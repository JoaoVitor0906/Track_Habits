import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';

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
