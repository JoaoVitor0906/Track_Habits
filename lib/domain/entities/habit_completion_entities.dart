// domain/entities/habit_completion_entities.dart

class HabitCompletion {
  final String id; // UUID gerado pelo banco
  final String userId; // UUID do usuário
  final String habitId; // UUID do hábito
  final DateTime date; // Data do dia (date type no supabase)
  final DateTime? completedAt; // Timestamp de conclusão

  HabitCompletion({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.date,
    this.completedAt,
  }) {
    if (userId.isEmpty) throw Exception('userId não pode ser vazio');
    if (habitId.isEmpty) throw Exception('habitId não pode ser vazio');
  }
}
