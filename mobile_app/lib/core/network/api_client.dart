import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import '../services/version_service.dart';
import '../services/version_provider.dart';

part 'api_client.g.dart';

@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    ),
  );

  const storage = FlutterSecureStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['x-app-platform'] = Platform.isIOS ? 'ios' : 'android';
        options.headers['x-app-version'] = VersionService.currentVersion;
        options.headers['x-app-build'] = VersionService.currentBuildNumber.toString();
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // Clear session on unauthorized errors
          storage.delete(key: AppConstants.tokenKey);
          storage.delete(key: AppConstants.userKey);
        } else if (e.response?.statusCode == 426) {
          // Backend enforced HTTP 426 Upgrade Required
          ref
              .read(versionStateProvider.notifier)
              .triggerForceUpdateFromBackend(e.response?.data);
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}
