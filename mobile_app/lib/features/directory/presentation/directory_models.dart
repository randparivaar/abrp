import '../../../core/utils/name_formatter.dart';

class BusinessProfile {
  final int id;
  final String businessName;
  final String? logoUrl;
  final String industryCategory;
  final String contactMobile;
  final String? whatsappMobile;
  final String? email;
  final String? websiteUrl;
  final String? gstin;
  final String? description;
  final List<String>? tags;
  final Map<String, dynamic>? operatingHours;
  final Map<String, dynamic>? communityPerk;
  final List<dynamic>? catalog;
  final String address;
  final String city;
  final String? state;
  final String? pincode;
  final String? googleMapsLink;

  BusinessProfile({
    required this.id,
    required String businessName,
    this.logoUrl,
    required this.industryCategory,
    required this.contactMobile,
    this.whatsappMobile,
    this.email,
    this.websiteUrl,
    this.gstin,
    this.description,
    this.tags,
    this.operatingHours,
    this.communityPerk,
    this.catalog,
    required this.address,
    required this.city,
    this.state,
    this.pincode,
    this.googleMapsLink,
  }) : businessName = businessName.toTitleCase();

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: json['id'] as int,
      businessName: (json['businessName'] as String? ?? '').toTitleCase(),
      logoUrl: json['logoUrl'] as String?,
      industryCategory: json['industryCategory'] as String,
      contactMobile: json['contactMobile'] as String,
      whatsappMobile: json['whatsappMobile'] as String?,
      email: json['email'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      gstin: json['gstin'] as String?,
      description: json['description'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      operatingHours: json['operatingHours'] as Map<String, dynamic>?,
      communityPerk: json['communityPerk'] as Map<String, dynamic>?,
      catalog: json['catalog'] as List<dynamic>?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      googleMapsLink: json['googleMapsLink'] as String?,
    );
  }
}

class MemberNode {
  final int id;
  final int familyId;
  final String fullName;
  final String gender;
  final String relationshipToHead;
  final String? mobile;
  final String? gotra;
  final int? estimatedAgeOnCreation;
  final DateTime? birthDate;
  final String? education;
  final String? occupationType;
  final String? occupationDetail;
  final int? yearlyIncome;
  final int? fatherId;
  final int? motherId;
  final int? spouseId;
  final String? status; // 'pending' | 'approved'
  final String? bloodGroup;
  final String? maritalStatus;
  final DateTime? anniversaryDate;
  final String? currentAddress;
  final String? currentCity;
  final String? currentState;
  final String? currentPincode;
  final BusinessProfile? businessProfile;
  final String? avatarUrl;
  final String? specialRemarks;
  final String? validationFeedback;

  MemberNode({
    required this.id,
    required this.familyId,
    required String fullName,
    required this.gender,
    required this.relationshipToHead,
    this.mobile,
    this.gotra,
    this.estimatedAgeOnCreation,
    this.birthDate,
    this.education,
    this.occupationType,
    this.occupationDetail,
    this.yearlyIncome,
    this.fatherId,
    this.motherId,
    this.spouseId,
    this.status,
    this.bloodGroup,
    this.maritalStatus,
    this.anniversaryDate,
    this.currentAddress,
    this.currentCity,
    this.currentState,
    this.currentPincode,
    this.businessProfile,
    this.avatarUrl,
    this.specialRemarks,
    this.validationFeedback,
  }) : fullName = fullName.toTitleCase();

  factory MemberNode.fromJson(Map<String, dynamic> json) {
    return MemberNode(
      id: json['id'] as int,
      familyId: json['familyId'] as int,
      fullName: (json['fullName'] as String? ?? '').toTitleCase(),
      gender: json['gender'] as String,
      relationshipToHead: json['relationshipToHead'] as String,
      mobile: json['mobile'] as String?,
      gotra: json['gotra'] as String?,
      estimatedAgeOnCreation: json['estimatedAgeOnCreation'] as int?,
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      education: json['education'] as String?,
      occupationType: json['occupationType'] as String?,
      occupationDetail: json['occupationDetail'] as String?,
      yearlyIncome: json['yearlyIncome'] as int?,
      fatherId: json['fatherId'] as int?,
      motherId: json['motherId'] as int?,
      spouseId: json['spouseId'] as int?,
      status: json['status'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      anniversaryDate: json['anniversaryDate'] != null ? DateTime.tryParse(json['anniversaryDate'] as String) : null,
      currentAddress: json['currentAddress'] as String?,
      currentCity: json['currentCity'] as String?,
      currentState: json['currentState'] as String?,
      currentPincode: json['currentPincode'] as String?,
      businessProfile: json['businessProfile'] != null 
          ? BusinessProfile.fromJson(json['businessProfile'] as Map<String, dynamic>)
          : null,
      avatarUrl: json['avatarUrl'] as String?,
      specialRemarks: json['specialRemarks'] as String?,
      validationFeedback: json['validationFeedback'] as String?,
    );
  }

  int get age {
    if (birthDate != null) {
      return DateTime.now().year - birthDate!.year;
    }
    return estimatedAgeOnCreation ?? 0;
  }
}

class FamilyUnit {
  final int id;
  final String familyCode;
  final String address;
  final String? city;
  final String? state;
  final String? pincode;
  final String villageName;
  final String regionName;

  FamilyUnit({
    required this.id,
    required this.familyCode,
    required this.address,
    this.city,
    this.state,
    this.pincode,
    required this.villageName,
    required this.regionName,
  });

  factory FamilyUnit.fromJson(Map<String, dynamic> json) {
    return FamilyUnit(
      id: json['id'] as int,
      familyCode: json['familyCode'] as String,
      address: json['address'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      villageName: (json['village']?['name'] ?? '') as String,
      regionName: (json['village']?['region']?['name'] ?? '') as String,
    );
  }
}

class FamilyTreeData {
  final FamilyUnit family;
  final List<MemberNode> members;
  final bool canEdit;

  FamilyTreeData({
    required this.family,
    required this.members,
    this.canEdit = true,
  });
}
