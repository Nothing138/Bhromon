// services/email_service.dart
// services/email_service.dart - FIXED VERSION
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class EmailService {
  // ✅ Load API key from .env file
  late String _resendApiKey;
  static const String _resendBaseUrl = 'https://api.resend.com/emails';
  static const int _timeoutSeconds = 30; // Increased timeout

  EmailService() {
    // Initialize API key from environment
    _resendApiKey = dotenv.env['RESEND_API_KEY'] ?? '';

    if (_resendApiKey.isEmpty) {
      print('⚠️ WARNING: RESEND_API_KEY not found in .env file!');
      print(
          'Expected .env file in project root with: RESEND_API_KEY=your_key_here');
    } else {
      print(
          '✅ RESEND_API_KEY loaded successfully (${_resendApiKey.substring(0, 10)}...)');
    }
  }

  // ========================
  // USER WELCOME EMAIL
  // ========================
  Future<void> sendUserWelcomeEmail({
    required String email,
    required String fullName,
  }) async {
    try {
      if (_resendApiKey.isEmpty) {
        throw Exception('RESEND_API_KEY is not configured');
      }

      print('📧 Sending welcome email to $email');

      final response = await http
          .post(
            Uri.parse(_resendBaseUrl),
            headers: {
              'Authorization': 'Bearer $_resendApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'from': 'onboarding@resend.dev',
              'to': email,
              'subject': 'Welcome to Bhromon - Start Your Travel Adventure! 🌍',
              'html': _buildUserWelcomeEmail(fullName),
            }),
          )
          .timeout(Duration(seconds: _timeoutSeconds))
          .catchError((e) {
        print('❌ Network error sending email: $e');
        throw Exception('Network timeout or error: $e');
      });

      if (response.statusCode == 200) {
        print('✅ User welcome email sent to $email');
      } else {
        print('❌ Resend API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Resend API error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('❌ User email send error: $e');
      rethrow;
    }
  }

  // ========================
  // SEND OTP ON REGISTRATION (AGENCY)
  // ========================
  Future<void> sendAgencyRegistrationOtp({
    required String email,
    required String agencyName,
    required String otp,
  }) async {
    try {
      if (_resendApiKey.isEmpty) {
        throw Exception('RESEND_API_KEY is not configured');
      }

      print('📧 Sending agency registration OTP to $email');

      final response = await http
          .post(
            Uri.parse(_resendBaseUrl),
            headers: {
              'Authorization': 'Bearer $_resendApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'from': 'onboarding@resend.dev',
              'to': email,
              'subject': 'Verify Your Bhromon Agency Account - OTP Code',
              'html': _buildRegistrationOtpEmail(agencyName, otp),
            }),
          )
          .timeout(Duration(seconds: _timeoutSeconds))
          .catchError((e) {
        print('❌ Network error sending OTP: $e');
        throw Exception('Network timeout or error: $e');
      });

      if (response.statusCode == 200) {
        print('✅ Agency registration OTP email sent to $email');
      } else {
        print('❌ Resend API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Resend API error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('❌ Agency OTP email send error: $e');
      rethrow;
    }
  }

  // ========================
  // SEND OTP ON RESEND (AGENCY)
  // ========================
  Future<void> sendAgencyOtpResend({
    required String email,
    required String agencyName,
    required String otp,
  }) async {
    try {
      if (_resendApiKey.isEmpty) {
        throw Exception('RESEND_API_KEY is not configured');
      }

      print('📧 Sending OTP resend email to $email');

      final response = await http
          .post(
            Uri.parse(_resendBaseUrl),
            headers: {
              'Authorization': 'Bearer $_resendApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'from': 'onboarding@resend.dev',
              'to': email,
              'subject': 'Your New Bhromon OTP Code',
              'html': _buildResendOtpEmail(agencyName, otp),
            }),
          )
          .timeout(Duration(seconds: _timeoutSeconds))
          .catchError((e) {
        print('❌ Network error sending resend OTP: $e');
        throw Exception('Network timeout or error: $e');
      });

      if (response.statusCode == 200) {
        print('✅ Agency resend OTP email sent to $email');
      } else {
        print('❌ Resend API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Resend API error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('❌ Resend OTP email send error: $e');
      rethrow;
    }
  }

  // ========================
  // EMAIL TEMPLATE: USER WELCOME
  // ========================
  static String _buildUserWelcomeEmail(String fullName) {
    final firstName = fullName.split(' ').first;
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; border-radius: 8px; color: white; text-align: center;">
        <h1 style="margin: 0; font-size: 32px;">🌍 Bhromon</h1>
        <p style="margin: 10px 0; font-size: 16px;">Travel. Connect. Explore.</p>
      </div>

      <div style="background: #f8f9fa; padding: 40px 20px; margin-top: 20px; border-radius: 8px;">
        <h2 style="color: #333; margin-top: 0;">Welcome to Bhromon, $firstName! 🎉</h2>
        
        <p style="color: #666; line-height: 1.6;">
          Thank you for joining our travel community. Your account has been created successfully and you're now ready to explore amazing destinations, connect with fellow travelers, and share your travel stories.
        </p>

        <div style="background: white; padding: 30px; margin: 30px 0; border-radius: 8px; border-left: 4px solid #667eea;">
          <h3 style="color: #333; margin-top: 0;">What You Can Do Now:</h3>
          <ul style="color: #666; line-height: 1.8;">
            <li>📍 Explore travel destinations and places</li>
            <li>👥 Connect with fellow travelers</li>
            <li>🏖️ Join travel groups in your area</li>
            <li>✍️ Share your travel experiences</li>
            <li>💰 Find great travel deals</li>
            <li>🆘 Access emergency services when needed</li>
          </ul>
        </div>

        <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="color: #1976d2; margin: 0; font-size: 14px;">
            💡 Complete your profile with a photo to get more matches with other travelers!
          </p>
        </div>

        <h3 style="color: #333; margin-top: 30px; margin-bottom: 15px;">Getting Started:</h3>
        <ol style="color: #666; line-height: 1.8;">
          <li>Log in to your account</li>
          <li>Complete your profile</li>
          <li>Explore nearby destinations</li>
          <li>Start connecting with travelers</li>
        </ol>

        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
          <p style="color: #999; font-size: 12px; margin: 0;">
            Have questions? Check out our help center or contact support@bhromon.com
          </p>
        </div>
      </div>

      <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd;">
        <p style="color: #999; font-size: 12px;">
          © 2024 Bhromon. All rights reserved. | 
          <a href="https://bhromon.com" style="color: #667eea; text-decoration: none;">Visit Website</a>
        </p>
      </div>
    </div>
    ''';
  }

  // ========================
  // EMAIL TEMPLATE: AGENCY REGISTRATION OTP
  // ========================
  static String _buildRegistrationOtpEmail(String agencyName, String otp) {
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; border-radius: 8px; color: white; text-align: center;">
        <h1 style="margin: 0; font-size: 32px;">🌍 Bhromon</h1>
        <p style="margin: 10px 0; font-size: 16px;">Travel. Connect. Explore.</p>
      </div>

      <div style="background: #f8f9fa; padding: 40px 20px; margin-top: 20px; border-radius: 8px;">
        <h2 style="color: #333; margin-top: 0;">Welcome to Bhromon, $agencyName! 🎉</h2>
        
        <p style="color: #666; line-height: 1.6;">
          Your agency account has been successfully created and approved! To complete your registration and start managing bookings, please verify your email with the OTP code below.
        </p>

        <div style="background: white; padding: 30px; margin: 30px 0; border-radius: 8px; text-align: center; border: 2px dashed #667eea;">
          <p style="color: #999; margin: 0 0 10px 0; font-size: 14px;">Your OTP Code</p>
          <p style="color: #667eea; font-size: 48px; font-weight: bold; margin: 0; letter-spacing: 8px;">$otp</p>
          <p style="color: #999; margin: 10px 0 0 0; font-size: 12px;">This code expires in 10 minutes</p>
        </div>

        <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="color: #1976d2; margin: 0; font-size: 14px;">
            ✅ Your agency is approved! Enter the OTP to activate your account.
          </p>
        </div>

        <h3 style="color: #333; margin-top: 30px; margin-bottom: 15px;">Next Steps:</h3>
        <ol style="color: #666; line-height: 1.8;">
          <li>Enter the OTP code in the app</li>
          <li>Complete your agency setup</li>
          <li>Start receiving bookings from travelers</li>
        </ol>

        <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="color: #856404; margin: 0; font-size: 12px;">
            🔒 Never share this code with anyone. Bhromon staff will never ask for your OTP.
          </p>
        </div>

        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
          <p style="color: #999; font-size: 12px; margin: 0;">
            If you didn't create this account, please contact support immediately.
          </p>
        </div>
      </div>

      <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd;">
        <p style="color: #999; font-size: 12px;">
          © 2024 Bhromon. All rights reserved.
        </p>
      </div>
    </div>
    ''';
  }

  // ========================
  // EMAIL TEMPLATE: AGENCY RESEND OTP
  // ========================
  static String _buildResendOtpEmail(String agencyName, String otp) {
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; border-radius: 8px; color: white; text-align: center;">
        <h1 style="margin: 0; font-size: 32px;">🌍 Bhromon</h1>
        <p style="margin: 10px 0; font-size: 16px;">Travel. Connect. Explore.</p>
      </div>

      <div style="background: #f8f9fa; padding: 40px 20px; margin-top: 20px; border-radius: 8px;">
        <h2 style="color: #333; margin-top: 0;">Your New OTP Code</h2>
        
        <p style="color: #666; line-height: 1.6;">
          You requested a new OTP code for your Bhromon agency account. Use the code below to verify your identity.
        </p>

        <div style="background: white; padding: 30px; margin: 30px 0; border-radius: 8px; text-align: center; border: 2px dashed #667eea;">
          <p style="color: #999; margin: 0 0 10px 0; font-size: 14px;">Your OTP Code</p>
          <p style="color: #667eea; font-size: 48px; font-weight: bold; margin: 0; letter-spacing: 8px;">$otp</p>
          <p style="color: #999; margin: 10px 0 0 0; font-size: 12px;">This code expires in 10 minutes</p>
        </div>

        <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="color: #856404; margin: 0; font-size: 14px;">
            ⚠️ If you didn't request this code, you can safely ignore this email.
          </p>
        </div>

        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
          <p style="color: #999; font-size: 12px; margin: 0;">
            Need help? Contact us at support@bhromon.com
          </p>
        </div>
      </div>

      <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd;">
        <p style="color: #999; font-size: 12px;">
          © 2024 Bhromon. All rights reserved.
        </p>
      </div>
    </div>
    ''';
  }
}
