class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String role; // 'admin', 'member', 'moderator'
  final String preferredLanguage; // 'en', 'hi'
  final String status; // 'active', 'inactive'
  final String? mobile; // registered mobile number

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.preferredLanguage,
    required this.status,
    this.mobile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String,
      preferredLanguage: json['preferredLanguage'] as String,
      status: json['status'] as String,
      mobile: json['mobile'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'role': role,
      'preferredLanguage': preferredLanguage,
      'status': status,
      'mobile': mobile,
    };
  }
}
