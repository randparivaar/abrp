import 'package:dio/dio.dart';
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
    if (response.data['success'] == true) {
      final list = response.data['ads'] as List<dynamic>;
      return list.map((json) => AdvertisementModel.fromJson(json)).toList();
    }
  } catch (_) {}
  return [];
});

final allActiveAdsProvider = FutureProvider<List<AdvertisementModel>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  try {
    final response = await dio.get(
      '/ads/active',
      options: Options(receiveTimeout: const Duration(seconds: 10)),
    );
    if (response.data['success'] == true) {
      final list = response.data['ads'] as List<dynamic>;
      return list.map((json) => AdvertisementModel.fromJson(json)).toList();
    }
  } catch (_) {}
  return [];
});
