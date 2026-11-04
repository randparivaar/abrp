import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/localization/app_translations.dart';

class LegalSectionModel {
  final String title;
  final String content;

  LegalSectionModel({required this.title, required this.content});

  factory LegalSectionModel.fromJson(Map<String, dynamic> json) {
    return LegalSectionModel(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class LegalDocumentModel {
  final String title;
  final String lastUpdated;
  final String contactEmail;
  final List<LegalSectionModel> sections;

  LegalDocumentModel({
    required this.title,
    required this.lastUpdated,
    required this.contactEmail,
    required this.sections,
  });

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['sections'] as List<dynamic>? ?? [];
    return LegalDocumentModel(
      title: json['title'] as String? ?? '',
      lastUpdated: json['lastUpdated'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? 'randerparivaar@gmail.com',
      sections: sectionsRaw
          .map((s) => LegalSectionModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FaqModel {
  final String category;
  final String question;
  final String answer;

  FaqModel({
    required this.category,
    required this.question,
    required this.answer,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      category: json['category'] as String? ?? 'General',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class LegalRepository {
  final Dio _dio;

  LegalRepository(this._dio);

  Future<LegalDocumentModel> getPrivacyPolicy(AppLanguage lang) async {
    final langStr = lang == AppLanguage.hi ? 'hi' : 'en';
    try {
      final response = await _dio.get('/legal/privacy-policy', queryParameters: {'lang': langStr});
      return LegalDocumentModel.fromJson(response.data['document']);
    } catch (_) {
      return _getFallbackPrivacy(lang);
    }
  }

  Future<LegalDocumentModel> getTerms(AppLanguage lang) async {
    final langStr = lang == AppLanguage.hi ? 'hi' : 'en';
    try {
      final response = await _dio.get('/legal/terms-and-conditions', queryParameters: {'lang': langStr});
      return LegalDocumentModel.fromJson(response.data['document']);
    } catch (_) {
      return _getFallbackTerms(lang);
    }
  }

  Future<List<FaqModel>> getFaqs(AppLanguage lang) async {
    final langStr = lang == AppLanguage.hi ? 'hi' : 'en';
    try {
      final response = await _dio.get('/legal/faqs', queryParameters: {'lang': langStr});
      final faqsRaw = response.data['faqs'] as List<dynamic>? ?? [];
      return faqsRaw.map((f) => FaqModel.fromJson(f as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getFallbackFaqs(lang);
    }
  }

  LegalDocumentModel _getFallbackPrivacy(AppLanguage lang) {
    if (lang == AppLanguage.hi) {
      return LegalDocumentModel(
        title: 'गोपनीयता नीति (Privacy Policy)',
        lastUpdated: 'सितंबर 2026',
        contactEmail: 'randerparivaar@gmail.com',
        sections: [
          LegalSectionModel(
            title: '1. प्रस्तावना',
            content: 'अखिल भारतीय रांदड़ परिवार समाज (ABRP) समाज बंधुओं की निजता और डेटा सुरक्षा के प्रति पूर्णतः समर्पित है।',
          ),
          LegalSectionModel(
            title: '2. एकत्रित की जाने वाली जानकारी',
            content: 'नाम, पंजीकृत मोबाइल, ईमेल, परिवार वंशावली के रिश्ते, गाँव, गोत्र, फोटो एवं पुश नोटिफिकेशन हेतु डिवाइस टोकन।',
          ),
          LegalSectionModel(
            title: '3. डेटा सुरक्षा एवं थर्ड-पार्टी',
            content: 'हमारा डेटा Neon PostgreSQL एवं Cloudflare R2 पर सुरक्षित है। हम व्यावसायिक विज्ञापनों हेतु आपका डेटा किसी को नहीं बेचते।',
          ),
          LegalSectionModel(
            title: '4. खाता हटाने का अधिकार (Account Deletion)',
            content: 'आप प्रोफ़ाइल स्क्रीन में नीचे "Delete Account" विकल्प पर जाकर सीधे अपना खाता स्थायी रूप से हटा सकते हैं या randerparivaar@gmail.com पर संपर्क कर सकते हैं। इसके बाद आप कभी भी पुनः नया पंजीकरण कर सकते हैं।',
          ),
        ],
      );
    }
    return LegalDocumentModel(
      title: 'Privacy Policy',
      lastUpdated: 'September 2026',
      contactEmail: 'randerparivaar@gmail.com',
      sections: [
        LegalSectionModel(
          title: '1. Introduction',
          content: 'Akhil Bhartiya Rander Parivar Samaj ("ABRP") is committed to protecting the privacy of our community members.',
        ),
        LegalSectionModel(
          title: '2. Information We Collect',
          content: 'Personal identifiers (name, mobile, email), family tree relationships, native village, gotra, avatars, and FCM notification tokens.',
        ),
        LegalSectionModel(
          title: '3. Third-Party Services & Data Safety',
          content: 'We use Neon PostgreSQL for secure storage, Cloudflare R2 for images, and Firebase FCM for notifications. We do not sell or trade personal data to commercial third parties.',
        ),
        LegalSectionModel(
          title: '4. Account Deletion & Re-registration (Google Play Policy)',
          content: 'You can permanently delete your user account directly inside the app via Profile > Delete Account, or submit a request on our web portal https://api.abrp.walogics.in/delete-account. Your credentials and tokens are removed, freeing your phone and email for clean re-registration.',
        ),
        LegalSectionModel(
          title: '5. Contact',
          content: 'Questions or data deletion inquiries can be sent to randerparivaar@gmail.com.',
        ),
      ],
    );
  }

  LegalDocumentModel _getFallbackTerms(AppLanguage lang) {
    if (lang == AppLanguage.hi) {
      return LegalDocumentModel(
        title: 'नियम एवं शर्तें (Terms & Conditions)',
        lastUpdated: 'सितंबर 2026',
        contactEmail: 'randerparivaar@gmail.com',
        sections: [
          LegalSectionModel(
            title: '1. नियमों की स्वीकृति',
            content: 'इस ऐप का उपयोग करके आप अखिल भारतीय रांदड़ परिवार समाज के नियमों व नीतियों से सहमत होते हैं।',
          ),
          LegalSectionModel(
            title: '2. प्रामाणिक जानकारी',
            content: 'परिवार वंशावली एवं व्यापारिक प्रविष्टियों में केवल सत्य एवं सत्यापित जानकारी दर्ज करें।',
          ),
          LegalSectionModel(
            title: '3. आचार संहिता',
            content: 'समाज डायरेक्टरी के संपर्कों का उपयोग केवल पारिवारिक एवं सामाजिक सद्भाव हेतु करें, किसी भी व्यावसायिक स्पैम हेतु नहीं।',
          ),
        ],
      );
    }
    return LegalDocumentModel(
      title: 'Terms & Conditions',
      lastUpdated: 'September 2026',
      contactEmail: 'randerparivaar@gmail.com',
      sections: [
        LegalSectionModel(
          title: '1. Acceptance of Terms',
          content: 'By accessing this mobile application, you agree to comply with our community terms and guidelines.',
        ),
        LegalSectionModel(
          title: '2. Accurate Information',
          content: 'Members must provide authentic and verifiable family details and directory information.',
        ),
        LegalSectionModel(
          title: '3. Code of Conduct',
          content: 'The directory is intended exclusively for community networking. Commercial spam or harassment is strictly prohibited.',
        ),
      ],
    );
  }

  List<FaqModel> _getFallbackFaqs(AppLanguage lang) {
    if (lang == AppLanguage.hi) {
      return [
        FaqModel(
          category: 'खाता एवं वंशावली',
          question: 'मैं अपने परिवार को कैसे जोड़ूँ?',
          answer: 'ऐप ड्रॉअर में "Family Tree" या "Onboard Family" पर जाएं और अपने परिवार की जानकारी दर्ज करें।',
        ),
        FaqModel(
          category: 'सत्यापन',
          question: 'सत्यापन कैसे होता है?',
          answer: 'आपके क्षेत्र के अधिकृत क्षेत्र संयोजक (Zone Coordinator) द्वारा आपकी प्रविष्टि का सत्यापन किया जाता है।',
        ),
        FaqModel(
          category: 'खाता हटाना',
          question: 'क्या मैं खाता हटाने के बाद दोबारा पंजीकरण कर सकता हूँ?',
          answer: 'हाँ, खाता हटाने पर आपका मोबाइल और ईमेल तुरंत मुक्त हो जाते हैं और आप कभी भी पुनः नया पंजीकरण कर सकते हैं।',
        ),
      ];
    }
    return [
      FaqModel(
        category: 'Account & Family Tree',
        question: 'How do I add my family to the directory?',
        answer: 'Navigate to "Family Tree" or "Onboard Family" in the drawer and submit your family and member details.',
      ),
      FaqModel(
        category: 'Verification',
        question: 'How does verification work?',
        answer: 'Designated Zone Coordinators review submitted family entries for authenticity before they are approved.',
      ),
      FaqModel(
        category: 'Account Deletion',
        question: 'Can I re-register after deleting my account?',
        answer: 'Yes! When you delete your account, your mobile and email are freed, so you can re-register anytime with a fresh account.',
      ),
    ];
  }
}

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return LegalRepository(dio);
});
