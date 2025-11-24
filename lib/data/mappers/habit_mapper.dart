// domain/mappers/habit_mapper.dart
import 'package:flutter_application_1/data/dtos/habit_dto.dart';
import 'package:flutter_application_1/domain/entities/habit_entities.dart';

class HabitMapper {
  static Habit toEntity(HabitDto dto) {
    return Habit(
      id: dto.id ?? '', // Normaliza nulo para vazio se necessário
      title: dto.title ?? 'Sem Título',
      description: dto.description ?? '',
      // Converte String para Enum
      frequency: FrequencyType.values.firstWhere(
        (e) => e.toString().split('.').last == (dto.frequencyType ?? 'daily'),
        orElse: () => FrequencyType.daily, // Valor padrão seguro
      ),
      target: dto.targetCount ?? 1,
      // Converte String para DateTime
      createdAt: dto.createdAt != null
          ? DateTime.parse(dto.createdAt!)
          : DateTime.now(),
    );
  }

  static HabitDto toDto(Habit entity) {
    return HabitDto(
      id: entity.id.isEmpty ? null : entity.id,
      title: entity.title,
      description: entity.description,
      // Converte Enum para String
      frequencyType: entity.frequency.toString().split('.').last,
      targetCount: entity.target,
      // Converte DateTime para String ISO
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
