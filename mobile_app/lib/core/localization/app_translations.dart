enum AppLanguage { en, hi }

class AppTranslations {
  static const Map<String, Map<AppLanguage, String>> _keys = {
    'app_name': {
      AppLanguage.en: 'Akhil Bhartiya Rander Parivar Samaj',
      AppLanguage.hi: 'अखिल भारतीय रांदड़ परिवार समाज',
    },
    'login_title': {
      AppLanguage.en: 'Welcome to Rander Parivar',
      AppLanguage.hi: 'रांदड़ परिवार में आपका स्वागत है',
    },
    'login_subtitle': {
      AppLanguage.en: 'Connect with our community, receive alerts, and stay updated.',
      AppLanguage.hi: 'हमारे समाज से जुड़ें, अलर्ट प्राप्त करें और अपडेट रहें।',
    },
    'sign_in_google': {
      AppLanguage.en: 'Sign in with Google',
      AppLanguage.hi: 'गूगल के साथ साइन इन करें',
    },
    'logout': {
      AppLanguage.en: 'Logout',
      AppLanguage.hi: 'लॉगआउट',
    },
    'settings': {
      AppLanguage.en: 'Settings',
      AppLanguage.hi: 'सेटिंग्स',
    },
    'language': {
      AppLanguage.en: 'Language / भाषा',
      AppLanguage.hi: 'भाषा / Language',
    },
    'change_language': {
      AppLanguage.en: 'Change Language',
      AppLanguage.hi: 'भाषा बदलें',
    },
    'profile': {
      AppLanguage.en: 'Profile',
      AppLanguage.hi: 'प्रोफ़ाइल',
    },
    'home': {
      AppLanguage.en: 'Home',
      AppLanguage.hi: 'मुख्य पृष्ठ',
    },
    'role': {
      AppLanguage.en: 'User Role',
      AppLanguage.hi: 'उपयोगकर्ता भूमिका',
    },
    'admin_dashboard': {
      AppLanguage.en: 'Admin Dashboard',
      AppLanguage.hi: 'प्रशासक डैशबोर्ड',
    },
    'upload_photo': {
      AppLanguage.en: 'Upload Photo',
      AppLanguage.hi: 'फोटो अपलोड करें',
    },
    'notifications': {
      AppLanguage.en: 'Notifications',
      AppLanguage.hi: 'सूचनाएं',
    },
    'no_notifications': {
      AppLanguage.en: 'No notifications yet',
      AppLanguage.hi: 'अभी तक कोई सूचना नहीं है',
    },
    'switch_english': {
      AppLanguage.en: 'English',
      AppLanguage.hi: 'अंग्रेज़ी (English)',
    },
    'switch_hindi': {
      AppLanguage.en: 'Hindi (हिंदी)',
      AppLanguage.hi: 'हिंदी',
    },
    'error_generic': {
      AppLanguage.en: 'Something went wrong. Please try again.',
      AppLanguage.hi: 'कुछ गलत हो गया। कृपया पुन: प्रयास करें।',
    },
    'admin_features': {
      AppLanguage.en: 'Administrative Tools',
      AppLanguage.hi: 'प्रशासनिक उपकरण',
    },
    'send_test_push': {
      AppLanguage.en: 'Send Test Push Notification',
      AppLanguage.hi: 'परीक्षण पुश अधिसूचना भेजें',
    },
    'upload_r2_desc': {
      AppLanguage.en: 'Upload profile photo',
      AppLanguage.hi: 'प्रोफ़ाइल फ़ोटो अपलोड करें',
    },
    'zone_coordinator_panel': {
      AppLanguage.en: 'Zone Coordinator Panel',
      AppLanguage.hi: 'क्षेत्र संयोजक पैनल',
    },
    'zone_coordinator_desc': {
      AppLanguage.en: 'You have Zone Coordinator access. Open the panel to review and approve/reject family members in your assigned area.',
      AppLanguage.hi: 'आपके पास क्षेत्र संयोजक अधिकार हैं। अपने आवंटित क्षेत्र के सदस्यों और परिवारों के सत्यापन के लिए पैनल खोलें।',
    },
    'coordinator_view_banner': {
      AppLanguage.en: 'Zone Coordinator View: Showing pending approvals only for families in your assigned area/zone.',
      AppLanguage.hi: 'क्षेत्र संयोजक दृश्य: केवल आपके आवंटित क्षेत्र के परिवारों के लंबित सत्यापन दिखाए जा रहे हैं।',
    },
    'coordinator_reason': {
      AppLanguage.en: 'Coordinator Feedback',
      AppLanguage.hi: 'संयोजक की टिप्पणी',
    },
    'admin_desc': {
      AppLanguage.en: 'You have administrator access. Open the admin panel to manage members and dispatch notifications.',
      AppLanguage.hi: 'आपके पास प्रशासक अधिकार हैं। सदस्यों के प्रबंधन और सूचनाएं भेजने के लिए एडमिन पैनल खोलें।',
    },
    'role_coordinator': {
      AppLanguage.en: 'Zone Coordinator',
      AppLanguage.hi: 'क्षेत्र संयोजक',
    },
    'role_admin': {
      AppLanguage.en: 'Administrator',
      AppLanguage.hi: 'प्रशासक',
    },
    'role_member': {
      AppLanguage.en: 'Member',
      AppLanguage.hi: 'सदस्य',
    },
  };

  static String get(String key, AppLanguage lang) {
    if (!_keys.containsKey(key)) return key;
    return _keys[key]![lang] ?? key;
  }
}
