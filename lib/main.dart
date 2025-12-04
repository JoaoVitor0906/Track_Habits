import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'domain/repositories/profile_repository.dart';
import 'data/repositories/profile_repository_impl.dart';

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
      ProfileRepositoryImpl(preferencesService, localPhotoStore);

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
        typography: Typography.material2021(),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          headlineLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          ),
          labelLarge: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          labelMedium: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          labelSmall: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: const Color(0xFF059669),
              width: 1.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          centerTitle: true,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
