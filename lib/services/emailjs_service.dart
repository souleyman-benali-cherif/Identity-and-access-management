import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends transactional emails through EmailJS REST API.
class EmailJsService {
  static const String _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  static const String _publicKey = String.fromEnvironment(
    'EMAILJS_PUBLIC_KEY',
    defaultValue: 'kVCV--ua2rTsmwRX8',
  );

  static const String _serviceId = String.fromEnvironment(
    'EMAILJS_SERVICE_ID',
    defaultValue: 'service_jvk04h4',
  );

  static const String _otpTemplateId = String.fromEnvironment(
    'EMAILJS_TEMPLATE_OTP',
    defaultValue: 'template_i3iijhp',
  );

  static const String _resetTemplateId = String.fromEnvironment(
    'EMAILJS_TEMPLATE_RESET',
    defaultValue: 'template_wahfvk7',
  );

  Future<bool> sendOtpEmail({
    required String toEmail,
    required String otpCode,
    required String appName,
    String? toName,
  }) async {
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));

    return _send(
      templateId: _otpTemplateId,
      templateParams: {
        'email': toEmail,
        'to_name': toName ?? '',
        'otp_code': otpCode,
        'otp': otpCode,
        'code': otpCode,
        'passcode': otpCode,
        'one_time_password': otpCode,
        'app_name': appName,
        'company_name': appName,
        'expiry_text': '5 minutes',
        'time': expiresAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      },
    );
  }

  Future<bool> sendResetTokenEmail({
    required String toEmail,
    required String resetToken,
    required String appName,
    String? toName,
  }) async {
    final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));

    return _send(
      templateId: _resetTemplateId,
      templateParams: {
        'email': toEmail,
        'to_name': toName ?? '',
        'reset_token': resetToken,
        'token': resetToken,
        'resetToken': resetToken,
        'app_name': appName,
        'company_name': appName,
        'expiry_text': '1 hour',
        'time': expiresAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      },
    );
  }

  Future<bool> _send({
    required String templateId,
    required Map<String, dynamic> templateParams,
  }) async {
    if (_publicKey.isEmpty || _serviceId.isEmpty || templateId.isEmpty) {
      debugPrint('[EmailJsService] Missing EmailJS configuration.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: const {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': templateId,
          'user_id': _publicKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      debugPrint(
        '[EmailJsService] Send failed (${response.statusCode}): ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('[EmailJsService] Send exception: $e');
      return false;
    }
  }
}
