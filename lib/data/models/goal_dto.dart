/// DTO (Data Transfer Object) para Goal
/// Representa os dados crus vindos do Supabase (snake_case)
class GoalDto {
  final String? id;
  final String? userId;
  final String? title;
  final int? target;
  final int? currentProgress;
  final String? reminder; // Formato HH:mm como TIME no banco
  final bool? completed;
  final String? completedAt; // TIMESTAMPTZ como String ISO 8601
  final String? createdAt; // TIMESTAMPTZ como String ISO 8601
  final String? updatedAt; // TIMESTAMPTZ como String ISO 8601

  GoalDto({
    this.id,
    this.userId,
    this.title,
    this.target,
    this.currentProgress,
    this.reminder,
    this.completed,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Cria um GoalDto a partir de um Map (JSON do Supabase)
  factory GoalDto.fromJson(Map<String, dynamic> json) {
    return GoalDto(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      title: json['title'] as String?,
      target: json['target'] as int?,
      currentProgress: json['current_progress'] as int?,
      reminder: json['reminder'] as String?,
      completed: json['completed'] as bool?,
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Converte o GoalDto para um Map (JSON para enviar ao Supabase)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'target': target,
      'current_progress': currentProgress ?? 0,
      'completed': completed ?? false,
    };

    // Campos opcionais
    if (id != null) map['id'] = id;
    if (userId != null) map['user_id'] = userId;
    if (reminder != null && reminder!.isNotEmpty) map['reminder'] = reminder;
    if (completedAt != null) map['completed_at'] = completedAt;
    // created_at e updated_at são gerenciados pelo banco

    return map;
  }

  /// Cria uma cópia com campos atualizados
  GoalDto copyWith({
    String? id,
    String? userId,
    String? title,
    int? target,
    int? currentProgress,
    String? reminder,
    bool? completed,
    String? completedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return GoalDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      target: target ?? this.target,
      currentProgress: currentProgress ?? this.currentProgress,
      reminder: reminder ?? this.reminder,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'GoalDto(id: $id, title: $title, target: $target, progress: $currentProgress, completed: $completed)';
  }
}
