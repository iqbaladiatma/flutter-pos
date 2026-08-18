class OutletModel {
  final String id;
  final String organizationId;
  final String name;
  final String slug;
  final String address;
  final String phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final bool isActive;

  OutletModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.slug,
    required this.address,
    required this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.isActive = true,
  });

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'] ?? '',
      organizationId: json['organization_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'name': name,
        'slug': slug,
        'address': address,
        'phone': phone,
        'email': email,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'is_active': isActive,
      };
}
