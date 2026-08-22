class EventModel {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<String> galleryUrls;
  final String? externalAlbumUrl;
  final DateTime eventDate;
  final DateTime? endDate;
  final String? venue;
  final String category;
  final bool isActive;
  final DateTime? createdAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.galleryUrls = const [],
    this.externalAlbumUrl,
    required this.eventDate,
    this.endDate,
    this.venue,
    this.category = 'general',
    this.isActive = true,
    this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedGallery = [];
    if (json['galleryUrls'] != null && json['galleryUrls'] is List) {
      parsedGallery = (json['galleryUrls'] as List)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    } else if (json['gallery_urls'] != null && json['gallery_urls'] is List) {
      parsedGallery = (json['gallery_urls'] as List)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return EventModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? 'Untitled Event',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      galleryUrls: parsedGallery,
      externalAlbumUrl: json['externalAlbumUrl'] as String? ?? json['external_album_url'] as String?,
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'].toString()).toLocal()
          : (json['event_date'] != null
              ? DateTime.parse(json['event_date'].toString()).toLocal()
              : DateTime.now()),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString()).toLocal()
          : (json['end_date'] != null ? DateTime.parse(json['end_date'].toString()).toLocal() : null),
      venue: json['venue'] as String?,
      category: json['category'] as String? ?? 'general',
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : (json['is_active'] is bool ? json['is_active'] as bool : true),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : (json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'galleryUrls': galleryUrls,
      'externalAlbumUrl': externalAlbumUrl,
      'eventDate': eventDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'venue': venue,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Helper to get all available image URLs for galleries (main banner + gallery)
  List<String> get allImageUrls {
    final list = <String>[];
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      list.add(imageUrl!.trim());
    }
    for (final url in galleryUrls) {
      if (url.trim().isNotEmpty && !list.contains(url.trim())) {
        list.add(url.trim());
      }
    }
    return list;
  }
}
