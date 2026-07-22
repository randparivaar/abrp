import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/features/auth/presentation/auth_controller.dart';

final myFamilyProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    return null;
  }
  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/directory/my-family');
    return response.data as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
});
