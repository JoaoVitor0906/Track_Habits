import '../models/goal_dto.dart';
import '../../domain/entities/goal_entity.dart';

/// Mapper para converter entre GoalDto (dados do Supabase) e Goal (entidade de domínio)
class GoalMapper {
  /// Converte um GoalDto para uma entidade Goal
  static Goal toEntity(GoalDto dto) {
    return Goal(
      id: dto.id ?? '',
      userId: dto.userId ?? '',
      title: dto.title ?? 'Meta sem título',
      target: dto.target ?? 1,
      currentProgress: dto.currentProgress ?? 0,
      reminder: dto.reminder,
      completed: dto.completed ?? false,
      completedAt: dto.completedAt != null
          ? DateTime.tryParse(dto.completedAt!)
          : null,
      createdAt: dto.createdAt != null
          ? DateTime.parse(dto.createdAt!)
          : DateTime.now(),
      updatedAt: dto.updatedAt != null
          ? DateTime.parse(dto.updatedAt!)
          : DateTime.now(),
    );
  }

  /// Converte uma entidade Goal para GoalDto
  static GoalDto toDto(Goal entity) {
    return GoalDto(
      id: entity.id.isEmpty ? null : entity.id,
      userId: entity.userId.isEmpty ? null : entity.userId,
      title: entity.title,
      target: entity.target,
      currentProgress: entity.currentProgress,
      reminder: entity.reminder,
      completed: entity.completed,
      completedAt: entity.completedAt?.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  /// Converte uma lista de GoalDto para uma lista de Goal
  static List<Goal> toEntityList(List<GoalDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Converte uma lista de Goal para uma lista de GoalDto
  static List<GoalDto> toDtoList(List<Goal> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }

  /// Converte um Map (dados locais do PrefsService) para GoalDto
  static GoalDto fromLocalMap(Map<String, dynamic> map) {
    return GoalDto(
      id: map['id'] as String?,
      userId: null, // Não temos user_id nos dados locais
      title: map['title'] as String?,
      target: map['target'] as int?,
      currentProgress: map['currentProgress'] as int?,
      reminder: map['reminder'] as String?,
      completed: map['completed'] as bool?,
      completedAt: map['completedAt'] as String?,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  /// Converte GoalDto para Map (para salvar localmente no PrefsService)
  static Map<String, dynamic> toLocalMap(GoalDto dto) {
    return {
      if (dto.id != null) 'id': dto.id,
      'title': dto.title,
      'target': dto.target,
      'currentProgress': dto.currentProgress ?? 0,
      'reminder': dto.reminder ?? '',
      'completed': dto.completed ?? false,
      if (dto.completedAt != null) 'completedAt': dto.completedAt,
      if (dto.createdAt != null) 'createdAt': dto.createdAt,
      if (dto.updatedAt != null) 'updatedAt': dto.updatedAt,
    };
  }
}
