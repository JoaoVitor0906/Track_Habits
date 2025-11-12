import 'package:flutter/material.dart';
import 'smart_suggestions_service.dart';

class SmartSuggestionsWidget extends StatefulWidget {
  final void Function(HabitSuggestion) onAdd;
  final String? userName;

  const SmartSuggestionsWidget({Key? key, required this.onAdd, this.userName}) : super(key: key);

  @override
  State<SmartSuggestionsWidget> createState() => _SmartSuggestionsWidgetState();
}

class _SmartSuggestionsWidgetState extends State<SmartSuggestionsWidget> {
  final SmartSuggestionService _service = SmartSuggestionService();
  late Future<List<HabitSuggestion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.suggest(userName: widget.userName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HabitSuggestion>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: list.map((s) => Card(
            child: ListTile(
              title: Text(s.title),
              subtitle: Text(s.description),
              trailing: ElevatedButton(
                onPressed: () => widget.onAdd(s),
                child: const Text('Adicionar')
              ),
            ),
          )).toList(),
        );
      }
    );
  }
}
