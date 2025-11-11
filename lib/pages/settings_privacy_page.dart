import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';

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
                  Navigator.pushReplacementNamed(context, '/onboarding');
                }
              },
              child: const Text('Revogar consentimento'))
        ]),
      ),
    );
  }
}
