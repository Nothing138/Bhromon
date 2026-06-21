// services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/travel_agency_model.dart';
import 'email_service.dart';

class AuthService extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  final emailService = EmailService();

  User? _currentUser;
  TravelAgency? _currentAgency;
  String? _userType; // 'user' or 'agency'
  bool _isOtpRequired = false;

  User? get currentUser => _currentUser;
  TravelAgency? get currentAgency => _currentAgency;
  String? get userType => _userType;
  bool get isOtpRequired => _isOtpRequired;
  bool get isAuthenticated => _currentUser != null;
  bool get isAgency => _userType == 'agency';
  bool get isUser => _userType == 'user';

  // ========================
  // USER REGISTRATION
  // ========================
  Future<bool> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // Sign up with Supabase Auth
      final response = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'full_name': fullName.trim(),
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed: User creation failed');
      }

      // Create user profile
      await supabase.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName.trim(),
        'username': email.trim().split('@')[0],
        'user_type': 'user',
      });

      _currentUser = response.user;
      _userType = 'user';
      _isOtpRequired = false;
      notifyListeners();

      return true;
    } catch (e) {
      throw Exception('User registration error: $e');
    }
  }

  // ========================
  // AGENCY REGISTRATION - SIMPLIFIED (OTP ONLY, NO APPROVAL)
  // ========================
  Future<bool> registerAgency({
    required AgencyRegistrationRequest request,
    required Map<String, String> documentUrls, // {docType: url}
  }) async {
    try {
      // Step 1: Sign up with Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: request.ownerEmail.trim(),
        password: request.password.trim(),
        data: {
          'full_name': request.ownerFullName.trim(),
        },
      );

      if (authResponse.user == null) {
        throw Exception('Agency registration failed: Auth creation failed');
      }

      final userId = authResponse.user!.id;

      // Step 2: Create user profile with 'agency' type
      await supabase.from('profiles').insert({
        'id': userId,
        'full_name': request.ownerFullName.trim(),
        'username': request.ownerEmail.trim().split('@')[0],
        'user_type': 'agency',
      });

      // Step 3: Create travel agency record - DIRECTLY APPROVED (NO WAITING)
      final agencyResponse = await supabase
          .from('travel_agencies')
          .insert({
            'user_id': userId,
            'agency_name': request.agencyName.trim(),
            'owner_full_name': request.ownerFullName.trim(),
            'owner_email': request.ownerEmail.trim(),
            'owner_phone': request.ownerPhone.trim(),
            'office_address': request.officeAddress.trim(),
            'office_phone': request.officePhone,
            'business_license_number': request.businessLicenseNumber,
            'tax_id': request.taxId,
            'website_url': request.websiteUrl,
            'bank_account_holder': request.bankAccountHolder,
            'bank_account_number': request.bankAccountNumber,
            'bank_name': request.bankName,
            'branch_name': request.branchName,
            'verification_status': 'approved',
            'verified_at': DateTime.now().toIso8601String(),
            'otp_verified': false,
          })
          .select('id')
          .single();

      final agencyId = agencyResponse['id'];

      // Step 4: Upload documents (if any)
      if (documentUrls.isNotEmpty) {
        for (final entry in documentUrls.entries) {
          await supabase.from('agency_documents').insert({
            'agency_id': agencyId,
            'document_type': entry.key,
            'document_url': entry.value,
            'verification_status': 'pending',
          });
        }
      }

      // Step 5: Generate and send OTP (first login verification)
      final otp = _generateOtp();
      final expiresAt = DateTime.now().add(Duration(minutes: 10));

      await supabase.from('agency_otp').insert({
        'agency_id': agencyId,
        'otp_code': otp,
        'expires_at': expiresAt.toIso8601String(),
      });

      // ✅ CRITICAL FIX: Send OTP via email but DON'T FAIL if email fails
      try {
        await emailService.sendAgencyRegistrationOtp(
          email: request.ownerEmail.trim(),
          agencyName: request.agencyName.trim(),
          otp: otp,
        );
        print('✅ OTP email sent successfully');
      } catch (emailError) {
        print('⚠️ Email failed (non-critical): $emailError');
        // Continue - OTP is stored in database, user can ask for resend
      }

      // Sign out after registration
      await supabase.auth.signOut();

      _currentUser = authResponse.user;
      _userType = 'agency';
      _isOtpRequired = false;
      notifyListeners();

      return true;
    } catch (e) {
      throw Exception('Agency registration error: $e');
    }
  }

  // ========================
  // SMART LOGIN (USER + AGENCY) - SIMPLIFIED
  // ========================
  Future<bool> smartLogin({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with Supabase Auth
      final authResponse = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (authResponse.user == null) {
        throw Exception('Login failed: Invalid credentials');
      }

      _currentUser = authResponse.user;

      // Fetch user profile to determine type
      final profile = await supabase
          .from('profiles')
          .select('user_type')
          .eq('id', authResponse.user!.id)
          .single();

      _userType = profile['user_type'];

      // If agency, check OTP status
      if (_userType == 'agency') {
        await _handleAgencyLogin(authResponse.user!.id);
      } else {
        _isOtpRequired = false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // ========================
  // AGENCY LOGIN HANDLER - SIMPLIFIED (NO APPROVAL CHECK)
  // ========================
  Future<void> _handleAgencyLogin(String userId) async {
    try {
      final agency = await supabase
          .from('travel_agencies')
          .select()
          .eq('user_id', userId)
          .single();

      _currentAgency = TravelAgency.fromJson(agency);

      // Check if OTP verification is needed (first login)
      if (!_currentAgency!.otpVerified) {
        _isOtpRequired = true;
      } else {
        _isOtpRequired = false;
        // Log successful login
        await supabase.from('agency_login_history').insert({
          'agency_id': _currentAgency!.id,
          'login_method': 'password',
        });
      }
    } catch (e) {
      throw Exception('Agency login check error: $e');
    }
  }

  // ========================
  // OTP VERIFICATION (Agency First Login)
  // ========================
  Future<bool> verifyOtp({
    required String otpCode,
  }) async {
    try {
      if (_currentUser == null || !isAgency) {
        throw Exception('Invalid OTP verification request');
      }

      // Fetch the latest OTP for this agency
      final otpRecord = await supabase
          .from('agency_otp')
          .select()
          .eq('agency_id', _currentAgency!.id)
          .eq('is_used', false)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      // Validate OTP
      if (otpRecord['otp_code'] != otpCode.trim()) {
        throw Exception('Invalid OTP code');
      }

      // Check expiration
      final expiresAt = DateTime.parse(otpRecord['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('OTP has expired');
      }

      // Mark OTP as used
      await supabase.from('agency_otp').update({
        'is_used': true,
        'used_at': DateTime.now().toIso8601String()
      }).eq('id', otpRecord['id']);

      // Update agency OTP verification status
      await supabase.from('travel_agencies').update({
        'otp_verified': true,
        'otp_verified_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentAgency!.id);

      // Update agency object
      _currentAgency = _currentAgency!.copyWith(
        otpVerified: true,
        otpVerifiedAt: DateTime.now(),
      );

      // Log successful OTP verification login
      await supabase.from('agency_login_history').insert({
        'agency_id': _currentAgency!.id,
        'login_method': 'otp',
      });

      _isOtpRequired = false;
      notifyListeners();

      return true;
    } catch (e) {
      throw Exception('OTP verification error: $e');
    }
  }

  // ========================
  // RESEND OTP - IMPROVED WITH ERROR HANDLING
  // ========================
  Future<bool> resendOtp() async {
    try {
      if (_currentAgency == null) {
        throw Exception('No agency found');
      }

      // Generate new OTP (6 digits)
      final newOtp = _generateOtp();
      final expiresAt = DateTime.now().add(Duration(minutes: 10));

      // Insert new OTP record
      await supabase.from('agency_otp').insert({
        'agency_id': _currentAgency!.id,
        'otp_code': newOtp,
        'expires_at': expiresAt.toIso8601String(),
      });

      // ✅ Send OTP to email but handle failure gracefully
      try {
        await emailService.sendAgencyOtpResend(
          email: _currentAgency!.ownerEmail,
          agencyName: _currentAgency!.agencyName,
          otp: newOtp,
        );
        print('✅ Resend OTP email sent successfully');
      } catch (emailError) {
        print('⚠️ Resend email failed: $emailError');
        // Don't throw - OTP is in database
      }

      return true;
    } catch (e) {
      throw Exception('Resend OTP error: $e');
    }
  }

  // ========================
  // PASSWORD RESET
  // ========================
  Future<bool> requestPasswordReset({
    required String email,
  }) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.bhromon.app://reset-password',
      );
      return true;
    } catch (e) {
      throw Exception('Password reset request error: $e');
    }
  }

  Future<bool> updatePasswordAfterReset({
    required String newPassword,
  }) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );
      return true;
    } catch (e) {
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
    } catch (e) {
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

        final profile = await supabase
            .from('profiles')
            .select('user_type')
            .eq('id', session.user.id)
            .single();

        _userType = profile['user_type'];

        if (_userType == 'agency') {
          await _handleAgencyLogin(session.user.id);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Auth status check error: $e');
    }
  }

  // ========================
  // HELPER: OTP GENERATOR
  // ========================
  String _generateOtp() {
    return (100000 + (DateTime.now().millisecond % 900000)).toString();
  }
}
