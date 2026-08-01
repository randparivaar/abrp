class AppConstants {
  static const String appName = 'Akhil Bhartiya Rander Parivar Samaj';

  // ── API Base URL ──────────────────────────────────────────────────────────
  // Injected at build/run time via --dart-define=BASE_URL=<url>
  //   Vercel (release) : --dart-define=BASE_URL=https://abrp.vercel.app/api/v1
  //   Local (dev)      : --dart-define=BASE_URL=http://10.0.2.2:8005/api/v1
  //
  // If no --dart-define is supplied the local Android emulator URL is used.
  static const String _localUrl  = 'http://10.0.2.2:8005/api/v1';

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: _localUrl,
  );

  // Secure Storage keys
  static const String tokenKey = 'auth_jwt_token';
  static const String userKey  = 'auth_user_metadata';
  static const String langKey  = 'app_preferred_language';
  static const String themeKey = 'app_custom_theme_config';
}



