import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for handling SMS operations including verification codes
class SmsService {
  // For development - simulate SMS sending
  // In production, integrate with Firebase SMS, Twilio, etc.

  /// Send SMS verification code
  Future<bool> sendVerificationCode({
    required String phoneNumber,
    required String fullName,
    required String verificationCode,
    required String userType,
  }) async {
    try {
      // For development, log the SMS details
      if (kDebugMode) {
        print('📱 SMS VERIFICATION CODE:');
        print('Phone: $phoneNumber');
        print('Name: $fullName');
        print('Type: $userType');
        print('Code: $verificationCode');
        print('==================================');
      }

      // TODO: In production, integrate with SMS service
      // Example Twilio integration:
      /*
      final response = await http.post(
        Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': twilioPhoneNumber,
          'To': phoneNumber,
          'Body': 'Your Cue Sports verification code is: $verificationCode. Valid for 10 minutes.',
        },
      );

      if (response.statusCode == 201) {
        print('✅ SMS sent successfully to $phoneNumber');
        return true;
      } else {
        print('❌ Failed to send SMS: ${response.body}');
        return false;
      }
      */

      // Simulate successful SMS sending
      await Future.delayed(const Duration(milliseconds: 800));

      print('✅ SMS verification code sent successfully to $phoneNumber');
      return true;
    } catch (e) {
      print('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Generate a 6-digit verification code
  String generateVerificationCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(899999)).toString();
  }

  /// Send password reset SMS
  Future<bool> sendPasswordResetCode({
    required String phoneNumber,
    required String fullName,
    required String resetCode,
  }) async {
    try {
      if (kDebugMode) {
        print('📱 PASSWORD RESET SMS:');
        print('Phone: $phoneNumber');
        print('Name: $fullName');
        print('Reset Code: $resetCode');
        print('==================================');
      }

      // Simulate successful SMS sending
      await Future.delayed(const Duration(milliseconds: 800));

      print('✅ Password reset SMS sent successfully to $phoneNumber');
      return true;
    } catch (e) {
      print('❌ Error sending password reset SMS: $e');
      return false;
    }
  }
}
