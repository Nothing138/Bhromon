// services/agency_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import '../models/travel_agency_model.dart';

class AgencyService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  // Backend URL - Change this to your actual backend
  static const String BACKEND_URL = 'http://localhost:3000/api';
  // For production: 'https://your-backend.com/api'

  late Dio _dio;
  String? _token;
  TravelAgency? _currentAgency;
  String? _error;

  // Getters
  TravelAgency? get currentAgency => _currentAgency;
  String? get error => _error;

  AgencyService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: BACKEND_URL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptor for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          _error = error.message;
          notifyListeners();
          return handler.next(error);
        },
      ),
    );
  }

  // ========================
  // SET TOKEN
  // ========================
  Future<void> setToken() async {
    try {
      final session = supabase.auth.currentSession;
      if (session != null) {
        _token = session.accessToken;
        print(' Token set for agency service');
      }
    } catch (e) {
      print(' Error setting token: $e');
      _error = 'Failed to set authentication token';
    }
  }

  // ========================
  // FETCH AGENCY PROFILE
  // ========================
  Future<bool> fetchAgencyProfile() async {
    try {
      print(' Fetching agency profile...');

      await setToken();

      final response = await _dio.get('/agency/profile');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success']) {
          _currentAgency = TravelAgency.fromJson(data['data']);
          _error = null;
          notifyListeners();
          print(' Agency profile fetched: ${_currentAgency!.agencyName}');
          return true;
        } else {
          _error = data['error'] ?? 'Failed to fetch profile';
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Failed to fetch profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print(' Error fetching agency profile: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================
  // UPDATE AGENCY PROFILE
  // ========================
  Future<bool> updateAgencyProfile({
    required String agencyName,
    required String ownerFullName,
    required String ownerEmail,
    required String ownerPhone,
    required String officeAddress,
    required String websiteUrl,
    String? imageUrl,
  }) async {
    try {
      print(' Updating agency profile...');

      await setToken();

      final requestData = {
        'agencyName': agencyName.trim(),
        'ownerFullName': ownerFullName.trim(),
        'ownerEmail': ownerEmail.trim(),
        'ownerPhone': ownerPhone.trim(),
        'officeAddress': officeAddress.trim(),
        'websiteUrl': websiteUrl.trim(),
      };

      // Add imageUrl if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        requestData['imageUrl'] = imageUrl;
      }

      final response = await _dio.put(
        '/agency/profile',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success']) {
          _currentAgency = TravelAgency.fromJson(data['data']);
          _error = null;
          notifyListeners();
          print(' Agency profile updated successfully');
          return true;
        } else {
          _error = data['error'] ?? 'Failed to update profile';
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print(' Error updating agency profile: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================
  // UPLOAD AGENCY IMAGE
  // ========================
  Future<String?> uploadAgencyImage(File imageFile) async {
    try {
      print(' Uploading agency image...');

      await setToken();

      // Create multipart request
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'agency_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      });

      final response = await _dio.post(
        '/agency/profile/upload-image',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success']) {
          final imageUrl = data['imageUrl'];
          _error = null;
          notifyListeners();
          print(' Image uploaded successfully: $imageUrl');
          return imageUrl;
        } else {
          _error = data['error'] ?? 'Failed to upload image';
          notifyListeners();
          return null;
        }
      } else {
        _error = 'Failed to upload image';
        notifyListeners();
        return null;
      }
    } catch (e) {
      print(' Error uploading image: $e');
      _error = 'Error uploading image: $e';
      notifyListeners();
      return null;
    }
  }

  // ========================
  // GET AGENCY STATISTICS
  // ========================
  Future<Map<String, dynamic>?> getAgencyStats() async {
    try {
      print(' Fetching agency statistics...');

      await setToken();

      final response = await _dio.get('/agency/events/stats');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success']) {
          _error = null;
          notifyListeners();
          print(' Agency stats fetched');
          return data['data'];
        } else {
          _error = data['error'] ?? 'Failed to fetch stats';
          notifyListeners();
          return null;
        }
      } else {
        _error = 'Failed to fetch stats';
        notifyListeners();
        return null;
      }
    } catch (e) {
      print(' Error fetching agency stats: $e');
      _error = 'Error: $e';
      notifyListeners();
      return null;
    }
  }

  // ========================
  // GET ALL AGENCY DOCUMENTS
  // ========================
  Future<List<Map<String, dynamic>>> getAgencyDocuments() async {
    try {
      print(' Fetching agency documents...');

      await setToken();

      final response = await supabase
          .from('agency_documents')
          .select()
          .eq('agency_id', _currentAgency!.id);

      _error = null;
      notifyListeners();
      print(' Agency documents fetched: ${response.length} documents');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print(' Error fetching documents: $e');
      _error = 'Error: $e';
      notifyListeners();
      return [];
    }
  }

  // ========================
  // UPDATE AGENCY DOCUMENTS
  // ========================
  Future<bool> updateAgencyDocument({
    required String documentId,
    required String documentUrl,
  }) async {
    try {
      print(' Updating agency document...');

      await supabase.from('agency_documents').update({
        'document_url': documentUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      _error = null;
      notifyListeners();
      print(' Document updated successfully');
      return true;
    } catch (e) {
      print(' Error updating document: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================
  // GET AGENCY EVENTS COUNT
  // ========================
  Future<Map<String, int>> getEventCounts() async {
    try {
      if (_currentAgency == null) {
        return {'total': 0, 'active': 0, 'cancelled': 0, 'completed': 0};
      }

      print(' Fetching event counts...');

      final events = await supabase
          .from('agency_events')
          .select()
          .eq('agency_id', _currentAgency!.id);

      final total = events.length;
      final active = events.where((e) => e['status'] == 'active').length;
      final cancelled = events.where((e) => e['status'] == 'cancelled').length;
      final completed = events.where((e) => e['status'] == 'completed').length;

      print(
          ' Event counts: Total=$total, Active=$active, Cancelled=$cancelled, Completed=$completed');

      return {
        'total': total,
        'active': active,
        'cancelled': cancelled,
        'completed': completed,
      };
    } catch (e) {
      print(' Error fetching event counts: $e');
      _error = 'Error: $e';
      notifyListeners();
      return {'total': 0, 'active': 0, 'cancelled': 0, 'completed': 0};
    }
  }

  // ========================
  // VERIFY AGENCY OTP (Backup Method)
  // ========================
  Future<bool> verifyOtpDirect({
    required String otpCode,
  }) async {
    try {
      if (_currentAgency == null) {
        throw Exception('No agency found');
      }

      print(' Verifying OTP directly...');

      await setToken();

      final response = await _dio.post(
        '/verify-otp',
        data: {
          'agencyId': _currentAgency!.id,
          'otpCode': otpCode.trim(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success']) {
          print(' OTP verified successfully');
          return true;
        } else {
          _error = data['error'] ?? 'OTP verification failed';
          notifyListeners();
          return false;
        }
      } else {
        _error = 'OTP verification failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print(' Error verifying OTP: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================
  // CLEAR ERROR
  // ========================
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========================
  // RESET SERVICE
  // ========================
  void reset() {
    _currentAgency = null;
    _token = null;
    _error = null;
    notifyListeners();
  }
}

// ========================
// HELPER CLASSES
// ========================
class AgencyRegistrationRequest {
  final String agencyName;
  final String ownerFullName;
  final String ownerEmail;
  final String ownerPhone;
  final String password;
  final String officeAddress;
  final String officePhone;
  final String businessLicenseNumber;
  final String taxId;
  final String websiteUrl;
  final String bankAccountHolder;
  final String bankAccountNumber;
  final String bankName;
  final String branchName;

  AgencyRegistrationRequest({
    required this.agencyName,
    required this.ownerFullName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.password,
    required this.officeAddress,
    required this.officePhone,
    required this.businessLicenseNumber,
    required this.taxId,
    required this.websiteUrl,
    required this.bankAccountHolder,
    required this.bankAccountNumber,
    required this.bankName,
    required this.branchName,
  });
}
