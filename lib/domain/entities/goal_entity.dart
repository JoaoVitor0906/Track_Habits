/// Entidade de domínio que representa uma Meta
/// Metas são objetivos numéricos com prazo, diferentes de hábitos recorrentes
class Goal {
  final String id;
  final String userId;
  final String title;
  final int target;
  final int currentProgress;
  final String? reminder; // Formato HH:mm
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.target,
    this.currentProgress = 0,
    this.reminder,
    this.completed = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  }) {
    // Invariantes de Domínio (Validações)
    if (title.isEmpty) {
      throw Exception('O título da meta não pode ser vazio.');
    }
    if (target <= 0) {
      throw Exception('A meta numérica deve ser maior que zero.');
    }
    if (currentProgress < 0) {
      throw Exception('O progresso não pode ser negativo.');
    }
  }

  /// Verifica se a meta foi atingida (progresso >= target)
  bool get isAchieved => currentProgress >= target;

  /// Retorna a porcentagem de progresso (0.0 a 1.0)
  double get progressPercentage =>
      target > 0 ? (currentProgress / target).clamp(0.0, 1.0) : 0.0;

  /// Cria uma cópia da meta com campos atualizados
  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    int? target,
    int? currentProgress,
    String? reminder,
    bool? completed,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
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
    return 'Goal(id: $id, title: $title, target: $target, progress: $currentProgress, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
