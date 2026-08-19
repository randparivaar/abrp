import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ThemeModeNotifier extends Notifier<ThemeMode> {
  final _storage = const FlutterSecureStorage();

  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadThemeMode() async {
    try {
      final savedMode = await _storage.read(key: AppConstants.themeModeKey);
      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          default:
            state = ThemeMode.system;
            break;
        }
      }
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final modeStr = mode == ThemeMode.light
          ? 'light'
          : (mode == ThemeMode.dark ? 'dark' : 'system');
      await _storage.write(key: AppConstants.themeModeKey, value: modeStr);
      state = mode;
    } catch (_) {
      state = mode;
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

