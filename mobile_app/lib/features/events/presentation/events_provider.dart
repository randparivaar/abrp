import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/features/events/domain/event_model.dart';
import 'package:image_picker/image_picker.dart';


final activeEventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  try {
    final response = await dio.get('/events/active');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List rawList = response.data['events'] ?? [];
      return rawList.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}
  return [];
});

final adminEventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  try {
    final response = await dio.get('/events/admin/all');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List rawList = response.data['events'] ?? [];
      return rawList.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}
  return [];
});

// ─────────────────────────────────────────────────────────────────────────────

class EventsService {
  final Dio dio;

  EventsService(this.dio);

  Future<String?> uploadSingleImage(XFile imageFile) async {
    try {
      final filename = 'event_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      const contentType = 'image/jpeg';

      final presignedResponse = await dio.post('/upload/presigned-url', data: {
        'filename': filename,
        'contentType': contentType,
      });

      final uploadUrl = presignedResponse.data['uploadUrl'] as String;
      final publicUrl = presignedResponse.data['publicUrl'] as String;

      final bytes = await imageFile.readAsBytes();
      final uploadDio = Dio();
      await uploadDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
      );

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(List<XFile> imageFiles) async {
    final List<String> uploadedUrls = [];
    for (final file in imageFiles) {
      final url = await uploadSingleImage(file);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    return uploadedUrls;
  }

  Future<bool> createEvent({
    required String title,
    String? description,
    String? imageUrl,
    List<String> galleryUrls = const [],
    String? externalAlbumUrl,
    required DateTime eventDate,
    DateTime? endDate,
    String? venue,
    String category = 'general',
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post('/events/admin/create', data: {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'galleryUrls': galleryUrls,
        'externalAlbumUrl': externalAlbumUrl,
        'eventDate': eventDate.toUtc().toIso8601String(),
        'endDate': endDate?.toUtc().toIso8601String(),
        'venue': venue,
        'category': category,
        'isActive': isActive,
      });
      return response.statusCode == 201 || (response.data != null && response.data['success'] == true);
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEvent(
    int id, {
    String? title,
    String? description,
    String? imageUrl,
    List<String>? galleryUrls,
    String? externalAlbumUrl,
    DateTime? eventDate,
    DateTime? endDate,
    String? venue,
    String? category,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (galleryUrls != null) 'galleryUrls': galleryUrls,
        if (externalAlbumUrl != null) 'externalAlbumUrl': externalAlbumUrl,
        if (eventDate != null) 'eventDate': eventDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
        if (venue != null) 'venue': venue,
        if (category != null) 'category': category,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await dio.put('/events/admin/$id', data: data);
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Quick status-only toggle — sends only isActive to the backend.
  Future<bool> toggleEventStatus(int id, {required bool isActive}) async {
    try {
      final response = await dio.put('/events/admin/$id', data: {'isActive': isActive});
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      final response = await dio.delete('/events/admin/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

final eventsServiceProvider = Provider<EventsService>((ref) {
  return EventsService(ref.watch(apiClientProvider));
});
