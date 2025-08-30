class VodContent {
  final String id;
  final String name;
  final String? cmd; // Stream URL
  final String? logo;
  final String? description;
  final String? year;
  final String? director;
  final String? actors;
  final String? duration;
  final String? categoryId; // To link back to VodCategory

  VodContent({
    required this.id,
    required this.name,
    this.cmd,
    this.logo,
    this.description,
    this.year,
    this.director,
    this.actors,
    this.duration,
    this.categoryId,
  });

  factory VodContent.fromJson(Map<String, dynamic> json, {String? categoryId}) {
    return VodContent(
      id: json['id'] as String,
      name: json['name'] as String,
      cmd: json['cmd'] as String?,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      year: json['year'] as String?,
      director: json['director'] as String?,
      actors: json['actors'] as String?,
      duration: json['duration'] as String?,
      categoryId: categoryId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Assuming you'll add columns for VOD content in DatabaseHelper
      // For now, using generic names, will need to map to actual DB columns
      'id': id,
      'name': name,
      'cmd': cmd,
      'logo': logo,
      'description': description,
      'year': year,
      'director': director,
      'actors': actors,
      'duration': duration,
      'category_id': categoryId,
    };
  }
}