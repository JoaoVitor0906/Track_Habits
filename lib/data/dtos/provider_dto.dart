class ProviderDto {
  final int id;
  final String name;
  final String? image_url; // nomes iguais aos do banco
  final String? brand_color_hex;
  final double rating;
  final double? distance_km;
  final Map<String, dynamic>? metadata;
  final String updated_at; // ISO8601 no fio

  ProviderDto({
    required this.id,
    required this.name,
    this.image_url,
    this.brand_color_hex,
    required this.rating,
    this.distance_km,
    this.metadata,
    required this.updated_at,
  });

  factory ProviderDto.fromMap(Map<String, dynamic> m) => ProviderDto(
    id: m['id'] as int,
    name: m['name'] as String,
    image_url: m['image_url'] as String?,
    brand_color_hex: m['brand_color_hex'] as String?,
    rating: (m['rating'] as num).toDouble(),
    distance_km: (m['distance_km'] as num?)?.toDouble(),
    metadata: m['metadata'] as Map<String, dynamic>?,
    updated_at: m['updated_at'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'image_url': image_url,
    'brand_color_hex': brand_color_hex,
    'rating': rating,
    'distance_km': distance_km,
    'metadata': metadata,
    'updated_at': updated_at,
  };
}