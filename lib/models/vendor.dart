class Vendor {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? photo; // Nouveau champ pour la photo (URL ou chemin)

  Vendor({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.photo, // facultatif
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      name: json['name'] ?? json['nom'] ?? 'Inconnu',
      description: json['description'] ?? json['specialty'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photo: json['photo'] ?? null, // Récupère la photo si disponible
    );
  }
}
