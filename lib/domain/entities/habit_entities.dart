// domain/entities/habit.dart
enum FrequencyType { daily, weekly, monthly }

class Habit {
  final String id;
  final String title;
  final String description;
  final FrequencyType frequency; // Enum forte, não string
  final int target;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    required this.target,
    required this.createdAt,
  }) {
    // Invariantes de Domínio (Validações)
    if (title.isEmpty) {
      throw Exception('O título do hábito não pode ser vazio.');
    }
    if (target <= 0) {
      throw Exception('A meta deve ser maior que zero.');
    }
  }
}
