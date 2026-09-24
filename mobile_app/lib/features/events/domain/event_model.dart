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
      final direct = DriveUrlHelper.toDirectImageUrl(imageUrl!) ?? imageUrl!.trim();
      list.add(direct);
    }
    for (final url in galleryUrls) {
      if (url.trim().isNotEmpty) {
        final direct = DriveUrlHelper.toDirectImageUrl(url) ?? url.trim();
        if (!list.contains(direct)) {
          list.add(direct);
        }
      }
    }
    // If externalAlbumUrl is a single Google Drive file or direct image, add to in-app gallery!
    if (externalAlbumUrl != null && externalAlbumUrl!.trim().isNotEmpty) {
      final directFromAlbum = DriveUrlHelper.toDirectImageUrl(externalAlbumUrl!);
      if (directFromAlbum != null && !list.contains(directFromAlbum)) {
        list.add(directFromAlbum);
      }
    }
    return list;
  }
}

class DriveUrlHelper {
  static String? extractDriveFileId(String url) {
    final reg1 = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final m1 = reg1.firstMatch(url);
    if (m1 != null) return m1.group(1);

    final reg2 = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    final m2 = reg2.firstMatch(url);
    if (m2 != null) return m2.group(1);

    return null;
  }

  static bool isDriveFolder(String url) {
    return url.contains('drive.google.com/drive/folders') || url.contains('drive.google.com/folderview');
  }

  static String? toDirectImageUrl(String url) {
    final fileId = extractDriveFileId(url);
    if (fileId != null && !isDriveFolder(url)) {
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }
    return null;
  }

  static String sanitizeUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    return s;
  }
}
