import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';

class CreateHabitPage extends StatefulWidget {
  const CreateHabitPage({super.key});

  @override
  State<CreateHabitPage> createState() => _CreateHabitPageState();
}

class _CreateHabitPageState extends State<CreateHabitPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _reminderController = TextEditingController();
  bool _enabled = true;

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Criar hábito')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            decoration: const InputDecoration(labelText: 'Meta'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reminderController,
            decoration: const InputDecoration(labelText: 'Lembrete (HH:MM)'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Ativado'),
            const SizedBox(width: 12),
            Switch(
                value: _enabled, onChanged: (v) => setState(() => _enabled = v))
          ]),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                final goal = _goalController.text.trim();
                final reminder = _reminderController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Título é obrigatório')));
                  return;
                }
                final id = await prefs.saveHabit({
                  'title': title,
                  'goal': goal,
                  'reminder': reminder,
                  'enabled': _enabled,
                  'target': 1,
                });
                print('💾 [CreateHabit] Hábito criado localmente com ID: $id');

                // Try to create on Supabase as well (if authenticated)
                // IMPORTANTE: Passar o mesmo ID local para manter sincronia
                try {
                  final sup = SupabaseService();
                  final result = await sup.createHabit({
                    'id': id, // Usar o mesmo ID local!
                    'title': title,
                    'goal': goal,
                    'reminder': reminder,
                    'enabled': _enabled,
                    'target': 1,
                  });
                  print('✅ [CreateHabit] Resultado Supabase: $result');
                } catch (e) {
                  print('❌ [CreateHabit] Erro ao criar no Supabase: $e');
                  // ignore errors: offline/local-first behavior
                }
                await prefs.setBoolKey('first_habit_created', true);
                await prefs.setStringKey('first_habit_id', id);
                if (context.mounted) Navigator.pop(context, id);
              },
              child: const Text('Criar'))
        ]),
      ),
    );
  }
}
