class Provider {
  final int id;
  final String name;
  final Uri? imageUri; // mais seguro que String solta
  final String? brandColorHex; // pode virar Color depois
  final double rating; // garantimos 0..5
  final double? distanceKm;
  final Set<String> tags; // vindo de metadata, mas aqui já limpo
  final bool featured; // idem
  final DateTime updatedAt;

  Provider({
    required this.id,
    required this.name,
    this.imageUri,
    this.brandColorHex,
    required double rating,
    this.distanceKm,
    Set<String>? tags,
    this.featured = false,
    required this.updatedAt,
  }) : rating = rating.clamp(0.0, 5.0),
      tags = {...?tags};

  /// Conveniência para a UI (texto pronto)
  String get subtitle =>
      '${rating.toStringAsFixed(1)} ⋅ ${distanceKm?.toStringAsFixed(1) ?? '-'} km';
}