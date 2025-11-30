// data/models/habit_dto.dart
class HabitDto {
  final String? id; // Pode ser nulo antes de salvar
  final String? title;
  final String? description;
  final String? frequencyType; // String crua, não Enum
  final int? targetCount;
  final String? createdAt; // Data como String (ISO 8601)

  HabitDto({
   required this.id,
   required this.title,
   required this.description,
   required this.frequencyType,
   required this.targetCount,
   required this.createdAt,
  });

  factory HabitDto.fromJson(Map<String, dynamic> json) {
    return HabitDto(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      frequencyType: json['frequency_type'] as String?, // snake_case aqui
      targetCount: json['target_count'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'frequency_type': frequencyType,
      'target_count': targetCount,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
