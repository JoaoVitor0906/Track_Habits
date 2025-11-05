import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sp = await SharedPreferences.getInstance();
  final prefsService = PrefsService(sp);
  runApp(Provider<PrefsService>.value(
      value: prefsService, child: const TrackHabitsApp()));
}

class TrackHabitsApp extends StatelessWidget {
  const TrackHabitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackHabits',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669), // Emerald primária
          primary: const Color(0xFF059669), // Emerald
          secondary: const Color(0xFF4F46E5), // Indigo
          surface: const Color(0xFFFFFFFF), // Surface
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF0F172A), // Texto claro
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(),
          bodyMedium: TextStyle(),
        ),
        // A11Y: Suporte a text scaling
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Roteamento conforme PRD
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/consent': (context) => const ConsentPage(),
        '/home': (context) => const HomePage(),
        '/create-habit': (context) => const CreateHabitPage(),
        '/settings/privacy': (context) => const SettingsPrivacyPage(),
      },
      // A11Y: Foco visível
      debugShowCheckedModeBanner: false,
    );
  }
}

// Minimal HomePage used by routes
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
    // initial load will run after first build to have context available
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
                              // reload after returning from detail
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
                      // reload after returning
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

// Serviço de Preferências (UI → Service → Storage)
class PrefsService {
  static const String _policiesVersion = 'v1';
  static const String _privacyReadKey = 'privacy_read_$_policiesVersion';
  static const String _termsReadKey = 'terms_read_$_policiesVersion';
  static const String _policiesVersionAcceptedKey = 'policies_version_accepted';
  static const String _acceptedAtKey = 'accepted_at';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _habitsListKey = 'habits_list'; // Para hábitos (JSON)

  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  // Checa se fully accepted
  bool get isFullyAccepted {
    return _prefs.getBool(_onboardingCompletedKey) == true &&
        _prefs.getString(_policiesVersionAcceptedKey) == _policiesVersion;
  }

  // Checa se onboarding completed
  bool get isOnboardingCompleted =>
      _prefs.getBool(_onboardingCompletedKey) == true;

  // Set read for policy
  Future<void> setPolicyRead(String policy, bool read) async {
    final key = policy == 'privacy' ? _privacyReadKey : _termsReadKey;
    await _prefs.setBool(key, read);
  }

  // Generic setter used by onboarding flow
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool get isPrivacyRead => _prefs.getBool(_privacyReadKey) == true;
  bool get isTermsRead => _prefs.getBool(_termsReadKey) == true;

  // Accept policies
  Future<void> acceptPolicies() async {
    await _prefs.setString(_policiesVersionAcceptedKey, _policiesVersion);
    await _prefs.setString(_acceptedAtKey, DateTime.now().toIso8601String());
    await _prefs.setBool(_onboardingCompletedKey, true);
  }

  // Revoke
  Future<void> revokePolicies() async {
    await _prefs.remove(_privacyReadKey);
    await _prefs.remove(_termsReadKey);
    await _prefs.remove(_policiesVersionAcceptedKey);
    await _prefs.remove(_acceptedAtKey);
    await _prefs.setBool(_onboardingCompletedKey, false);
  }

  List<Map<String, dynamic>> get habits =>
      _prefs
          .getStringList(_habitsListKey)
          ?.map((e) => Map<String, dynamic>.from(jsonDecode(e)))
          .toList() ??
      [];

  // New habit APIs: save/get/delete by id and list of ids in _habitsListKey
  Future<String> saveHabit(Map<String, dynamic> habit) async {
    final id = (habit['id'] as String?) ?? const Uuid().v4();
    final key = 'habit_$id';
    final withId = Map<String, dynamic>.from(habit);
    withId['id'] = id;
    await _prefs.setString(key, jsonEncode(withId));
    final ids = _prefs.getStringList(_habitsListKey) ?? [];
    if (!ids.contains(id)) {
      ids.add(id);
      await _prefs.setStringList(_habitsListKey, ids);
    }
    return id;
  }

  Map<String, dynamic>? getHabit(String id) {
    final raw = _prefs.getString('habit_$id');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> deleteHabit(String id) async {
    await _prefs.remove('habit_$id');
    final ids = _prefs.getStringList(_habitsListKey) ?? [];
    ids.remove(id);
    await _prefs.setStringList(_habitsListKey, ids);
  }

  List<Map<String, dynamic>> getAllHabits() {
    final ids = _prefs.getStringList(_habitsListKey) ?? [];
    final out = <Map<String, dynamic>>[];
    for (final id in ids) {
      final h = getHabit(id);
      if (h != null) out.add(h);
    }
    return out;
  }

  Future<void> addHabit(Map<String, dynamic> habit) async {
    final list = habits;
    list.add(habit);
    await _prefs.setStringList(
        _habitsListKey, list.map((e) => jsonEncode(e)).toList());
  }

  Future<void> clearHabits() async => await _prefs.remove(_habitsListKey);

  // Generic getters/setters for tests and API completeness
  bool getBoolKey(String key) => _prefs.getBool(key) == true;
  Future<void> setBoolKey(String key, bool value) async =>
      await _prefs.setBool(key, value);
  String? getStringKey(String key) => _prefs.getString(key);
  Future<void> setStringKey(String key, String value) async =>
      await _prefs.setString(key, value);
  Future<void> setString(String key, String value) async =>
      await setStringKey(key, value);

  // Migrate policy version (simple invalidation)
  Future<void> migratePolicyVersion(String from, String to) async {
    final accepted = _prefs.getString(_policiesVersionAcceptedKey);
    if (accepted != to) {
      await _prefs.remove(_privacyReadKey);
      await _prefs.remove(_termsReadKey);
      await _prefs.remove(_policiesVersionAcceptedKey);
      await _prefs.remove(_acceptedAtKey);
    }
  }
}

class HabitService {
  final PrefsService prefs;
  HabitService(this.prefs);

  Future<void> createExampleHabit() async {
    if (prefs.getAllHabits().isEmpty) {
      final id = await prefs.saveHabit({
        'title': 'Beber água',
        'goal': '3 copos/dia',
        'reminder': '09:00',
        'enabled': true
      });
      await prefs.setBoolKey('first_habit_created', true);
      await prefs.setStringKey('first_habit_id', id);
    }
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (prefs.isFullyAccepted) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else if (prefs.isOnboardingCompleted) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/consent');
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Color(0xFF059669)),
            SizedBox(height: 16),
            Text('TrackHabits',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  final ValueNotifier<int> _page = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // PrefsService injected via Provider; no direct SharedPreferences calls
    // We'll update onboarding_completed when user reaches last onboarding page.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          _page.value = index;
          if (index == 2) {
            final prefs = Provider.of<PrefsService>(context, listen: false);
            prefs.setBoolKey('onboarding_completed', true);
          }
        },
        children: [
          _OnboardingScreen(
            title: 'Bem-vindo ao TrackHabits',
            body:
                'Crie hábitos simples para sua rotina de estudante. Foco sem fricção!',
            onNext: () => _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
            onSkip: () => Navigator.pushReplacementNamed(context, '/consent'),
          ),
          _OnboardingScreen(
            title: 'Como funciona',
            body:
                'Crie e acompanhe hábitos diários, como beber água. Marque checks para progresso.',
            onNext: () => _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
            onBack: () => _controller.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
            onSkip: () => Navigator.pushReplacementNamed(context, '/consent'),
          ),
          _OnboardingScreen(
            title: 'Pronto para começar?',
            body:
                'Aceite nossas políticas para prosseguir e criar seu primeiro hábito.',
            onNext: () => Navigator.pushReplacementNamed(context, '/consent'),
          ),
        ],
      ),
      bottomSheet: ValueListenableBuilder<int>(
          valueListenable: _page,
          builder: (context, value, child) {
            // hide dots on last page
            if (value == 2) return const SizedBox.shrink();
            return _DotsIndicator(controller: _controller, currentPage: value);
          }),
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const _OnboardingScreen(
      {required this.title,
      required this.body,
      this.onNext,
      this.onBack,
      this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 100, color: Color(0xFF059669)),
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(body,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (onBack != null)
                ElevatedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(88, 48)),
                    label: const Text('Voltar')),
              if (onNext != null)
                ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 48),
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white),
                    label: const Text('Avançar')),
              if (onSkip != null)
                TextButton(
                    onPressed: onSkip,
                    style:
                        TextButton.styleFrom(minimumSize: const Size(64, 48)),
                    child: const Text('Pular')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  const _DotsIndicator({required this.controller, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isActive = currentPage == index ||
              (controller.hasClients && controller.page?.round() == index);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 24 : 8,
            decoration: BoxDecoration(
                color: isActive ? const Color(0xFF059669) : Colors.grey,
                borderRadius: BorderRadius.circular(4)),
          );
        }),
      ),
    );
  }
}

class PolicyViewerPage extends StatefulWidget {
  final String policyType; // 'privacy' or 'terms'
  const PolicyViewerPage({super.key, required this.policyType});

  @override
  State<PolicyViewerPage> createState() => _PolicyViewerPageState();
}

class _PolicyViewerPageState extends State<PolicyViewerPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  bool _isRead = false;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    // We'll handle scroll progress via ScrollNotification in the build method to be
    // more robust on the web (maxScrollExtent may not be available immediately).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      final prefs = Provider.of<PrefsService>(context, listen: false);
      setState(() {
        _isRead = widget.policyType == 'privacy'
            ? prefs.isPrivacyRead
            : prefs.isTermsRead;
        _didInit = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _loadPolicy() async {
    final file = widget.policyType == 'privacy' ? 'privacidade.md' : 'terms.md';
    return await rootBundle.loadString('assets/policies/$file');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.policyType == 'privacy'
              ? 'Política de Privacidade'
              : 'Termos de Uso')),
      body: FutureBuilder<String>(
        future: _loadPolicy(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'Erro ao carregar o documento. Tente novamente mais tarde.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Voltar'))
                    ])));
          }

          // Ensure that if content is smaller than the viewport we immediately
          // enable the "Marcar como lido" action.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isRead && _scrollController.hasClients) {
              final maxExtent = _scrollController.position.maxScrollExtent;
              if (maxExtent <= 0) {
                setState(() {
                  _isRead = true;
                  _scrollProgress = 1.0;
                });
              }
            }
          });

          return Column(
            children: [
              LinearProgressIndicator(value: _scrollProgress),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    final metrics = notification.metrics;
                    final max = metrics.maxScrollExtent;
                    final pixels = metrics.pixels;
                    if (max <= 0) {
                      // Short document (fits viewport) -> consider read
                      if (!_isRead) {
                        setState(() {
                          _isRead = true;
                          _scrollProgress = 1.0;
                        });
                      }
                    } else {
                      // compute progress and require user to reach the very end
                      final progress = (pixels / max).clamp(0.0, 1.0);
                      // require full scroll: pixels >= max (with tiny epsilon)
                      final reachedEnd = pixels >= (max - 1.0);
                      setState(() {
                        _scrollProgress = progress;
                        _isRead = reachedEnd;
                      });
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: MarkdownBody(data: snapshot.data!)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isRead ? _markAsRead : null,
                  icon: const Icon(Icons.check),
                  style: ElevatedButton.styleFrom(
            backgroundColor: _isRead ? const Color(0xFF059669) : null,
            foregroundColor: _isRead ? Colors.white : null,
                      minimumSize: const Size(double.infinity, 48)),
                  label: const Text('Marcar como lido'),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _markAsRead() async {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    await prefs.setPolicyRead(widget.policyType, true);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});
  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _privacyRead = false;
  bool _termsRead = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefs = Provider.of<PrefsService>(context, listen: false);
    setState(() {
      _privacyRead = prefs.isPrivacyRead;
      _termsRead = prefs.isTermsRead;
    });
  }

  bool get _canAccept => _privacyRead && _termsRead;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consentimento')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Aceite nossas políticas para continuar.',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            CheckboxListTile(
              title: const Text('Li e concordo com a Política de Privacidade'),
              value: _privacyRead,
              onChanged: (value) async {
                if (value == true) {
                  final navigator = Navigator.of(context);
                  final result = await navigator.push<bool?>(MaterialPageRoute(
                      builder: (_) =>
                          const PolicyViewerPage(policyType: 'privacy')));
                  if (!mounted) return;
                  if (result == true) {
                    setState(() {
                      _privacyRead = true;
                    });
                  }
                }
              },
            ),
            CheckboxListTile(
              title: const Text('Li e concordo com os Termos de Uso'),
              value: _termsRead,
              onChanged: (value) async {
                if (value == true) {
                  final navigator = Navigator.of(context);
                  final result = await navigator.push<bool?>(MaterialPageRoute(
                      builder: (_) =>
                          const PolicyViewerPage(policyType: 'terms')));
                  if (!mounted) return;
                  if (result == true) {
                    setState(() {
                      _termsRead = true;
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _canAccept
                  ? () async {
                      final navigator = Navigator.of(context);
                      final prefs = Provider.of<PrefsService>(context, listen: false);
                      await prefs.acceptPolicies();
                      if (!mounted) return;
                      navigator.pushReplacementNamed('/home');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
          maximumSize: const Size(double.infinity, 48),
          backgroundColor: _canAccept ? const Color(0xFF059669) : null,
          foregroundColor: _canAccept ? Colors.white : null),
              child: const Text('Aceitar e continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
            Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v))
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
                  'enabled': _enabled
                });
                await prefs.setBoolKey('first_habit_created', true);
                await prefs.setStringKey('first_habit_id', id);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Criar'))
        ]),
      ),
    );
  }
}

class SettingsPrivacyPage extends StatelessWidget {
  const SettingsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Gerenciar consentimento'),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: () async {
                // confirm revoke
                final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                            title: const Text('Revogar consentimento?'),
                            content: const Text(
                                'Isso removerá o aceite e voltará o usuário ao fluxo legal.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Revogar'))
                            ]));
                if (ok != true) return;

                // save previous state so we can undo
                final prevVersion =
                    prefs.getStringKey('policies_version_accepted');
                final prevAt = prefs.getStringKey('accepted_at');
                await prefs.revokePolicies();

                if (context.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(SnackBar(
                    content: const Text('Consentimento revogado'),
                    action: SnackBarAction(
                        label: 'Desfazer',
                        onPressed: () async {
                          if (prevVersion != null) {
                            await prefs.setStringKey(
                                'policies_version_accepted', prevVersion);
                          }
                          if (prevAt != null) {
                            await prefs.setStringKey('accepted_at', prevAt);
                          }
                          await prefs.setBoolKey('onboarding_completed', true);
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        }),
                  ));
                  // navigate back to home or to consent flow depending on undo
                  Navigator.pushReplacementNamed(context, '/onboarding');
                }
              },
              child: const Text('Revogar consentimento'))
        ]),
      ),
    );
  }
}

// Page to view and edit a single habit
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
      // Habit missing -> pop
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
