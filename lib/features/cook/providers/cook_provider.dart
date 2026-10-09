import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/api_client.dart';

class CookState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? cook;
  final Map<String, dynamic>? dashboardData;
  final Map<String, dynamic>? kitchen;
  final Map<String, dynamic>? bankDetails;
  final Map<String, dynamic>? documents;
  final Map<String, dynamic>? settings;
  final bool isOnline;

  const CookState({
    this.isLoading = false,
    this.error,
    this.cook,
    this.dashboardData,
    this.kitchen,
    this.bankDetails,
    this.documents,
    this.settings,
    this.isOnline = true,
  });

  CookState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? cook,
    Map<String, dynamic>? dashboardData,
    Map<String, dynamic>? kitchen,
    Map<String, dynamic>? bankDetails,
    Map<String, dynamic>? documents,
    Map<String, dynamic>? settings,
    bool? isOnline,
  }) {
    return CookState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      cook: cook ?? this.cook,
      dashboardData: dashboardData ?? this.dashboardData,
      kitchen: kitchen ?? this.kitchen,
      bankDetails: bankDetails ?? this.bankDetails,
      documents: documents ?? this.documents,
      settings: settings ?? this.settings,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class CookNotifier extends StateNotifier<CookState> {
  CookNotifier(this._client, this._storage) : super(const CookState()) {
    checkAuthSession();
  }

  final ApiClient _client;
  final FlutterSecureStorage _storage;

  Future<void> checkAuthSession() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      await fetchDashboard();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
          'role': 'cook',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);
      _client.updateAuthToken(token);

      state = state.copyWith(
        isLoading: false,
        cook: user,
        isOnline: user['isOnline'] as bool? ?? true,
      );

      await fetchDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during login.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String kitchenName,
    required String phone,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/register-cook',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'kitchenName': kitchenName.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'role': 'cook',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final user = data['user'] as Map<String, dynamic>?;

      state = state.copyWith(
        isLoading: false,
        cook: user,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create cook account: $e',
      );
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/verify-email',
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);
      _client.updateAuthToken(token);

      state = state.copyWith(
        isLoading: false,
        cook: user,
        isOnline: user['isOnline'] as bool? ?? true,
      );

      await fetchDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification failed: $e',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> googleAuth({
    required String idToken,
    String? kitchenName,
    String? phone,
    String? address,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.post(
        '/auth/google',
        data: {
          'idToken': idToken,
          'role': 'cook',
          if (kitchenName != null) 'kitchenName': kitchenName.trim(),
          if (phone != null) 'phone': phone.trim(),
          if (address != null) 'address': address.trim(),
          if (name != null) 'name': name.trim(),
        },
      );

      final body = response.data as Map<String, dynamic>;
      if (body['requiresProfileCompletion'] == true) {
        state = state.copyWith(isLoading: false);
        return {
          'requiresProfileCompletion': true,
          'data': body['data'],
        };
      }

      final data = body['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);
      _client.updateAuthToken(token);

      state = state.copyWith(
        isLoading: false,
        cook: user,
        isOnline: user['isOnline'] as bool? ?? true,
      );

      await fetchDashboard();
      return {
        'requiresProfileCompletion': false,
        'user': user,
      };
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed: $e',
      );
      return null;
    }
  }

  Future<void> fetchDashboard() async {
    try {
      final response = await _client.dio.get('/cooks/dashboard');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final cookInfo = data['cook'] as Map<String, dynamic>?;
        state = state.copyWith(
          dashboardData: data,
          isOnline: cookInfo?['isOnline'] as bool? ?? state.isOnline,
        );
      }
    } on DioException catch (e) {
      // Non-fatal on background fetch
      state = state.copyWith(error: ApiClient.messageFrom(e));
    } catch (_) {}
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    final previous = state.isOnline;
    state = state.copyWith(isOnline: isOnline);
    try {
      await _client.dio.put('/cooks/profile', data: {'isOnline': isOnline});
      await fetchDashboard();
    } catch (_) {
      // Revert if error
      state = state.copyWith(isOnline: previous);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.put('/cooks/profile', data: updateData);
      final updatedCook = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        cook: updatedCook,
        isOnline: updatedCook['isOnline'] as bool? ?? state.isOnline,
      );
      await fetchDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.messageFrom(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile.',
      );
      return false;
    }
  }

  Future<void> fetchMyProfile() async {
    try {
      final response = await _client.dio.get('/cook/profile');
      if (response.statusCode == 200) {
        final user = response.data['data'] as Map<String, dynamic>;
        state = state.copyWith(
          cook: user,
          isOnline: user['isOnline'] as bool? ?? state.isOnline,
        );
      }
    } catch (_) {}
  }

  Future<void> fetchKitchen() async {
    try {
      final response = await _client.dio.get('/cook/kitchen');
      if (response.statusCode == 200) {
        final kitchenData = response.data['data'] as Map<String, dynamic>;
        state = state.copyWith(kitchen: kitchenData);
      }
    } catch (_) {}
  }

  Future<bool> updateKitchen(Map<String, dynamic> updateData, {File? imageFile}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      dynamic payload;
      if (imageFile != null) {
        final map = Map<String, dynamic>.from(updateData);
        map['image'] = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        );
        payload = FormData.fromMap(map);
      } else {
        payload = updateData;
      }

      final response = await _client.dio.put('/cook/kitchen', data: payload);
      final updatedKitchen = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(isLoading: false, kitchen: updatedKitchen);
      await fetchMyProfile();
      await fetchDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update kitchen');
      return false;
    }
  }

  Future<void> fetchBankDetails() async {
    try {
      final response = await _client.dio.get('/cook/bank-details');
      if (response.statusCode == 200) {
        final details = response.data['data'] as Map<String, dynamic>;
        state = state.copyWith(bankDetails: details);
      }
    } catch (_) {}
  }

  Future<bool> updateBankDetails({
    required String accountHolderName,
    required String bankName,
    required String branchName,
    required String accountNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.put('/cook/bank-details', data: {
        'accountHolderName': accountHolderName.trim(),
        'bankName': bankName.trim(),
        'branchName': branchName.trim(),
        'accountNumber': accountNumber.trim(),
      });
      final details = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(isLoading: false, bankDetails: details);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to save bank details');
      return false;
    }
  }

  Future<void> fetchDocuments() async {
    try {
      final response = await _client.dio.get('/cook/documents');
      if (response.statusCode == 200) {
        final docs = response.data['data'] as Map<String, dynamic>;
        state = state.copyWith(documents: docs);
      }
    } catch (_) {}
  }

  Future<bool> submitDocument({
    required String documentType,
    String? fileUrl,
    String? fileName,
    File? file,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      dynamic payload;
      if (file != null) {
        payload = FormData.fromMap({
          'documentType': documentType,
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });
      } else {
        final map = <String, dynamic>{'documentType': documentType};
        if (fileUrl != null) map['fileUrl'] = fileUrl;
        if (fileName != null) map['fileName'] = fileName;
        payload = map;
      }

      final response = await _client.dio.post('/cook/documents', data: payload);
      final docs = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(isLoading: false, documents: docs);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to submit document');
      return false;
    }
  }

  Future<void> fetchSettings() async {
    try {
      final response = await _client.dio.get('/cook/settings');
      if (response.statusCode == 200) {
        final settingsData = response.data['data'] as Map<String, dynamic>;
        state = state.copyWith(settings: settingsData);
      }
    } catch (_) {}
  }

  Future<bool> updateSettings(Map<String, dynamic> settingsData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.dio.put('/cook/settings', data: settingsData);
      final updatedSettings = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(isLoading: false, settings: updatedSettings);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update settings');
      return false;
    }
  }

  Future<bool> updateProfilePhoto({File? imageFile, String? imageUrl}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      dynamic payload;
      if (imageFile != null) {
        payload = FormData.fromMap({
          'profileImage': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });
      } else if (imageUrl != null) {
        payload = {'profileImage': imageUrl};
      } else {
        return false;
      }

      final response = await _client.dio.put('/cook/profile', data: payload);
      final updatedCook = response.data['data'] as Map<String, dynamic>;
      state = state.copyWith(isLoading: false, cook: updatedCook);
      await fetchDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.messageFrom(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to update profile photo');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _client.clearCache();
    state = const CookState();
  }
}

final cookProvider = StateNotifierProvider<CookNotifier, CookState>((ref) {
  return CookNotifier(ApiClient(), const FlutterSecureStorage());
});

