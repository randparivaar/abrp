import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import 'app_translations.dart';

part 'app_language.g.dart';

@riverpod
class LanguageState extends _$LanguageState {
  final _storage = const FlutterSecureStorage();

  @override
  AppLanguage build() {
    _loadLanguage();
    return AppLanguage.en;
  }

  Future<void> _loadLanguage() async {
    try {
      final savedLang = await _storage.read(key: AppConstants.langKey);
      if (savedLang == 'hi') {
        state = AppLanguage.hi;
      } else {
        state = AppLanguage.en;
      }
    } catch (_) {
      state = AppLanguage.en;
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    await _storage.write(key: AppConstants.langKey, value: lang.name);
    state = lang;
  }
}
