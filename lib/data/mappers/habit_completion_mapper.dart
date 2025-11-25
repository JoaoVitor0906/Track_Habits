// data/mappers/habit_completion_mapper.dart
import 'package:flutter_application_1/data/dtos/habit_completion_dto.dart';
import 'package:flutter_application_1/domain/entities/habit_completion_entities.dart';

class HabitCompletionMapper {
  static HabitCompletion toEntity(HabitCompletionDto dto) {
    final id = dto.id ?? '';

    DateTime parsedDate;
    if (dto.date != null) {
      // date field is stored as "YYYY-MM-DD" in the DB, we parse as DateTime
      parsedDate = DateTime.parse(dto.date!);
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedCompletedAt;
    if (dto.completedAt != null) {
      parsedCompletedAt = DateTime.parse(dto.completedAt!);
    }

    return HabitCompletion(
      id: id,
      userId: dto.userId ?? '',
      habitId: dto.habitId ?? '',
      date: parsedDate,
      completedAt: parsedCompletedAt,
    );
  }

  static HabitCompletionDto toDto(HabitCompletion entity) => HabitCompletionDto(
        id: entity.id.isEmpty ? null : entity.id,
        userId: entity.userId,
        habitId: entity.habitId,
        date: entity.date.toIso8601String().split('T').first,
        completedAt: entity.completedAt?.toIso8601String(),
      );
}
