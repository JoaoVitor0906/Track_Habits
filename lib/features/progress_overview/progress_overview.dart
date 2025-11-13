import 'package:flutter/material.dart';

/// ProgressOverview
/// Widget simples que recebe número total de metas e número completadas hoje
/// e exibe um resumo visual básico. É um stub minimal para atender ao
/// contrato de apresentação — substitua a fonte dos dados por PrefsService
/// quando for integrar.

class ProgressOverview extends StatelessWidget {
  final int total;
  final int completedToday;

  const ProgressOverview(
      {Key? key, required this.total, required this.completedToday})
      : super(key: key);

  double get percentage => total == 0 ? 0.0 : (completedToday / total) * 100.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Progresso',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$completedToday de $total concluídos hoje'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: total == 0 ? 0.0 : completedToday / total),
            const SizedBox(height: 8),
            Text('${percentage.toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }
}
