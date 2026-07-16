import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/api_client.dart';

final myFamilyProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/directory/my-family');
    return response.data as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
});
