import 'customer_preferences_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? town;
  final String? city;
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
    this.town,
    this.city,
    this.profileImage,
    this.emailVerified = false,
    this.isBlocked = false,
    this.preferences,
  });

  String get displayTown {
    if (town != null && town!.trim().isNotEmpty) return town!.trim();
    if (city != null && city!.trim().isNotEmpty) return city!.trim();
    if (address != null && address!.trim().isNotEmpty) {
      var cleaned = address!.replaceAll(RegExp(r',\s*Sri Lanka$', caseSensitive: false), '').trim();
      final colomboMatch = RegExp(r'colombo[\s-]*(?:0?[1-9]|1[0-5])\b', caseSensitive: false).firstMatch(cleaned);
      if (colomboMatch != null) {
        final digits = colomboMatch.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.isNotEmpty ? 'Colombo ${digits.padLeft(2, '0')}' : 'Colombo';
      }
      final parts = cleaned.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      for (int i = parts.length - 1; i >= 0; i--) {
        var part = parts[i];
        if (RegExp(r'^sri lanka$', caseSensitive: false).hasMatch(part)) continue;
        if (RegExp(r'^(lk-?)?\d{4,6}$', caseSensitive: false).hasMatch(part)) continue;
        part = part.replaceAll(RegExp(r'[-,\s]*\b\d{4,6}\b.*$'), '').trim();
        if (part.isNotEmpty) {
          return part.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
        }
      }
      if (parts.isNotEmpty) return parts.last;
    }
    return 'Colombo 03';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'customer') as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      town: json['town'] as String?,
      city: json['city'] as String?,
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
    'town': town,
    'city': city,
    'profileImage': profileImage,
    'emailVerified': emailVerified,
    'isBlocked': isBlocked,
    if (preferences != null) 'preferences': preferences!.toJson(),
  };
}
