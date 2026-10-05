import 'customer_preferences_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? profileImage;
  final bool emailVerified;
  final bool isBlocked;
  final CustomerPreferences? preferences;

  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    this.role = 'customer',
    this.phone,
    this.address,
    this.profileImage,
    this.emailVerified = false,
    this.isBlocked = false,
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'customer') as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      profileImage: json['profileImage'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      preferences: json['preferences'] is Map<String, dynamic>
          ? CustomerPreferences.fromJson(json['preferences'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'address': address,
    'profileImage': profileImage,
    'emailVerified': emailVerified,
    'isBlocked': isBlocked,
    if (preferences != null) 'preferences': preferences!.toJson(),
  };
}
