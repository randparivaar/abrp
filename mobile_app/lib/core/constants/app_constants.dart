class AppConstants {
  static const String appName = 'Akhil Bhartiya Rander Parivar Samaj';
  
  // Base API url (Points to Hono backend running in Docker locally by default)
  // Replace this with your Vercel deployment URL in production (e.g. 'https://api.abrp.vercel.app/api/v1')
  static const String baseUrl = 'http://10.0.2.2:8005/api/v1'; // Default IP mapping for Android Emulator. Use localhost:8005 for iOS.
  
  // Secure Storage keys
  static const String tokenKey = 'auth_jwt_token';
  static const String userKey = 'auth_user_metadata';
  static const String langKey = 'app_preferred_language';
  static const String themeKey = 'app_custom_theme_config';
}


