import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _habits = [];

  Future<void> _loadHabits() async {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    setState(() {
      _habits = prefs.getAllHabits();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHabits());
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    final habits = _habits;

    return Scaffold(
      appBar: AppBar(title: const Text('Home'), actions: [
        IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings/privacy'),
            icon: const Icon(Icons.privacy_tip))
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (habits.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Comece com um hábito',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('Sugerimos: Beber água (3 copos/dia)'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: () async {
                            final id = await prefs.saveHabit({
                              'title': 'Beber água',
                              'goal': '3 copos/dia',
                              'reminder': '09:00',
                              'enabled': true
                            });
                            await prefs.setBoolKey('first_habit_created', true);
                            await prefs.setStringKey('first_habit_id', id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Hábito criado: Beber água')));
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => HabitDetailPage(habitId: id)));
                              if (mounted) await _loadHabits();
                            }
                          },
                          child: const Text('Criar meu 1º hábito'))
                    ],
                  ),
                ),
              )
            else ...[
              const Text('Seus hábitos:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: habits.length,
                itemBuilder: (ctx, i) {
                final h = habits[i];
                final id = h['id'] as String?;
                return ListTile(
                  title: Text(h['title'] ?? '—'),
                  subtitle: Text(h['goal'] ?? ''),
                  onTap: id != null
                    ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HabitDetailPage(habitId: id)));
                      if (mounted) await _loadHabits();
                      }
                    : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {}));
                }))
            ]
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-habit'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class HabitDetailPage extends StatefulWidget {
  final String habitId;
  const HabitDetailPage({super.key, required this.habitId});

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _reminderController = TextEditingController();
  bool _enabled = true;
  PrefsService? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    _prefs = prefs;
    final h = prefs.getHabit(widget.habitId);
    if (h != null) {
      _titleController.text = (h['title'] as String?) ?? '';
      _goalController.text = (h['goal'] as String?) ?? '';
      _reminderController.text = (h['reminder'] as String?) ?? '';
      _enabled = (h['enabled'] as bool?) ?? true;
      if (mounted) {
        setState(() {});
      }
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Título é obrigatório')));
      return;
    }
    await _prefs!.saveHabit({
      'id': widget.habitId,
      'title': title,
      'goal': _goalController.text.trim(),
      'reminder': _reminderController.text.trim(),
      'enabled': _enabled
    });
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Excluir hábito?'),
              content: const Text('Esta ação removerá o hábito permanentemente.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir'))
              ],
            ));
    if (ok == true) {
      await _prefs!.deleteHabit(widget.habitId);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do hábito')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título')),
          const SizedBox(height: 12),
          TextField(controller: _goalController, decoration: const InputDecoration(labelText: 'Meta')),
          const SizedBox(height: 12),
          TextField(controller: _reminderController, decoration: const InputDecoration(labelText: 'Lembrete (HH:MM)')),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Ativado'),
            const SizedBox(width: 12),
            Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v))
          ]),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Salvar')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _delete, child: const Text('Excluir'))
        ]),
      ),
    );
  }
}
