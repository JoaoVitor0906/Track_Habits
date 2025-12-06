import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';
import '../features/progress_overview/progress_overview.dart';
import '../features/smart_suggestions/smart_suggestions_widget.dart';
import '../widgets/app_drawer.dart';
import '../domain/repositories/profile_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _habits = [];
  bool _showPendingOnly = false;

  Future<void> _loadHabits() async {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    setState(() {
      _habits = prefs.getAllHabits();
    });
  }

  Future<void> _showManageGoalsModal(
      BuildContext context, List<Map<String, dynamic>> habits) async {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    final goals = prefs.getAllGoals();

    final parentContext = context;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            if (goals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma meta criada',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crie sua primeira meta usando o botão +',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreateGoalModal(parentContext);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Criar Meta'),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              controller: scrollController,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Suas Metas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...goals.map((g) {
                  final id = g['id'] as String?;
                  final title = g['title'] as String? ?? '—';
                  final target = (g['target'] as int?) ?? 1;
                  final reminder = g['reminder'] as String? ?? '';
                  final completed = g['completed'] as bool? ?? false;
                  final createdAt = g['createdAt'] as String?;

                  String createdDate = '';
                  if (createdAt != null) {
                    final date = DateTime.tryParse(createdAt);
                    if (date != null) {
                      createdDate =
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    }
                  }

                  if (id == null) return const SizedBox();
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        completed ? Icons.check_circle : Icons.flag,
                        color: completed
                            ? Colors.green
                            : Theme.of(parentContext).colorScheme.primary,
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meta: $target'),
                          if (reminder.isNotEmpty) Text('Lembrete: $reminder'),
                          if (createdDate.isNotEmpty)
                            Text('Criada em: $createdDate',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Editar',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showEditGoalModal(parentContext, g);
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'complete') {
                                await prefs.completeGoal(id);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Meta "$title" concluída!')),
                                  );
                                }
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: parentContext,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Excluir meta?'),
                                    content:
                                        Text('Deseja excluir a meta "$title"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  // Deletar localmente
                                  await prefs.deleteGoal(id);

                                  // Sincronizar exclusão com Supabase
                                  try {
                                    final sup = SupabaseService();
                                    await sup.deleteGoal(id);
                                  } catch (e) {
                                    print(
                                        '❌ Erro ao deletar meta do Supabase: $e');
                                    // Continua mesmo com erro (local-first)
                                  }

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Meta "$title" excluída')),
                                    );
                                  }
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              if (!completed)
                                const PopupMenuItem(
                                  value: 'complete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Marcar como concluída'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCreateGoalModal(parentContext);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Criar nova meta'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
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

    items.add(ProgressOverview(total: totalTargets, completedToday: completed));

    items.add(const SizedBox(height: 12));

    // Toggle to show only pending habits
    items.add(Row(children: [
      const Text('Mostrar apenas pendentes'),
      const SizedBox(width: 8),
      Switch(
          value: _showPendingOnly,
          onChanged: (v) => setState(() => _showPendingOnly = v)),
    ]));
    items.add(const SizedBox(height: 12));

    items.add(SmartSuggestionsWidget(
      userName: prefs.getStringKey('userName'),
      onAdd: (s) async {
        final messenger = ScaffoldMessenger.of(context);
        final id = await prefs.saveHabit({
          'title': s.title,
          'goal': s.description,
          'reminder': '',
          'enabled': true,
          'target': 1
        });
        // Sincronizar com Supabase usando o mesmo ID
        try {
          final sup = SupabaseService();
          await sup.createHabit({
            'id': id,
            'title': s.title,
            'goal': s.description,
            'target': 1,
          });
        } catch (_) {}
        if (mounted) {
          messenger.showSnackBar(
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
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final id = await prefs.saveHabit({
                    'title': 'Beber água',
                    'goal': '3 copos/dia',
                    'reminder': '09:00',
                    'enabled': true,
                    'target': 3
                  });
                  // Sincronizar com Supabase usando o mesmo ID
                  try {
                    final sup = SupabaseService();
                    await sup.createHabit({
                      'id': id,
                      'title': 'Beber água',
                      'goal': '3 copos/dia',
                      'target': 3,
                    });
                  } catch (_) {}
                  await prefs.setBoolKey('first_habit_created', true);
                  await prefs.setStringKey('first_habit_id', id);
                  if (mounted) {
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Hábito criado: Beber água')));
                    await navigator.push(MaterialPageRoute(
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

      final visibleHabits = _showPendingOnly
          ? habits.where((h) {
              final id = h['id'] as String?;
              if (id == null) return false;
              final target = (h['target'] as int?) ?? 1;
              final current = prefs.getHabitCount(id, DateTime.now());
              return current < target;
            }).toList()
          : habits;

      for (final h in visibleHabits) {
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
          onTap: () {
            _showHabitInfoDialog(context, h);
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await navigator.push(MaterialPageRoute(
                      builder: (_) => HabitDetailPage(habitId: nid)));
                  if (mounted) await _loadHabits();
                },
              ),
              IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: current <= 0
                      ? null
                      : () async {
                          await prefs.incrementHabitCount(
                              nid, DateTime.now(), -1);
                          if (mounted) setState(() {});
                        }),
              Text('$current / $target',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: current >= target
                      ? null
                      : () async {
                          // If this is the first increment from 0 -> 1, record completion to Supabase
                          final before =
                              prefs.getHabitCount(nid, DateTime.now());
                          await prefs.incrementHabitCount(
                              nid, DateTime.now(), 1);
                          final after =
                              prefs.getHabitCount(nid, DateTime.now());
                          if (before == 0 && after > 0) {
                            try {
                              final sup = SupabaseService();
                              final userId = sup.getCurrentUser()?.id;
                              if (userId != null) {
                                await sup.recordHabitCompletion(
                                    userId: userId,
                                    habitId: nid,
                                    date: DateTime.now());
                              }
                            } catch (_) {
                              // ignore: keep local-first behavior
                            }
                            // Record local completion event (with timestamp)
                            try {
                              await prefs.addCompletionRecord(
                                  nid, title, DateTime.now());
                            } catch (_) {
                              // ignore storage failures
                            }
                          }
                          if (mounted) setState(() {});
                        }),
            ],
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
          ? AppDrawer(
              profileRepository: profileRepository,
              habits: habits,
              onManageGoals: () => _showManageGoalsModal(context, habits),
            )
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
          onPressed: () => _showAddMenu(context), child: const Icon(Icons.add)),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Criar Hábito'),
              subtitle: const Text('Atividade recorrente para acompanhar'),
              onTap: () async {
                Navigator.pop(ctx);
                final navigator = Navigator.of(context);
                await navigator.pushNamed('/create-habit');
                if (mounted) await _loadHabits();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Criar Meta'),
              subtitle: const Text('Objetivo numérico com lembrete'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateGoalModal(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHabitInfoDialog(BuildContext context, Map<String, dynamic> habit) {
    final title = habit['title'] as String? ?? '—';
    final goal = habit['goal'] as String? ?? '';
    final target = (habit['target'] as int?) ?? 1;
    final reminder = habit['reminder'] as String? ?? '';
    final enabled = (habit['enabled'] as bool?) ?? true;
    final id = habit['id'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (goal.isNotEmpty) ...[
                const Text('Meta:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(goal),
                const SizedBox(height: 12),
              ],
              const Text('Meta numérica:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$target vezes por dia'),
              const SizedBox(height: 12),
              if (reminder.isNotEmpty) ...[
                const Text('Lembrete:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(reminder),
                const SizedBox(height: 12),
              ],
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    enabled ? Icons.check_circle : Icons.cancel,
                    color: enabled ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(enabled ? 'Ativo' : 'Desativado'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          if (id != null)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final navigator = Navigator.of(context);
                await navigator.push(MaterialPageRoute(
                    builder: (_) => HabitDetailPage(habitId: id)));
                if (mounted) await _loadHabits();
              },
              child: const Text('Editar'),
            ),
        ],
      ),
    );
  }

  void _showCreateGoalModal(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final reminderController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar Meta'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título da meta',
                    hintText: 'Ex: Beber água',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o título da meta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Meta numérica',
                    hintText: 'Ex: 8 (copos de água)',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe a meta numérica';
                    }
                    final num = int.tryParse(value.trim());
                    if (num == null || num <= 0) {
                      return 'Informe um número válido maior que 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reminderController,
                  decoration: const InputDecoration(
                    labelText: 'Lembrete (HH:mm)',
                    hintText: 'Ex: 09:00',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  keyboardType: TextInputType.datetime,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      final hour = time.hour.toString().padLeft(2, '0');
                      final minute = time.minute.toString().padLeft(2, '0');
                      reminderController.text = '$hour:$minute';
                    }
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final regex = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');
                      if (!regex.hasMatch(value)) {
                        return 'Formato inválido. Use HH:mm';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final prefs = Provider.of<PrefsService>(context, listen: false);
                final messenger = ScaffoldMessenger.of(context);

                final title = titleController.text.trim();
                final target = int.parse(targetController.text.trim());
                final reminder = reminderController.text.trim();

                // Salvar como meta localmente (separado dos hábitos)
                final goalId = await prefs.saveGoal({
                  'title': title,
                  'target': target,
                  'reminder': reminder,
                  'completed': false,
                  'currentProgress': 0,
                });

                // Sincronizar com Supabase usando o MESMO ID local
                try {
                  final sup = SupabaseService();
                  await sup.createGoal(
                    id: goalId, // Passa o ID local para manter sincronizado
                    title: title,
                    target: target,
                    reminder: reminder.isNotEmpty ? reminder : null,
                  );
                } catch (e) {
                  print('❌ Erro ao sincronizar meta com Supabase: $e');
                  // Continua mesmo com erro (local-first)
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Meta criada: $title')),
                  );
                  // Abrir o modal de gerenciamento de metas para mostrar a nova meta
                  // ignore: use_build_context_synchronously
                  _showManageGoalsModal(context, _habits);
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalModal(BuildContext context, Map<String, dynamic> goal) {
    final id = goal['id'] as String;
    final titleController =
        TextEditingController(text: (goal['title'] as String?) ?? '');
    final targetController =
        TextEditingController(text: ((goal['target'] as int?) ?? 1).toString());
    final reminderController =
        TextEditingController(text: (goal['reminder'] as String?) ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Meta'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título da meta',
                    hintText: 'Ex: Beber água',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o título da meta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Meta numérica',
                    hintText: 'Ex: 8 (copos de água)',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe a meta numérica';
                    }
                    final num = int.tryParse(value.trim());
                    if (num == null || num <= 0) {
                      return 'Informe um número válido maior que 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reminderController,
                  decoration: const InputDecoration(
                    labelText: 'Lembrete (HH:mm)',
                    hintText: 'Ex: 09:00',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  keyboardType: TextInputType.datetime,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      final hour = time.hour.toString().padLeft(2, '0');
                      final minute = time.minute.toString().padLeft(2, '0');
                      reminderController.text = '$hour:$minute';
                    }
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final regex = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');
                      if (!regex.hasMatch(value)) {
                        return 'Formato inválido. Use HH:mm';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // Capturar referências antes de fechar o diálogo
                final prefs = Provider.of<PrefsService>(ctx, listen: false);
                final navigator = Navigator.of(ctx);

                final title = titleController.text.trim();
                final target = int.parse(targetController.text.trim());
                final reminder = reminderController.text.trim();

                // Atualizar a meta localmente
                await prefs.saveGoal({
                  'id': id,
                  'title': title,
                  'target': target,
                  'reminder': reminder,
                  'completed': goal['completed'] ?? false,
                  'currentProgress': goal['currentProgress'] ?? 0,
                  'createdAt': goal['createdAt'],
                });

                // Sincronizar com Supabase
                try {
                  final sup = SupabaseService();
                  await sup.updateGoal(
                    goalId: id,
                    title: title,
                    target: target,
                    reminder: reminder.isNotEmpty ? reminder : null,
                  );
                } catch (e) {
                  print('❌ Erro ao atualizar meta no Supabase: $e');
                  // Continua mesmo com erro (local-first)
                }

                navigator.pop();

                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Meta atualizada: $title')),
                  );
                  // Reabrir o modal de gerenciamento de metas
                  // ignore: use_build_context_synchronously
                  _showManageGoalsModal(context, _habits);
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
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
    final habitData = {
      'id': widget.habitId,
      'title': title,
      'goal': _goalController.text.trim(),
      'reminder': _reminderController.text.trim(),
      'enabled': _enabled,
      'target': target
    };
    
    // Salva localmente
    await _prefs!.saveHabit(habitData);
    
    // Sincroniza com Supabase
    try {
      final sup = SupabaseService();
      print('🔄 [_save] Sincronizando hábito editado com Supabase...');
      await sup.updateHabit(habitData);
      print('✅ [_save] Hábito sincronizado com Supabase');
    } catch (e) {
      print('❌ [_save] Erro ao sincronizar com Supabase: $e');
      // ignore errors: offline/local-first behavior
    }
    
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
      print(
          '🗑️ [_delete] Iniciando exclusão do hábito local ID: ${widget.habitId}');
      await _prefs!.deleteHabit(widget.habitId);
      print('✅ [_delete] Hábito excluído localmente');

      // Try to delete from Supabase as well (if authenticated)
      try {
        final sup = SupabaseService();
        print('🔄 [_delete] Tentando excluir do Supabase...');
        final success = await sup.deleteHabit(widget.habitId);
        print('📊 [_delete] Resultado da exclusão no Supabase: $success');
      } catch (e) {
        print('❌ [_delete] Erro ao excluir do Supabase: $e');
        // ignore errors: offline/local-first behavior
      }
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
