// services/email_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  // ⚠️ IMPORTANT: Replace with your actual Resend API key
  // Get it from: https://resend.com/api-keys
  String _resendApiKey = dotenv.env['RESEND_API_KEY'] ?? '';
  static const String _resendBaseUrl = 'https://api.resend.com/emails';

  // ========================
  // SEND OTP ON REGISTRATION
  // ========================
  Future<void> sendAgencyRegistrationOtp({
    required String email,
    required String agencyName,
    required String otp,
  }) async {
    try {
      final response = await http.post(
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
      );

      if (response.statusCode != 200) {
        throw Exception('Resend API error: ${response.body}');
      }

      print('✅ Registration OTP email sent to $email');
    } catch (e) {
      print('❌ Email send error: $e');
      rethrow;
    }
  }

  // ========================
  // SEND OTP ON RESEND
  // ========================
  Future<void> sendAgencyOtpResend({
    required String email,
    required String agencyName,
    required String otp,
  }) async {
    try {
      final response = await http.post(
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
      );

      if (response.statusCode != 200) {
        throw Exception('Resend API error: ${response.body}');
      }

      print('✅ Resend OTP email sent to $email');
    } catch (e) {
      print('❌ Email send error: $e');
      rethrow;
    }
  }

  // ========================
  // EMAIL TEMPLATE: REGISTRATION OTP
  // ========================
  static String _buildRegistrationOtpEmail(String agencyName, String otp) {
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; border-radius: 8px; color: white; text-align: center;">
        <h1 style="margin: 0; font-size: 32px;">🌍 Bhromon</h1>
        <p style="margin: 10px 0; font-size: 16px;">Travel. Connect. Explore.</p>
      </div>

      <div style="background: #f8f9fa; padding: 40px 20px; margin-top: 20px; border-radius: 8px;">
        <h2 style="color: #333; margin-top: 0;">Welcome to Bhromon, $agencyName!</h2>
        
        <p style="color: #666; line-height: 1.6;">
          Your agency account has been successfully created. To complete your registration and start managing bookings, please verify your email with the OTP code below.
        </p>

        <div style="background: white; padding: 30px; margin: 30px 0; border-radius: 8px; text-align: center; border: 2px dashed #667eea;">
          <p style="color: #999; margin: 0 0 10px 0; font-size: 14px;">Your OTP Code</p>
          <p style="color: #667eea; font-size: 48px; font-weight: bold; margin: 0; letter-spacing: 8px;">$otp</p>
          <p style="color: #999; margin: 10px 0 0 0; font-size: 12px;">This code expires in 10 minutes</p>
        </div>

        <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="color: #1976d2; margin: 0; font-size: 14px;">
            🔒 Never share this code with anyone. Bhromon staff will never ask for your OTP.
          </p>
        </div>

        <h3 style="color: #333; margin-top: 30px; margin-bottom: 15px;">Next Steps:</h3>
        <ol style="color: #666; line-height: 1.8;">
          <li>Enter the OTP code above in the app</li>
          <li>Complete your agency setup</li>
          <li>Start receiving bookings from travelers</li>
        </ol>

        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
          <p style="color: #999; font-size: 12px; margin: 0;">
            If you didn't create this account, please ignore this email.
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
  // EMAIL TEMPLATE: RESEND OTP
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
