import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';

part 'auth_controller.g.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.user, this.isLoading = false, this.errorMessage});

  AuthState copyWith({UserModel? user, bool? isLoading, String? errorMessage}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.role == 'admin';
}

@riverpod
class Auth extends _$Auth {
  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  AuthState build() {
    _checkAuthStatus();
    return AuthState(isLoading: true);
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final userJson = await _storage.read(key: AppConstants.userKey);

      if (token != null && userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        state = AuthState(user: user);
        _refreshProfile();
      } else {
        state = AuthState(user: null);
      }
    } catch (e) {
      state = AuthState(errorMessage: e.toString(), user: null);
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/users/me');
      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);
      
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = AuthState(user: user);
    } catch (_) {
      // Fail silently and keep cached user metadata
    }
  }

  Future<String?> _getFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return await messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  String _getDeviceType() {
    try {
      if (Platform.isIOS) {
        return 'ios';
      }
    } catch (_) {}
    return 'android';
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google Identity signature payload missing.');
      }

      final fcmToken = await _getFcmToken();
      final deviceType = _getDeviceType();

      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/auth/google', data: {
        'idToken': idToken,
        'fcmToken': ?fcmToken,
        'deviceType': deviceType,
      });
      
      final token = response.data['token'] as String;
      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);

      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));

      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _getErrorMessage(e));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final fcmToken = await _getFcmToken();
      final deviceType = _getDeviceType();

      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'fcmToken': fcmToken,
        'deviceType': deviceType,
      });

      final token = response.data['token'] as String;
      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);

      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));

      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _getErrorMessage(e));
    }
  }

  Future<void> signUpWithEmail(String email, String fullName, String password, String mobile) async {
    state = state.copyWith(isLoading: true);
    try {
      final fcmToken = await _getFcmToken();
      final deviceType = _getDeviceType();

      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/auth/register', data: {
        'email': email,
        'fullName': fullName,
        'password': password,
        'mobile': mobile,
        'fcmToken': fcmToken,
        'deviceType': deviceType,
      });

      final token = response.data['token'] as String;
      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);

      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));

      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _getErrorMessage(e));
    }
  }

  Future<bool> linkMobileNumber(String mobile) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/auth/link-mobile', data: {
        'mobile': mobile,
      });

      if (response.data['success'] == true && response.data['user'] != null) {
        final updatedUser = UserModel.fromJson(response.data['user']);
        final token = response.data['token'] as String?;

        if (token != null) {
          await _storage.write(key: AppConstants.tokenKey, value: token);
        }
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(updatedUser.toJson()));

        state = AuthState(user: updatedUser);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: response.data['error'] ?? 'Failed to link mobile number');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _getErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    state = AuthState(user: null);
  }

  Future<void> changePreferredLanguage(String lang) async {
    if (state.user == null) return;
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.patch('/users/me', data: {'preferredLanguage': lang});
      final user = UserModel.fromJson(response.data['user']);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(errorMessage: _getErrorMessage(e));
    }
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    if (state.user == null) return;
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.patch('/users/me', data: {'avatarUrl': avatarUrl});
      final user = UserModel.fromJson(response.data['user']);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(errorMessage: _getErrorMessage(e));
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/auth/forgot-password', data: {'email': email});
      final otp = response.data['otp'] as String?;
      return otp;
    } catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
    } catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _getErrorMessage(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('error')) {
        return data['error'] as String;
      }
    }
    return e.toString();
  }
}
