class OrganizationModel {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final Map<String, dynamic> settings;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.settings,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'],
      settings: json['settings'] is Map ? json['settings'] : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'logo_url': logoUrl,
        'settings': settings,
      };
}
