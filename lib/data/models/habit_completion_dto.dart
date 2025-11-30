// data/models/habit_completion_dto.dart

class HabitCompletionDto {
  final String? id;
  final String? userId;
  final String? habitId;
  final String? date; // ISO date string (YYYY-MM-DD)
  final String? completedAt; // ISO timestamp

  HabitCompletionDto({
    this.id,
    this.userId,
    this.habitId,
    this.date,
    this.completedAt,
  });

  factory HabitCompletionDto.fromMap(Map<String, dynamic> m) => HabitCompletionDto(
        id: m['id'] as String?,
        userId: m['user_id'] as String?,
        habitId: m['habit_id'] as String?,
        date: m['date'] as String?,
        completedAt: m['completed_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (userId != null) 'user_id': userId,
        if (habitId != null) 'habit_id': habitId,
        if (date != null) 'date': date,
        if (completedAt != null) 'completed_at': completedAt,
      };
}
