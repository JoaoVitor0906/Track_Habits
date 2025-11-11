import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';

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
