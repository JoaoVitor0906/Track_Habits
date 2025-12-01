import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PrefsService>(context, listen: false);
    final items = prefs.getCompletionHistory();

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: items.isEmpty
          ? const Center(child: Text('Nenhuma conclusão registrada ainda.'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = items[index];
                final title = (e['title'] as String?) ?? 'Hábito';
                final atRaw = (e['completed_at'] as String?) ?? '';
                DateTime? at;
                try {
                  at = DateTime.parse(atRaw);
                } catch (_) {
                  at = null;
                }
                final subtitle = at != null ? at.toLocal().toString() : atRaw;
                return ListTile(
                  title: Text(title),
                  subtitle: Text(subtitle),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                );
              },
            ),
    );
  }
}
