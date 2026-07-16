class DirectoryConstants {
  static const List<Map<String, String>> maritalStatuses = [
    {'value': 'single', 'label': 'Single / अविवाहित'},
    {'value': 'married', 'label': 'Married / विवाहित'},
    {'value': 'widowed', 'label': 'Widowed / विधुर/विधवा'},
    {'value': 'divorced', 'label': 'Divorced / तलाकशुदा'},
  ];

  static const List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Don\'t Know'];

  static const List<Map<String, String>> genders = [
    {'value': 'male', 'label': 'Male / पुरुष'},
    {'value': 'female', 'label': 'Female / महिला'},
  ];

  static const List<Map<String, String>> occupations = [
    {'value': 'business', 'label': 'Business / व्यापार'},
    {'value': 'salaried', 'label': 'Salaried Job / नौकरी'},
    {'value': 'professional', 'label': 'Professional (CA, Doctor, etc.) / पेशेवर'},
    {'value': 'student', 'label': 'Student / विद्यार्थी'},
    {'value': 'retired', 'label': 'Retired / सेवानिवृत्त'},
    {'value': 'homemaker', 'label': 'Homemaker / गृहणी'},
    {'value': 'other', 'label': 'Other / अन्य'},
  ];

  static const List<Map<String, String>> industryCategories = [
    {'value': 'textiles', 'label': 'Textiles & Garments / वस्त्र और परिधान'},
    {'value': 'healthcare', 'label': 'Healthcare & Medical / स्वास्थ्य और चिकित्सा'},
    {'value': 'finance_legal', 'label': 'Financial & Legal / वित्तीय और कानूनी'},
    {'value': 'retail_grocery', 'label': 'Retail & Grocery / खुदरा और किराना'},
    {'value': 'real_estate', 'label': 'Real Estate & Construction / रियल एस्टेट और निर्माण'},
    {'value': 'it_software', 'label': 'IT & Software / आईटी और सॉफ्टवेयर'},
    {'value': 'education', 'label': 'Education & Coaching / शिक्षा और कोचिंग'},
    {'value': 'manufacturing', 'label': 'Manufacturing & Industries / विनिर्माण और उद्योग'},
    {'value': 'food_hospitality', 'label': 'Food & Hospitality / खाद्य और आतिथ्य'},
    {'value': 'other', 'label': 'Others / अन्य'},
  ];

  static const List<String> commonTags = [
    'Wholesale',
    'Retail',
    'Manufacturer',
    'Service Provider',
    'Consultant',
    'Distributor',
    'Trader',
    'Exporter',
    'Own Establishment'
  ];

  static const List<String> daysOptions = [
    'Mon - Sat',
    'Mon - Fri',
    'All Days',
    'Custom',
  ];

  static const List<String> timeOptions = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM', '08:30 PM', '09:00 PM', '10:00 PM'
  ];
}
