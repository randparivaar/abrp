import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import 'theme_config.dart';

part 'theme_notifier.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  final _storage = const FlutterSecureStorage();

  @override
  ThemeConfig build() {
    _loadThemeConfig();
    return ThemeConfig.defaultHeritage();
  }

  Future<void> _loadThemeConfig() async {
    try {
      final savedTheme = await _storage.read(key: AppConstants.themeKey);
      if (savedTheme != null) {
        final decoded = jsonDecode(savedTheme) as Map<String, dynamic>;
        state = ThemeConfig.fromJson(decoded);
      }
    } catch (_) {
      // Default to Heritage if loading fails
      state = ThemeConfig.defaultHeritage();
    }
  }

  Future<void> updateThemeConfig(ThemeConfig config) async {
    try {
      final jsonStr = jsonEncode(config.toJson());
      await _storage.write(key: AppConstants.themeKey, value: jsonStr);
      state = config;
    } catch (_) {
      // Fallback update in-memory
      state = config;
    }
  }

  Future<void> resetThemeConfig() async {
    try {
      await _storage.delete(key: AppConstants.themeKey);
      state = ThemeConfig.defaultHeritage();
    } catch (_) {
      state = ThemeConfig.defaultHeritage();
    }
  }
}
