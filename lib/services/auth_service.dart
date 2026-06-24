// services/auth_service.dart
// services/auth_service.dart - UPDATED WITH PASSWORD RESET
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/travel_agency_model.dart';
import 'email_service.dart';

class AuthService extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  late EmailService emailService;

  static const String BACKEND_URL = 'http://localhost:3000/api/auth';

  User? _currentUser;
  TravelAgency? _currentAgency;
  String? _userType;
  bool _isOtpRequired = false;

  AuthService() {
    emailService = EmailService();
  }

  User? get currentUser => _currentUser;
  TravelAgency? get currentAgency => _currentAgency;
  String? get userType => _userType;
  bool get isOtpRequired => _isOtpRequired;
  bool get isAuthenticated => _currentUser != null;
  bool get isAgency => _userType == 'agency';
  bool get isUser => _userType == 'user';

  // ========================
  // USER REGISTRATION (Via Backend)
  // ========================
  Future<bool> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Starting user registration via backend for: $email');

      final response = await http
          .post(
            Uri.parse('$BACKEND_URL/register/user'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'fullName': fullName.trim(),
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Backend registration successful: ${data['userId']}');

        await Future.delayed(Duration(seconds: 2));
        await smartLogin(email: email, password: password);
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ User registration error: $e');
      throw Exception('User registration error: $e');
    }
  }

  // ========================
  // AGENCY REGISTRATION (Via Backend)
  // ========================
  Future<bool> registerAgency({
    required AgencyRegistrationRequest request,
    required Map<String, String> documentUrls,
  }) async {
    try {
      print(
          '🔄 Starting agency registration via backend for: ${request.ownerEmail}');

      final response = await http
          .post(
            Uri.parse('$BACKEND_URL/register/agency'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'agencyName': request.agencyName,
              'ownerFullName': request.ownerFullName,
              'ownerEmail': request.ownerEmail,
              'ownerPhone': request.ownerPhone,
              'password': request.password,
              'officeAddress': request.officeAddress,
              'officePhone': request.officePhone,
              'businessLicenseNumber': request.businessLicenseNumber,
              'taxId': request.taxId,
              'websiteUrl': request.websiteUrl,
              'bankAccountHolder': request.bankAccountHolder,
              'bankAccountNumber': request.bankAccountNumber,
              'bankName': request.bankName,
              'branchName': request.branchName,
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Backend agency registration successful: ${data['agencyId']}');

        await Future.delayed(Duration(seconds: 2));
        await smartLogin(email: request.ownerEmail, password: request.password);
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Agency registration failed');
      }
    } catch (e) {
      print('❌ Agency registration error: $e');
      throw Exception('Agency registration error: $e');
    }
  }

  // ========================
  // SMART LOGIN (USER + AGENCY)
  // ========================
  Future<bool> smartLogin({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Starting login for: $email');

      final authResponse = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (authResponse.user == null) {
        throw Exception('Login failed: Invalid credentials');
      }

      _currentUser = authResponse.user;
      print('✅ User authenticated: ${authResponse.user!.id}');

      final profile = await supabase
          .from('profiles')
          .select('user_type')
          .eq('id', authResponse.user!.id)
          .single();

      _userType = profile['user_type'];
      print('✅ User type: $_userType');

      if (_userType == 'agency') {
        await _handleAgencyLogin(authResponse.user!.id);
      } else {
        _isOtpRequired = false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login error: $e');
    }
  }

  // ========================
  // AGENCY LOGIN HANDLER
  // ========================
  Future<void> _handleAgencyLogin(String userId) async {
    try {
      final agency = await supabase
          .from('travel_agencies')
          .select()
          .eq('user_id', userId)
          .single();

      _currentAgency = TravelAgency.fromJson(agency);
      print('✅ Agency loaded: ${_currentAgency!.agencyName}');

      if (!_currentAgency!.otpVerified) {
        _isOtpRequired = true;
        print('⚠️ OTP verification required');
      } else {
        _isOtpRequired = false;
        await supabase.from('agency_login_history').insert({
          'agency_id': _currentAgency!.id,
          'login_method': 'password',
        });
        print('✅ OTP already verified, login successful');
      }
    } catch (e) {
      print('❌ Agency login check error: $e');
      throw Exception('Agency login check error: $e');
    }
  }

  // ========================
  // OTP VERIFICATION (Via Backend)
  // ========================
  Future<bool> verifyOtp({
    required String otpCode,
  }) async {
    try {
      if (_currentAgency == null) {
        throw Exception('No agency found');
      }

      print('🔄 Verifying OTP via backend for agency: ${_currentAgency!.id}');

      final response = await http
          .post(
            Uri.parse('$BACKEND_URL/verify-otp'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'agencyId': _currentAgency!.id,
              'otpCode': otpCode.trim(),
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ OTP verified successfully via backend');

        _currentAgency = _currentAgency!.copyWith(
          otpVerified: true,
          otpVerifiedAt: DateTime.now(),
        );

        await supabase.from('agency_login_history').insert({
          'agency_id': _currentAgency!.id,
          'login_method': 'otp',
        });

        _isOtpRequired = false;
        notifyListeners();

        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      print('❌ OTP verification error: $e');
      throw Exception('OTP verification error: $e');
    }
  }

  // ========================
  // RESEND OTP (Via Backend)
  // ========================
  Future<bool> resendOtp() async {
    try {
      if (_currentAgency == null) {
        throw Exception('No agency found');
      }

      print('🔄 Resending OTP via backend for agency: ${_currentAgency!.id}');

      final response = await http
          .post(
            Uri.parse('$BACKEND_URL/resend-otp'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'agencyId': _currentAgency!.id,
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ OTP resent successfully via backend');
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Resend OTP failed');
      }
    } catch (e) {
      print('❌ Resend OTP error: $e');
      throw Exception('Resend OTP error: $e');
    }
  }

  // ========================
  // PASSWORD RESET - REQUEST
  // ========================
  Future<bool> requestPasswordReset({
    required String email,
  }) async {
    try {
      print('🔄 Password reset requested for: $email');

      // ✅ Option 1: Use Backend for custom email with token
      final response = await http
          .post(
            Uri.parse('$BACKEND_URL/request-password-reset'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ Password reset email sent via backend');
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Password reset request failed');
      }
    } catch (e) {
      print('⚠️ Backend password reset failed, trying Supabase Auth');
      try {
        // ✅ Fallback: Use Supabase Auth
        await supabase.auth.resetPasswordForEmail(email.trim());
        print('✅ Password reset email sent via Supabase');
        return true;
      } catch (supabaseError) {
        print('❌ Password reset request error: $supabaseError');
        throw Exception('Password reset request error: $supabaseError');
      }
    }
  }

  // ========================
  // PASSWORD RESET - VERIFY TOKEN & UPDATE
  // ========================
  Future<bool> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      print('🔄 Verifying reset token and updating password for: $email');

      final response = await http
          .post(
            Uri.parse('$BACKEND_URL/reset-password'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'resetToken': resetToken.trim(),
              'newPassword': newPassword.trim(),
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ Password reset successful via backend');
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      print('❌ Password reset error: $e');
      throw Exception('Password reset error: $e');
    }
  }

  // ========================
  // PASSWORD UPDATE - DIRECT (For authenticated users)
  // ========================
  Future<bool> updatePasswordDirect({
    required String newPassword,
  }) async {
    try {
      print('🔄 Updating password for current user');

      await supabase.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );

      print('✅ Password updated successfully');
      return true;
    } catch (e) {
      print('❌ Password update error: $e');
      throw Exception('Password update error: $e');
    }
  }

  // ========================
  // LOGOUT
  // ========================
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      _currentUser = null;
      _currentAgency = null;
      _userType = null;
      _isOtpRequired = false;
      notifyListeners();
      print('✅ Logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
      throw Exception('Logout error: $e');
    }
  }

  // ========================
  // CHECK AUTH STATUS
  // ========================
  Future<void> checkAuthStatus() async {
    try {
      final session = supabase.auth.currentSession;
      if (session != null) {
        _currentUser = session.user;
        print('✅ Session found for: ${session.user.email}');

        final profile = await supabase
            .from('profiles')
            .select('user_type')
            .eq('id', session.user.id)
            .single();

        _userType = profile['user_type'];
        print('✅ User type: $_userType');

        if (_userType == 'agency') {
          await _handleAgencyLogin(session.user.id);
        }
      }
      notifyListeners();
    } catch (e) {
      print('⚠️ Auth status check error: $e');
    }
  }
}
