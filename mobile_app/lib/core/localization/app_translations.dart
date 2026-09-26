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
    'active_ads_title': {
      AppLanguage.en: 'Business Offers & Ads',
      AppLanguage.hi: 'व्यापारिक विज्ञापन और ऑफ़र',
    },
    'active_ads_subtitle': {
      AppLanguage.en: 'Explore exclusive offers and promotions from Rander Parivar members.',
      AppLanguage.hi: 'रांदड़ परिवार के सदस्यों के विशेष प्रस्ताव और विज्ञापन देखें।',
    },
    'sponsored': {
      AppLanguage.en: 'Sponsored',
      AppLanguage.hi: 'प्रायोजित',
    },
    'call_now': {
      AppLanguage.en: 'Call',
      AppLanguage.hi: 'कॉल करें',
    },
    'whatsapp': {
      AppLanguage.en: 'WhatsApp',
      AppLanguage.hi: 'व्हाट्सएप',
    },
    'create_ad': {
      AppLanguage.en: 'Create Advertisement',
      AppLanguage.hi: 'विज्ञापन बनाएं',
    },
    'privacy_policy': {
      AppLanguage.en: 'Privacy Policy',
      AppLanguage.hi: 'गोपनीयता नीति',
    },
    'terms_of_service': {
      AppLanguage.en: 'Terms & Conditions',
      AppLanguage.hi: 'नियम एवं शर्तें',
    },
    'help_support': {
      AppLanguage.en: 'Help & Support',
      AppLanguage.hi: 'सहायता एवं समर्थन',
    },
    'faqs': {
      AppLanguage.en: 'Frequently Asked Questions',
      AppLanguage.hi: 'अक्सर पूछे जाने वाले प्रश्न',
    },
    'danger_zone': {
      AppLanguage.en: 'Account Management',
      AppLanguage.hi: 'खाता प्रबंधन',
    },
    'delete_account': {
      AppLanguage.en: 'Delete Account',
      AppLanguage.hi: 'खाता हटाएं',
    },
    'delete_account_dialog_title': {
      AppLanguage.en: 'Delete Your Account?',
      AppLanguage.hi: 'क्या आप अपना खाता हटाना चाहते हैं?',
    },
    'delete_account_dialog_desc': {
      AppLanguage.en: 'This action permanently deletes your login credentials, FCM notification tokens, and mobile links. Your email and mobile number will be freed so you can re-register anytime. Your family tree directory entry will remain as an unlinked member profile so genealogical records are preserved.\n\nAre you sure you want to proceed?',
      AppLanguage.hi: 'यह कार्रवाई आपके लॉगिन क्रेडेंशियल, FCM नोटिफिकेशन टोकन और मोबाइल लिंक को स्थायी रूप से हटा देगी। आपका ईमेल और मोबाइल नंबर मुक्त हो जाएगा ताकि आप कभी भी दोबारा पंजीकरण कर सकें। पारिवारिक वंशावली को सुरक्षित रखने के लिए डायरेक्टरी में आपका नाम बना रहेगा।\n\nक्या आप वाकई आगे बढ़ना चाहते हैं?',
    },
    'delete_account_confirm': {
      AppLanguage.en: 'Permanently Delete',
      AppLanguage.hi: 'स्थायी रूप से हटाएं',
    },
    'cancel': {
      AppLanguage.en: 'Cancel',
      AppLanguage.hi: 'रद्द करें',
    },
    'delete_success': {
      AppLanguage.en: 'Your account has been deleted successfully. You can re-register anytime.',
      AppLanguage.hi: 'आपका खाता सफलतापूर्वक हटा दिया गया है। आप कभी भी पुनः पंजीकरण कर सकते हैं।',
    },
    'legal_and_support': {
      AppLanguage.en: 'Legal & Support',
      AppLanguage.hi: 'कानूनी एवं सहायता',
    },
    'email_support': {
      AppLanguage.en: 'Email Support',
      AppLanguage.hi: 'ईमेल सहायता',
    },
  };

  static String get(String key, AppLanguage lang) {
    if (!_keys.containsKey(key)) return key;
    return _keys[key]![lang] ?? key;
  }
}
