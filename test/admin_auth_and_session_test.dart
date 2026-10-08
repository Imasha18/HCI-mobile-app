import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/models/user_model.dart';
import 'package:delivery_app/features/admin/services/admin_session_manager.dart';

void main() {
  group('UserModel Role & Auth Tests', () {
    test('UserModel correctly parses admin role from backend response', () {
      final json = {
        '_id': '64f1a2b3c4d5e6f7a8b9c0d1',
        'name': 'System Administrator',
        'email': 'admin@homebite.com',
        'role': 'admin',
        'isBlocked': false,
        'emailVerified': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '64f1a2b3c4d5e6f7a8b9c0d1');
      expect(user.name, 'System Administrator');
      expect(user.email, 'admin@homebite.com');
      expect(user.role, 'admin');
      expect(user.isBlocked, false);
      expect(user.emailVerified, true);
    });

    test('UserModel correctly parses customer role from backend response', () {
      final json = {
        '_id': '64f1a2b3c4d5e6f7a8b9c0d2',
        'name': 'Nimal Jayasuriya',
        'email': 'customer@homebite.com',
        'role': 'customer',
      };

      final user = UserModel.fromJson(json);

      expect(user.role, 'customer');
      expect(user.email, 'customer@homebite.com');
    });

    test('UserModel serializes to JSON matching backend API format', () {
      const user = UserModel(
        id: '123',
        name: 'Admin User',
        email: 'admin@homebite.com',
        role: 'admin',
      );

      final json = user.toJson();
      expect(json['id'], '123');
      expect(json['role'], 'admin');
      expect(json['email'], 'admin@homebite.com');
    });
  });

  group('AdminSessionManager Tests', () {
    test('Timeout duration is exactly 2 hours', () {
      expect(AdminSessionManager.inactivityTimeout, const Duration(hours: 2));
    });

    test('Timeout message matches required user notification', () {
      expect(
        AdminSessionManager.timeoutMessage,
        'Your admin session expired due to inactivity. Please log in again.',
      );
    });
  });
}
