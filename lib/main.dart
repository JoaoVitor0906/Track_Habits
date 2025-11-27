import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/splash_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/consent_page.dart';
import 'pages/home_page.dart';
import 'pages/create_habit_page.dart';
import 'pages/history_page.dart';
import 'pages/settings_privacy_page.dart';
import 'features/providers/presentation/providers_page.dart';
import 'services/prefs_service.dart';
import 'services/preferences_services.dart';
import 'services/local_photo_store.dart';
import 'repositories/profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  // Inicializar Supabase com credenciais
  // Permitir substituição por variável em tempo de compilação via --dart-define

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final sp = await SharedPreferences.getInstance();
  final prefsService = PrefsService(sp);

  // PreferencesService is used by ProfileRepository (photo storage, user info)
  final preferencesService = PreferencesService(sp);
  final localPhotoStore = LocalPhotoStore();
  final profileRepository =
      ProfileRepository(preferencesService, localPhotoStore);

  runApp(MultiProvider(
    providers: [
      Provider<PrefsService>.value(value: prefsService),
      Provider<ProfileRepository>.value(value: profileRepository),
    ],
    child: const TrackHabitsApp(),
  ));
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
        '/providers': (context) => const ProvidersPage(),
        '/create-habit': (context) => const CreateHabitPage(),
        '/history': (context) => const HistoryPage(),
        '/settings/privacy': (context) => const SettingsPrivacyPage(),
      },
      // A11Y: Foco visível
      debugShowCheckedModeBanner: false,
    );
  }
}
