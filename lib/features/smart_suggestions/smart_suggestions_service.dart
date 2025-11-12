 
/// HabitSuggestion DTO
class HabitSuggestion {
  final String title;
  final String description;

  HabitSuggestion({required this.title, required this.description});
}

/// SmartSuggestionService
/// Serviço local/heurístico que retorna sugestões fixas. Pode ser substituído por uma
/// implementação que use IA externa no futuro.
class SmartSuggestionService {
  SmartSuggestionService();

  Future<List<HabitSuggestion>> suggest({String? userName, int limit = 3}) async {
    // Simples heurística baseada no nome (exemplo)
    await Future.delayed(const Duration(milliseconds: 150));
    final base = <HabitSuggestion>[];
    base.add(HabitSuggestion(title: 'Beber água', description: 'Beba 3 copos por dia'));
    base.add(HabitSuggestion(title: 'Estudar 25 min', description: 'Sessões Pomodoro'));
    base.add(HabitSuggestion(title: 'Caminhar 10 min', description: 'Pequena caminhada diária'));

    if (userName != null && userName.isNotEmpty) {
      // personalização simples
      base.insert(0, HabitSuggestion(title: 'Saudação a $userName', description: 'Comece o dia com 1 ação simples'));
    }

    return base.take(limit).toList();
  }
}
