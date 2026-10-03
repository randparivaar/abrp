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
    'donate': {
      AppLanguage.en: 'Donation & Contributions',
      AppLanguage.hi: 'सहयोग एवं दान राशि',
    },
    'donate_now': {
      AppLanguage.en: 'Donate Now',
      AppLanguage.hi: 'सहयोग करें',
    },
    // Committee & Patron Translations
    'committee_title': {
      AppLanguage.en: 'Committee & Patrons',
      AppLanguage.hi: 'कार्यकारिणी एवं प्रेरणास्रोत',
    },
    'committee_share_tooltip': {
      AppLanguage.en: 'Share',
      AppLanguage.hi: 'साझा करें',
    },
    'committee_share_subject': {
      AppLanguage.en: 'ABRP Committee & Patrons',
      AppLanguage.hi: 'अखिल भारतीय रांदड़ परिवार समिति',
    },
    'committee_share_text': {
      AppLanguage.en: '🙏 Shri Akhil Bhartiya (Maheshwari) Rander Pariwar 🙏\nChief Patron & Inspiration:\nLate Shri Chandmal Ji Rander (Manglana)\n\n"Dedicated to community welfare, youth education, and social unity."',
      AppLanguage.hi: '🙏 श्री अखिल भारतीय (माहेश्वरी) रांदड़ परिवार 🙏\nमुख्य प्रेरणास्रोत एवं भामाशाह:\nस्व. श्री चांदमल जी रांदड़ (मंगलाना)\n\n"समाज सेवा, शिक्षा संवर्धन एवं बंधुत्व ही हमारा संकल्प है।"',
    },
    'patron_badge': {
      AppLanguage.en: 'CHIEF PATRON & INSPIRATION',
      AppLanguage.hi: 'मुख्य प्रेरणास्रोत एवं भामाशाह',
    },
    'patron_name': {
      AppLanguage.en: 'Late Shri Chandmal Ji Rander',
      AppLanguage.hi: 'स्व. श्री चांदमल जी रांदड़',
    },
    'patron_address': {
      AppLanguage.en: 'Manglana (Rajasthan)',
      AppLanguage.hi: 'मंगलाना (राजस्थान)',
    },
    'patron_community': {
      AppLanguage.en: 'Shri Akhil Bhartiya (Maheshwari) Rander Pariwar',
      AppLanguage.hi: 'श्री अखिल भारतीय (माहेश्वरी) रांदड़ परिवार',
    },
    'patron_quote': {
      AppLanguage.en: 'Dedication to community upliftment, education of youth, and supporting families in need.',
      AppLanguage.hi: 'समाज की सेवा, शिक्षा का संवर्धन एवं जरूरतमंदों का उत्थान ही सबसे बड़ा धर्म है।',
    },
    'committee_vision_title': {
      AppLanguage.en: 'Objectives & Core Vision',
      AppLanguage.hi: 'समिति के मुख्य उद्देश्य एवं संकल्प',
    },
    'obj_family_unity_title': {
      AppLanguage.en: 'Family Unity & Lineage',
      AppLanguage.hi: 'पारिवारिक समन्वय एवं एकता',
    },
    'obj_family_unity_desc': {
      AppLanguage.en: 'Connecting all Rander families across India and fostering matrimonial and social harmony.',
      AppLanguage.hi: 'देशभर में बसे समस्त रांदड़ परिवारों को एक सूत्र में जोड़ना एवं परिचय सम्मेलन आयोजित करना।',
    },
    'obj_education_title': {
      AppLanguage.en: 'Education & Scholarships',
      AppLanguage.hi: 'शिक्षा संवर्धन एवं छात्रवृत्ति',
    },
    'obj_education_desc': {
      AppLanguage.en: 'Providing scholarships, career counseling, and academic support to deserving youth.',
      AppLanguage.hi: 'मेधावी एवं जरूरतमंद छात्र-छात्राओं को उच्च शिक्षा, कोचिंग एवं छात्रवृत्ति सहायता।',
    },
    'obj_infrastructure_title': {
      AppLanguage.en: 'Community Infrastructure',
      AppLanguage.hi: 'समाज भवन एवं छात्रावास',
    },
    'obj_infrastructure_desc': {
      AppLanguage.en: 'Developing community halls, dharamshalas, and student hostels in pilgrimage centers.',
      AppLanguage.hi: 'तीर्थ क्षेत्रों एवं प्रमुख नगरों में समाज भवन, धर्मशाला एवं विद्यार्थियों हेतु छात्रावास निर्माण।',
    },
    'obj_healthcare_title': {
      AppLanguage.en: 'Healthcare & Social Care',
      AppLanguage.hi: 'चिकित्सा एवं सामाजिक सहयोग',
    },
    'obj_healthcare_desc': {
      AppLanguage.en: 'Emergency healthcare aid, senior citizen welfare, and community mutual aid programs.',
      AppLanguage.hi: 'आकस्मिक स्वास्थ्य संकट में सहायता एवं वरिष्ठ नागरिकों का सम्मान व सहयोग।',
    },
    // Donation Screen Translations
    'donation_title': {
      AppLanguage.en: 'Donation Details',
      AppLanguage.hi: 'सहयोग एवं दान राशि',
    },
    'donation_purpose': {
      AppLanguage.en: 'For Community Welfare, Education & Medical Care Support',
      AppLanguage.hi: 'समाज विकास, शिक्षा एवं चिकित्सा कल्याण सहयोग हेतु',
    },
    'donation_savings_account': {
      AppLanguage.en: 'Official Savings Account (NEFT/RTGS/IMPS)',
      AppLanguage.hi: 'आधिकारिक बचत खाता (NEFT / RTGS / IMPS)',
    },
    'copy_all_details': {
      AppLanguage.en: 'Copy All Details',
      AppLanguage.hi: 'समस्त विवरण कॉपी करें',
    },
    'share_action': {
      AppLanguage.en: 'Share',
      AppLanguage.hi: 'शेयर करें',
    },
    'beneficiary_label': {
      AppLanguage.en: 'Beneficiary Name',
      AppLanguage.hi: 'खाता धारक (Beneficiary)',
    },
    'account_number_label': {
      AppLanguage.en: 'Account Number',
      AppLanguage.hi: 'खाता संख्या (A/C No.)',
    },
    'ifsc_code_label': {
      AppLanguage.en: 'IFSC Code',
      AppLanguage.hi: 'आईएफएससी कोड (IFSC)',
    },
    'account_type_label': {
      AppLanguage.en: 'Account Type',
      AppLanguage.hi: 'खाता प्रकार',
    },
    'branch_label': {
      AppLanguage.en: 'Branch',
      AppLanguage.hi: 'शाखा (Branch)',
    },
    'receipt_process_title': {
      AppLanguage.en: 'Official Receipt Process',
      AppLanguage.hi: 'रसीद एवं पावती प्रक्रिया',
    },
    'receipt_step_1': {
      AppLanguage.en: 'Transfer the contribution via Net Banking (NEFT/RTGS/IMPS).',
      AppLanguage.hi: 'बैंक ट्रांसफर (NEFT / RTGS / IMPS / Net Banking) द्वारा राशि प्रेषित करें।',
    },
    'receipt_step_2': {
      AppLanguage.en: 'Save the transaction screenshot or UTR / Reference Number.',
      AppLanguage.hi: 'सफल ट्रांजेक्शन का स्क्रीनशॉट अथवा UTR नंबर सुरक्षित रखें।',
    },
    'receipt_step_3': {
      AppLanguage.en: 'Share screenshot along with your Full Name, Father/Husband Name & City to receive the official receipt.',
      AppLanguage.hi: 'आधिकारिक रसीद प्राप्त करने हेतु स्क्रीनशॉट, अपना पूरा नाम, पिता/पति का नाम एवं शहर/ग्राम समिति को ईमेल करें।',
    },
    'request_receipt_email': {
      AppLanguage.en: 'Request Receipt via Email',
      AppLanguage.hi: 'ईमेल द्वारा रसीद का अनुरोध करें',
    },
    'donation_share_subject': {
      AppLanguage.en: 'ABRP Donation Bank Account Details',
      AppLanguage.hi: 'रांदड़ परिवार समाज सहयोग बैंक विवरण',
    },
  };

  static String get(String key, AppLanguage lang) {
    if (!_keys.containsKey(key)) return key;
    return _keys[key]![lang] ?? key;
  }
}
