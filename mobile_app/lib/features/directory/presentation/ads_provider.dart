import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'directory_models.dart';

final adsByPlacementProvider = FutureProvider.family<List<AdvertisementModel>, String>((ref, placementKey) async {
  final dio = ref.watch(apiClientProvider);
  try {
    final response = await dio.get(
      '/ads/placement/$placementKey',
      options: Options(receiveTimeout: const Duration(seconds: 10)),
    );
    if (response.data != null && response.data['success'] == true) {
      final list = response.data['ads'] as List<dynamic>?;
      if (list != null) {
        return list.map((json) => AdvertisementModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    }
  } catch (e) {
    if (e is DioException && (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout)) {
      debugPrint('Ads fetch timeout for placement: $placementKey');
    } else {
      debugPrint('Error fetching ads by placement ($placementKey): $e');
    }
  }
  return [];
});

final allActiveAdsProvider = FutureProvider<List<AdvertisementModel>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final Map<int, AdvertisementModel> adMap = {};

  // 1. Fetch main active ads list
  try {
    final response = await dio.get(
      '/ads/active',
      options: Options(receiveTimeout: const Duration(seconds: 10)),
    );
    if (response.data != null && response.data['success'] == true) {
      final list = response.data['ads'] as List<dynamic>?;
      if (list != null) {
        for (final item in list) {
          try {
            final ad = AdvertisementModel.fromJson(item as Map<String, dynamic>);
            adMap[ad.id] = ad;
          } catch (e) {
            debugPrint('Error parsing ad item: $e');
          }
        }
      }
    }
  } catch (e, st) {
    debugPrint('Error fetching all active ads: $e\n$st');
  }

  // 2. Fallback check common placements to make sure no placement ad is missed
  final placements = ['directory_feed', 'directory_header', 'home_carousel', 'home_bottom_banner', 'business_directory'];
  for (final placementKey in placements) {
    try {
      final response = await dio.get(
        '/ads/placement/$placementKey',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['ads'] as List<dynamic>?;
        if (list != null) {
          for (final item in list) {
            try {
              final ad = AdvertisementModel.fromJson(item as Map<String, dynamic>);
              adMap[ad.id] = ad;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  final resultList = adMap.values.toList();
  resultList.sort((a, b) {
    final comp = b.priority.compareTo(a.priority);
    if (comp != 0) return comp;
    return b.id.compareTo(a.id);
  });

  return resultList;
});
