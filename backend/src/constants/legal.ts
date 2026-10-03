export interface LegalSection {
  title: string;
  content: string;
}

export interface LegalDocument {
  title: string;
  lastUpdated: string;
  serviceProvider: string;
  contactEmail: string;
  sections: LegalSection[];
}

export interface FaqItem {
  question: string;
  answer: string;
  category: string;
}

export const TERMS_AND_CONDITIONS: Record<'en' | 'hi', LegalDocument> = {
  en: {
    title: 'Terms & Conditions',
    lastUpdated: '2026-09-26',
    serviceProvider: 'Rander Parivaar ',
    contactEmail: 'randerparivaar@gmail.com',
    sections: [
      {
        title: 'Overview & Acceptance of Terms',
        content: `These terms and conditions apply to the Akhil Bhartiya Rander Parivar Samaj (ABRP) app for mobile devices, together with any related services operated by Rander Parivaar (collectively, the "Application"). Rander Parivaar   is hereby referred to as the "Service Provider".

By downloading or using the Application, you agree to these Terms and Conditions. You should read them carefully before using the Application.`,
      },
      {
        title: 'License to Use the Application',
        content: `Subject to your compliance with these Terms, the Service Provider grants you a limited, non-exclusive, non-transferable, revocable license to install and use the Application on a mobile device for personal community or internal directory purposes. You may not reproduce, distribute, modify, create derivative works from, reverse engineer, decompile, or disassemble the Application, except as and only to the extent that such activity is expressly permitted by applicable law.`,
      },
      {
        title: 'Intellectual Property',
        content: `The Service Provider retains all intellectual property rights in the Application, including its code, design, trademarks, service marks, trade names, logos, and branding (the "IP"). Nothing in these Terms grants you any license or right to use the Service Provider's trademarks, logos, or branding for any purpose. You agree not to remove, alter, or obscure any copyright, trademark, or other proprietary notices displayed in or on the Application.`,
      },
      {
        title: 'Eligibility & Termination',
        content: `You must be at least 16 years of age (the age of digital consent in your jurisdiction) to use the Application. If you are below 16, a parent or legal guardian must review and accept these Terms on your behalf.

The Service Provider may suspend your access to the Application or services if you materially breach these Terms. The Service Provider will provide you with written notice of the breach and, where the breach is capable of cure, you will have 14 days from receipt of notice to remedy the breach.

The Service Provider may suspend or terminate your access immediately without notice if you violate applicable law, infringe intellectual property rights, or engage in activity that could cause harm to other users or the Service Provider. Upon termination, your right to use the Application will end and you must delete all copies from your devices.`,
      },
      {
        title: 'User-Generated Content & Acceptable Use',
        content: `If this Application allows users to post, share, or upload content (such as family member profiles, business listings, advertisements, or event updates), you agree not to post content that:
• Is illegal or violates third-party intellectual property rights (copyright, trademark, patents)
• Is abusive, threatening, harassing, defamatory, or hate speech
• Contains discrimination or incitement to violence or illegal activity
• Is spam, phishing, or contains malware
• Violates the privacy or personal data rights of others
• Is misleading, false, or deceptive
• Contains explicit violence or sexual content

The Service Provider reserves the right to:
• Remove or disable access to content that violates these guidelines
• Suspend or terminate accounts of users who repeatedly violate these guidelines
• Cooperate with law enforcement if illegal content is reported
• Moderate, filter, or hide content that violates these Terms or community guidelines.

If you believe content violates these Terms or infringes your rights, you may report it to the Service Provider at randerparivaar@gmail.com or use the in-app reporting tools.`,
      },
      {
        title: 'Third-Party Services',
        content: `The Application integrates trusted third-party services that have their own terms:
• Google Analytics for Firebase (https://www.google.com/analytics/terms/)
• Firebase Crashlytics & Cloud Messaging (https://firebase.google.com/terms/crashlytics)
• Cloudflare R2 Media Storage (https://www.cloudflare.com/terms/)
• Brevo SMTP Transactional Email Services (https://www.brevo.com/legal/termsofuse/)`,
      },
      {
        title: 'Limitation of Liability',
        content: `To the fullest extent permitted by law, the Service Provider shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to lost profits, data loss, or business interruption, even if advised of the possibility of such damages.

The Service Provider retains full liability for death or personal injury caused by negligence, fraud or fraudulent misrepresentation, or any liability that cannot be excluded under applicable law. The total liability for any claim shall not exceed the amount paid by you for the Application in the preceding 12 months, or the minimum statutory amount permitted by law.`,
      },
      {
        title: 'Indemnification',
        content: `To the fullest extent permitted by law, you agree to indemnify and hold harmless the Service Provider, its affiliates, officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, and expenses, including reasonable legal fees, arising out of or directly related to your breach of these Terms or your intentional misuse of the Application.`,
      },
      {
        title: 'Governing Law, Jurisdiction & DSA Compliance',
        content: `These Terms and Conditions are governed by the laws of the jurisdiction in which the Service Provider is established.

DSA Compliance (Digital Services Act): The Service Provider maintains a single point of contact for direct communication with authorities and recipients of the service at randerparivaar@gmail.com. When the Service Provider restricts access to content or terminates an account, a clear and specific statement of reasons will be provided in accordance with Article 17 of the DSA. Users may submit notices of allegedly illegal content which will be processed without undue delay.`,
      },
      {
        title: 'Changes to These Terms & Conditions',
        content: `The Service Provider may periodically update these Terms and Conditions. You are advised to review this page regularly for changes. Effective as of 2026-09-26.

Contact Us: If you have any questions or suggestions, please contact the Service Provider at randerparivaar@gmail.com.`,
      },
    ],
  },
  hi: {
    title: 'नियम एवं शर्तें (Terms & Conditions)',
    lastUpdated: '2026-09-26',
    serviceProvider: 'रांदड़ परिवार ',
    contactEmail: 'randerparivaar@gmail.com',
    sections: [
      {
        title: 'नियमों की स्वीकृति एवं परिचय',
        content: `ये नियम और शर्तें अखिल भारतीय रांदड़ परिवार समाज (ABRP) मोबाइल ऐप और रांदड़ परिवार  ("सेवा प्रदाता") द्वारा संचालित संबंधित सेवाओं पर लागू होती हैं।

एप्लिकेशन डाउनलोड या उपयोग करके, आप इन नियमों व शर्तों से पूर्णतः सहमत होते हैं। कृपया उपयोग करने से पूर्व इन्हें ध्यानपूर्वक पढ़ें।`,
      },
      {
        title: 'एप्लिकेशन उपयोग हेतु लाइसेंस',
        content: `इन शर्तों के अनुपालन के अधीन, सेवा प्रदाता आपको व्यक्तिगत अथवा आंतरिक डायरेक्टरी उपयोग हेतु एप्लिकेशन इंस्टॉल और उपयोग करने का सीमित, गैर-हस्तांतरणीय, और प्रतिसंहरणीय लाइसेंस प्रदान करता है। बिना अनुमति के कोड कॉपी करना, संशोधन करना अथवा रिवर्स इंजीनियरिंग करना पूर्णतः वर्जित है।`,
      },
      {
        title: 'बौद्धिक संपदा अधिकार',
        content: `एप्लिकेशन, इसके कोड, डिज़ाइन, ट्रेडमार्क, लोगो और ब्रांडिंग के सभी बौद्धिक संपदा अधिकार सेवा प्रदाता के पास सुरक्षित हैं।`,
      },
      {
        title: 'पात्रता एवं समाप्ति',
        content: `एप्लिकेशन का उपयोग करने के लिए आपकी आयु कम से कम 16 वर्ष होनी चाहिए। यदि आपकी आयु 16 वर्ष से कम है, तो माता-पिता या अभिभावक द्वारा इन शर्तों को स्वीकार किया जाना अनिवार्य है।

शर्तों का गंभीर उल्लंघन करने पर सेवा प्रदाता आपकी सेवा समाप्त अथवा निलंबित कर सकता है।`,
      },
      {
        title: 'सदस्य आचार संहिता एवं उपयोग के नियम',
        content: `एप्लिकेशन में प्रोफाइल, व्यापार प्रविष्टि अथवा विज्ञापन जोड़ते समय सदस्य निम्नलिखित का पालन करेंगे:
• कोई भी अवैध, भ्रामक अथवा बौद्धिक संपदा का उल्लंघन करने वाली सामग्री पोस्ट न करें।
• अभद्र भाषा, अपमानजनक टिप्पणी या भेदभावपूर्ण संदेश न भेजें।
• डायरेक्टरी की जानकारी का उपयोग व्यावसायिक स्पैम हेतु न करें।
• असत्य या फर्जी वंशावली विवरण दर्ज न करें।

उल्लंघन की स्थिति में सेवा प्रदाता सामग्री हटाने और खाते को निलंबित करने का अधिकार सुरक्षित रखता है। शिकायत हेतु randerparivaar@gmail.com पर संपर्क करें।`,
      },
      {
        title: 'थर्ड-पार्टी सेवाएं',
        content: `एप्लिकेशन में Google Analytics for Firebase, Firebase Crashlytics, Firebase Cloud Messaging, Cloudflare R2 और Brevo की अधिकृत सेवाएं सम्मिलित हैं।`,
      },
      {
        title: 'दायित्व की सीमा (Limitation of Liability)',
        content: `कानून द्वारा अनुमत अधिकतम सीमा तक, सेवा प्रदाता किसी भी अप्रत्यक्ष या परिणामी नुकसान के लिए उत्तरदायी नहीं होगा।`,
      },
      {
        title: 'नियमों में परिवर्तन एवं संपर्क',
        content: `सेवा प्रदाता इन नियमों को समय-समय पर अद्यतन कर सकता है। प्रभावी तिथि: 2026-09-26।

प्रश्न अथवा सुझाव हेतु कृपया randerparivaar@gmail.com पर संपर्क करें।`,
      },
    ],
  },
};

export const PRIVACY_POLICY: Record<'en' | 'hi', LegalDocument> = {
  en: {
    title: 'Privacy Policy',
    lastUpdated: '2026-09-26',
    serviceProvider: 'Rander Parivaar ',
    contactEmail: 'randerparivaar@gmail.com',
    sections: [
      {
        title: 'Introduction & Scope',
        content: `This privacy policy applies to the Akhil Bhartiya Rander Parivar Samaj (ABRP) app for mobile devices, together with any related services operated by Rander Parivaar  (collectively, the "Application"). Rander Parivaar   is hereby referred to as the "Service Provider".

The Service Provider is dedicated to safeguarding the privacy and confidentiality of personal data entrusted to us by community members.`,
      },
      {
        title: 'Information Collection and Use',
        content: `The Application collects information when you download, register, and use it:
• User Provided Identifiers: Full name, registered mobile phone number, email address, password hash, and Google account profile (when using Google Sign-In).
• Community & Genealogical Data: Family tree connections (head of family, parents, spouse, children), native village, gotra, residential address, marital status, and dates of birth/anniversary.
• User Contributed Media: Profile photos, avatars, and business cards/logos uploaded to secure Cloudflare R2 storage.
• Device & Usage Data: Internet Protocol (IP) address, pages visited, operating system version, and Firebase Cloud Messaging (FCM) device tokens used for community notification delivery.`,
      },
      {
        title: 'Cookies & Tracking Technologies',
        content: `The Application or its third-party SDKs may use tokens, SDKs, and local secure storage to support authentication, session security, push notifications, and crash diagnostics. Where required by applicable law, user consent will be obtained.`,
      },
      {
        title: 'Third-Party Services & Access',
        content: `The Application utilizes trusted third-party services that have their own Privacy Policies:
• Google Analytics for Firebase: https://firebase.google.com/support/privacy
• Firebase Crashlytics & Cloud Messaging: https://firebase.google.com/support/privacy/
• Neon Serverless PostgreSQL Database (Encrypted at rest and in transit)
• Cloudflare R2 Object Storage (Encrypted media storage)
• Brevo SMTP API (Transactional email dispatches)

The Service Provider does not sell, rent, or trade your personal data to external advertisers or commercial telemarketers. Information is shared only as required by law, to protect community safety, or with trusted service providers who adhere strictly to this privacy policy.`,
      },
      {
        title: 'Account Deletion & Data Rights (Google Play Policy)',
        content: `In strict compliance with Google Play Developer policies, you have complete control over your account and data:
• In-App Deletion: You can permanently delete your user account directly inside the app at any time by navigating to Profile > Account Management > Delete Account.
• Web-Based Deletion Request: If you have uninstalled the app or lost access to your device, you can submit an account deletion request via our public web portal at https://abrp.vercel.app/delete-account or by emailing randerparivaar@gmail.com.
• Effect of Account Deletion & Re-Registration:
  1. Your login credentials, email address, password hash, Google account links, and registered mobile links are permanently purged.
  2. All device sessions and Firebase Cloud Messaging (FCM) push notification tokens are deleted.
  3. Your email address and mobile phone number are freed, allowing you to freely re-register with a fresh account at any time in the future.
  4. To preserve community family tree integrity, your genealogical entry in the directory remains preserved as an unlinked family node so ancestral lineage is not broken.`,
      },
      {
        title: 'Your Rights & California Privacy Rights (CCPA/CPRA)',
        content: `You may request access to, correction of, or deletion of your personal data held by the Service Provider by contacting randerparivaar@gmail.com.

California Residents: If you are a California resident, you have the right to know what personal information is collected, the right to request deletion, the right to opt out of any sale or sharing of personal information, and the right to non-discrimination for exercising these rights. Contact randerparivaar@gmail.com to exercise these rights.`,
      },
      {
        title: 'Data Retention Policy',
        content: `The Service Provider retains personal data based on necessity for community services:
• User Provided Data: Retained for the duration of your active use of the Application plus 12 months thereafter, unless deletion is requested earlier.
• Automatically Collected & Log Data: Retained for up to 24 months from collection.
• Aggregated and Anonymized Data: Retained indefinitely as it no longer identifies any individual.`,
      },
      {
        title: 'Children\'s Privacy',
        content: `The Application is not intended for unsupervised children under 16 years of age. Minors within family trees are added exclusively by authorized parents or family heads as dependent genealogical records. If you are aware that a minor has provided personal information without parental consent, please contact randerparivaar@gmail.com so we can take immediate corrective action.`,
      },
      {
        title: 'Security & Data Breach Notification',
        content: `The Service Provider employs robust physical, electronic, and procedural safeguards (including TLS 1.3 / HTTPS encryption in transit and secure hashed storage) to protect your information. In the unlikely event of a security breach affecting your personal data, the Service Provider will notify you promptly in accordance with applicable legal requirements.`,
      },
      {
        title: 'Changes & Contact Us',
        content: `The Service Provider may update this Privacy Policy from time to time. Effective as of 2026-09-26.

Contact Us: If you have any questions or data requests, please contact the Service Provider via email at randerparivaar@gmail.com.`,
      },
    ],
  },
  hi: {
    title: 'गोपनीयता नीति (Privacy Policy)',
    lastUpdated: '2026-09-26',
    serviceProvider: 'रांदड़ परिवार ',
    contactEmail: 'randerparivaar@gmail.com',
    sections: [
      {
        title: 'प्रस्तावना एवं परिचय',
        content: `यह गोपनीयता नीति अखिल भारतीय रांदड़ परिवार समाज (ABRP) मोबाइल एप्लिकेशन और रांदड़ परिवार  ("सेवा प्रदाता") द्वारा संचालित सेवाओं पर लागू होती है।

सेवा प्रदाता समाज बंधुओं द्वारा प्रदान की गई व्यक्तिगत जानकारी की सुरक्षा और गोपनीयता बनाए रखने हेतु पूर्ण रूप से प्रतिबद्ध है।`,
      },
      {
        title: 'एकत्रित की जाने वाली जानकारी',
        content: `एप्लिकेशन के उपयोग के दौरान निम्नलिखित जानकारी एकत्र की जाती है:
• व्यक्तिगत पहचान: पूरा नाम, पंजीकृत मोबाइल नंबर, ईमेल पता, पासवर्ड और गूगल प्रोफ़ाइल विवरण।
• समाज एवं परिवार वंशावली: परिवार प्रमुख, माता-पिता, जीवनसाथी, बच्चों के संबंध, मूल गाँव, गोत्र, पता और जन्म/विवाह तिथि।
• मीडिया: प्रोफ़ाइल फ़ोटो, अवतार और व्यापारिक कार्ड (क्लाउडफ्लेयर R2 पर सुरक्षित)।
• डिवाइस एवं तकनीकी डेटा: आईपी पता, ऑपरेटिंग सिस्टम प्रकार, और पुश नोटिफिकेशन हेतु FCM टोकन।`,
      },
      {
        title: 'थर्ड-पार्टी सेवाएं एवं सुरक्षा',
        content: `एप्लिकेशन में केवल विश्वसनीय तृतीय-पक्ष सेवाओं का उपयोग किया जाता है:
• Google Analytics for Firebase एवं Firebase Crashlytics
• Firebase Cloud Messaging (FCM)
• Neon PostgreSQL (एन्क्रिप्टेड डेटाबेस)
• Cloudflare R2 (सुरक्षित मीडिया स्टोरेज)
• Brevo SMTP (ईमेल सेवाएं)

सेवा प्रदाता आपके डेटा को किसी व्यावसायिक विज्ञापनदाता को नहीं बेचता है।`,
      },
      {
        title: 'खाता हटाने का अधिकार एवं पुनः पंजीकरण (Account Deletion & Re-registration)',
        content: `गूगल प्ले स्टोर के नियमों के अनुसार आपको अपना खाता और डेटा हटाने का पूर्ण अधिकार है:
• ऐप के माध्यम से: आप ऐप में Profile > Account Management > Delete Account पर जाकर तुरंत अपना खाता हटा सकते हैं।
• वेब पोर्टल के माध्यम से: यदि आपने ऐप अनइंस्टॉल कर दिया है, तो आप हमारी वेबसाइट https://abrp.vercel.app/delete-account पर जाकर या randerparivaar@gmail.com पर ईमेल भेजकर अनुरोध कर सकते हैं।
• खाता हटाने का प्रभाव:
  1. आपका लॉगिन खाता, पासवर्ड, ईमेल और मोबाइल लिंक स्थायी रूप से हटा दिए जाते हैं।
  2. आपके डिवाइस से जुड़े नोटिफिकेशन टोकन नष्ट कर दिए जाते हैं।
  3. आपका ईमेल और मोबाइल नंबर पूरी तरह मुक्त हो जाता है, जिससे आप भविष्य में कभी भी पुनः नया पंजीकरण (Re-register) कर सकते हैं।
  4. पारिवारिक वंशावली को अक्षुण्ण रखने हेतु परिवार वृक्ष में आपका नाम सुरक्षित रहता है परंतु व्यक्तिगत लॉगिन लिंक समाप्त हो जाता है।`,
      },
      {
        title: 'डेटा सुरक्षा एवं बच्चों की गोपनीयता',
        content: `डेटा संचार पूर्णतः HTTPS/TLS एन्क्रिप्शन द्वारा सुरक्षित है। 16 वर्ष से कम आयु के बच्चों की प्रविष्टि केवल माता-पिता अथवा परिवार प्रमुख द्वारा वंशावली के रूप में की जाती है।`,
      },
      {
        title: 'नीति में बदलाव एवं संपर्क सूत्र',
        content: `यह नीति 2026-09-26 से प्रभावी है।

किसी भी प्रश्न अथवा डेटा हटाने के अनुरोध हेतु कृपया randerparivaar@gmail.com पर संपर्क करें।`,
      },
    ],
  },
};

export const FAQS: Record<'en' | 'hi', FaqItem[]> = {
  en: [
    {
      category: 'Account & Registration',
      question: 'Who can register on the ABRP App?',
      answer: 'Any member of the Akhil Bhartiya Rander Parivar Samaj worldwide can register using their email address or Google Sign-In, and link their active mobile phone number.',
    },
    {
      category: 'Family Tree & Directory',
      question: 'How do I add my family to the directory?',
      answer: 'After signing in, open the Family Tree or Onboard Family section from the Drawer. You can create your family unit by entering your native village, address, and adding member nodes (parents, spouse, children) along with their details.',
    },
    {
      category: 'Verification',
      question: 'What is the verification process by Zone Coordinators?',
      answer: 'To ensure 100% authentic community data, submitted family profiles and business cards are reviewed by the appointed Zone Coordinator for your native area/region. Once reviewed and approved, your profile receives a verified badge and appears across the general directory.',
    },
    {
      category: 'Business Directory',
      question: 'How can I promote my business in the Samaj Directory?',
      answer: 'Go to the Business Directory section in the Drawer and tap "Register My Business". Fill in your business name, industry category, location, contact information, catalog photos, and optional Samaj community discount perks. After coordinator approval, your business will be visible to all members.',
    },
    {
      category: 'Privacy & Security',
      question: 'Who can see my phone number and family details?',
      answer: 'Only verified and authenticated members of the Akhil Bhartiya Rander Parivar Samaj can view directory cards. Your data is never sold to outside commercial advertisers or telemarketers.',
    },
    {
      category: 'Account Management',
      question: 'How can I delete my account, and can I re-register later?',
      answer: 'You can delete your account at any time by going to Profile > Delete Account, or submitting a request at https://abrp.vercel.app/delete-account. All your login credentials, FCM notification tokens, and mobile links will be immediately deleted, freeing your phone number and email. You can freely register again as a new user anytime in the future.',
    },
    {
      category: 'Support',
      question: 'How do I contact the Samaj technical or administrative support team?',
      answer: 'You can send an email directly to randerparivaar@gmail.com with your query or family details, and our administrative team will assist you promptly.',
    },
  ],
  hi: [
    {
      category: 'खाता एवं पंजीकरण',
      question: 'ABRP ऐप पर कौन पंजीकरण कर सकता है?',
      answer: 'अखिल भारतीय रांदड़ परिवार समाज का कोई भी सदस्य ईमेल अथवा गूगल साइन-इन के माध्यम से पंजीकरण कर सकता है और अपना मोबाइल नंबर लिंक कर सकता है।',
    },
    {
      category: 'पारिवारिक वंशावली एवं डायरेक्टरी',
      question: 'मैं अपने परिवार को डायरेक्टरी में कैसे जोड़ सकता हूँ?',
      answer: 'लॉगिन करने के बाद ऐप ड्रॉअर से "Family Tree" या "Onboard Family" पर जाएं। अपना मूल गाँव, पता दर्ज करें और अपने माता-पिता, जीवनसाथी तथा बच्चों की जानकारी जोड़ें।',
    },
    {
      category: 'सत्यापन प्रक्रिया',
      question: 'क्षेत्र संयोजकों (Zone Coordinators) द्वारा सत्यापन कैसे होता है?',
      answer: 'समाज की जानकारी की प्रामाणिकता बनाए रखने हेतु आपके मूल क्षेत्र के नियुक्त संयोजक द्वारा आपकी प्रविष्टि का सत्यापन किया जाता है। सत्यापन के पश्चात प्रोफ़ाइल डायरेक्टरी में सक्रिय हो जाती है।',
    },
    {
      category: 'व्यापार डायरेक्टरी',
      question: 'मैं अपने व्यापार को डायरेक्टरी में कैसे सूचीबद्ध करूँ?',
      answer: 'ड्रॉअर में "Business Directory" में जाकर "Register Business" चुनें। अपने प्रतिष्ठान का नाम, श्रेणी, पता और संपर्क विवरण भरें। संयोजक की स्वीकृति के बाद यह सभी समाज बंधुओं को प्रदर्शित होगी।',
    },
    {
      category: 'खाता प्रबंधन',
      question: 'मैं अपना खाता कैसे हटा सकता हूँ और क्या मैं बाद में दोबारा पंजीकरण कर सकता हूँ?',
      answer: 'आप प्रोफ़ाइल स्क्रीन में नीचे "Delete Account" पर जाकर अपना खाता हटा सकते हैं या https://abrp.vercel.app/delete-account पर अनुरोध कर सकते हैं। आपका लॉगिन विवरण तुरंत हटा दिया जाता है और आप कभी भी उसी ईमेल अथवा फ़ोन से पुनः नया पंजीकरण कर सकते हैं।',
    },
    {
      category: 'सहायता एवं संपर्क',
      question: 'सहायता हेतु समाज समिति से कैसे संपर्क करें?',
      answer: 'किसी भी सहायता हेतु आप randerparivaar@gmail.com पर ईमेल भेज सकते हैं। हमारी टीम आपकी त्वरित सहायता करेगी।',
    },
  ],
};
