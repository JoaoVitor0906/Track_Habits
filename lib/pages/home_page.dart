import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';
import '../features/progress_overview/progress_overview.dart';
import '../features/smart_suggestions/smart_suggestions_widget.dart';
import '../widgets/app_drawer.dart';
import '../repositories/profile_repository.dart';

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

    ProfileRepository? profileRepository;
    try {
      profileRepository =
          Provider.of<ProfileRepository>(context, listen: false);
    } catch (_) {
      profileRepository = null;
    }

    final habitIds = habits
        .map((h) => (h['id'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final totalTargets =
        habits.fold<int>(0, (sum, h) => sum + ((h['target'] as int?) ?? 1));
    final completed =
        prefs.countCompletedInstancesCapped(habitIds, DateTime.now());

    // Build the page content into a list to avoid complex inline collection control-flow.
    final List<Widget> items = [];

    items.add(Row(children: [
      Expanded(
          child:
              ProgressOverview(total: totalTargets, completedToday: completed)),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Gerenciar metas',
        icon: const Icon(Icons.flag),
        onPressed: () async {
          // Abre um modal para escolher qual hábito editar
          if (habits.isNotEmpty) {
            await showModalBottomSheet(
              context: context,
              builder: (ctx) {
                return ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Selecione um hábito para editar a meta:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...habits.map((h) {
                      final id = h['id'] as String?;
                      final title = h['title'] as String? ?? '—';
                      final target = (h['target'] as int?) ?? 1;
                      if (id == null) return const SizedBox();
                      return ListTile(
                        title: Text(title),
                        subtitle: Text('Meta: $target'),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HabitDetailPage(habitId: id),
                            ),
                          );
                          if (mounted) await _loadHabits();
                        },
                      );
                    }).toList(),
                  ],
                );
              },
            );
          } else {
            await Navigator.pushNamed(context, '/create-habit');
            if (mounted) await _loadHabits();
          }
        },
      )
    ]));

    items.add(const SizedBox(height: 12));

    items.add(SmartSuggestionsWidget(
      userName: prefs.getStringKey('userName'),
      onAdd: (s) async {
        await prefs.saveHabit({
          'title': s.title,
          'goal': s.description,
          'reminder': '',
          'enabled': true,
          'target': 1
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hábito criado: ${s.title}')));
        }
        await _loadHabits();
      },
    ));

    items.add(const SizedBox(height: 12));

    if (habits.isEmpty) {
      items.add(Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Comece com um hábito',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Sugerimos: Beber água (3 copos/dia)'),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () async {
                  final id = await prefs.saveHabit({
                    'title': 'Beber água',
                    'goal': '3 copos/dia',
                    'reminder': '09:00',
                    'enabled': true,
                    'target': 3
                  });
                  await prefs.setBoolKey('first_habit_created', true);
                  await prefs.setStringKey('first_habit_id', id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Hábito criado: Beber água')));
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => HabitDetailPage(habitId: id)));
                    if (mounted) await _loadHabits();
                  }
                },
                child: const Text('Criar meu 1º hábito'))
          ]),
        ),
      ));
    } else {
      items.add(const Text('Seus hábitos:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
      items.add(const SizedBox(height: 12));

      for (final h in habits) {
        final id = h['id'] as String?;
        final title = h['title'] as String? ?? '—';
        final goal = h['goal'] as String? ?? '';
        final target = (h['target'] as int?) ?? 1;

        if (id == null) {
          items.add(ListTile(
              title: Text(title),
              subtitle: Text(goal),
              trailing:
                  const SizedBox(width: 140, child: Center(child: Text('-')))));
          continue;
        }

        final nid = id;
        final current = prefs.getHabitCount(nid, DateTime.now());

        items.add(ListTile(
          title: Text(title),
          subtitle: Text(goal),
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => HabitDetailPage(habitId: nid)));
            if (mounted) await _loadHabits();
          },
          trailing: SizedBox(
            width: 140,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: current <= 0
                      ? null
                      : () async {
                          await prefs.incrementHabitCount(
                              nid, DateTime.now(), -1);
                          if (mounted) setState(() {});
                        }),
              Expanded(
                  child: Center(
                      child: Text('$current / $target',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)))),
              IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: current >= target
                      ? null
                      : () async {
                          await prefs.incrementHabitCount(
                              nid, DateTime.now(), 1);
                          if (mounted) setState(() {});
                        }),
            ]),
          ),
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Home'), actions: [
        IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings/privacy'),
            icon: const Icon(Icons.privacy_tip))
      ]),
      drawer: profileRepository != null
          ? AppDrawer(profileRepository: profileRepository)
          : Drawer(
              child: ListView(padding: EdgeInsets.zero, children: [
                DrawerHeader(
                  decoration:
                      BoxDecoration(color: Theme.of(context).primaryColor),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            radius: 28,
                            child: Text(
                                (prefs.getStringKey('userName') ?? 'U')
                                    .split(' ')
                                    .map((s) => s.isNotEmpty ? s[0] : '')
                                    .take(2)
                                    .join(),
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.white))),
                        const SizedBox(height: 8),
                        Text(prefs.getStringKey('userName') ?? 'Usuário',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ]),
                ),
                ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Perfil'),
                    onTap: () => Navigator.pop(context)),
              ]),
            ),
      body: Padding(
          padding: const EdgeInsets.all(16), child: ListView(children: items)),
      floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/create-habit'),
          child: const Icon(Icons.add)),
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
  final TextEditingController _targetController = TextEditingController();
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
      _targetController.text = ((h['target'] as int?) ?? 1).toString();
      if (mounted) setState(() {});
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _reminderController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Título é obrigatório')));
      return;
    }
    final target = int.tryParse(_targetController.text.trim()) ?? 1;
    await _prefs!.saveHabit({
      'id': widget.habitId,
      'title': title,
      'goal': _goalController.text.trim(),
      'reminder': _reminderController.text.trim(),
      'enabled': _enabled,
      'target': target
    });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Excluir hábito?'),
                content:
                    const Text('Esta ação removerá o hábito permanentemente.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Excluir'))
                ]));
    if (ok == true) {
      await _prefs!.deleteHabit(widget.habitId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do hábito')),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título')),
            const SizedBox(height: 12),
            TextField(
                controller: _goalController,
                decoration: const InputDecoration(labelText: 'Meta')),
            const SizedBox(height: 12),
            TextField(
                controller: _reminderController,
                decoration:
                    const InputDecoration(labelText: 'Lembrete (HH:MM)')),
            const SizedBox(height: 12),
            TextField(
                controller: _targetController,
                decoration:
                    const InputDecoration(labelText: 'Meta numérica (ex: 3)'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Ativado'),
              const SizedBox(width: 12),
              Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v))
            ]),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Salvar')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _delete, child: const Text('Excluir'))
          ])),
    );
  }
}
