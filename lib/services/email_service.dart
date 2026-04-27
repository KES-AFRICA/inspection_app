// lib/services/email_service.dart
import 'package:inspec_app/services/smtp_email_service.dart';

class EmailService {
  static Future<bool> sendOtpEmail({
    required String toEmail,
    required String userName,
    required String otpCode,
  }) async {
    try {
      final result = await SmtpEmailService.sendOtpEmail(
        toEmail: toEmail,
        userName: userName,
        otpCode: otpCode,
      );
      return result.success;
    } catch (e) {
      print('❌ Erreur envoi email: $e');
      return false;
    }
  }
  
  static bool verifyOtp({
    required String email,
    required String otpCode,
  }) {
    return SmtpEmailService.verifyOtp(
      email: email,
      otpCode: otpCode,
    );
  }
  
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
    required String userName,
  }) async {
    final result = await SmtpEmailService.resendOtp(
      email: email,
      userName: userName,
    );
    
    return {
      'success': result.success,
      'errorMessage': result.errorMessage,
      'retryAfterSeconds': result.retryAfterSeconds,
    };
  }
  
  static int? getRemainingSeconds(String email) {
    return SmtpEmailService.getRemainingSeconds(email);
  }
}