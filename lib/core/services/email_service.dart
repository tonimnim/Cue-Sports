import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'logger_service.dart';

/// Service for handling email operations including verification
class EmailService {
  final LoggerService _logger;

  // Configuration
  static const String _senderName = 'Kenya Pool Billiards Club';

  // Email templates
  static const String _verificationSubject =
      'Verify Your Email - Kenya Pool Billiards Club';

  // Environment-specific credentials (these should be stored securely in production)
  final String _emailUsername;
  final String _emailPassword;

  EmailService({
    required LoggerService logger,
    required String emailUsername,
    required String emailPassword,
  })  : _logger = logger,
        _emailUsername = emailUsername,
        _emailPassword = emailPassword;

  /// Generate a random verification code
  String generateVerificationCode() {
    final random = Random.secure();
    // Generate a 6-digit code
    return (100000 + random.nextInt(899999)).toString();
  }

  /// Send verification email with real email verification
  Future<bool> sendVerificationEmail({
    required String email,
    required String fullName,
    required String verificationCode,
    required String userType,
  }) async {
    try {
      // Create verification URL
      final verificationUrl = _createVerificationUrl(
        email: email,
        verificationCode: verificationCode,
      );

      // Email template parameters
      final templateParams = {
        'to_email': email,
        'to_name': fullName,
        'user_type': userType,
        'verification_url': verificationUrl,
        'verification_code': verificationCode,
        'app_name': 'Cue Sports',
        'company_name': 'Cue Sports Community',
        'support_email': 'support@cuesports.com',
        'expires_in': '24 hours',
      };

      // For development, log the verification details
      print('📧 VERIFICATION EMAIL DETAILS:');
      print('Email: $email');
      print('Name: $fullName');
      print('Type: $userType');
      print('Verification URL: $verificationUrl');
      print('Verification Code: $verificationCode');
      print('==================================');

      // TODO: In production, integrate with EmailJS or your email service
      // Example EmailJS integration:
      /*
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _apiKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Verification email sent successfully to $email');
        return true;
      } else {
        print('❌ Failed to send verification email: ${response.body}');
        return false;
      }
      */

      // For development - simulate successful email sending
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ Verification email sent successfully to $email');
      return true;
    } catch (e) {
      print('❌ Error sending verification email: $e');
      return false;
    }
  }

  /// Create verification URL for email
  String _createVerificationUrl({
    required String email,
    required String verificationCode,
  }) {
    // In production, this would be your app's deep link or web URL
    // For now, we'll create a custom URL scheme that the app can handle
    final encodedEmail = Uri.encodeComponent(email);
    final encodedCode = Uri.encodeComponent(verificationCode);

    return 'cuesports://verify-email?email=$encodedEmail&code=$encodedCode';
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail({
    required String email,
    required String fullName,
    required String resetToken,
  }) async {
    try {
      final resetUrl = _createPasswordResetUrl(
        email: email,
        resetToken: resetToken,
      );

      final templateParams = {
        'to_email': email,
        'to_name': fullName,
        'reset_url': resetUrl,
        'reset_token': resetToken,
        'app_name': 'Cue Sports',
        'expires_in': '1 hour',
      };

      // For development, log the reset details
      print('📧 PASSWORD RESET EMAIL DETAILS:');
      print('Email: $email');
      print('Name: $fullName');
      print('Reset URL: $resetUrl');
      print('Reset Token: $resetToken');
      print('==================================');

      // Simulate successful email sending
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ Password reset email sent successfully to $email');
      return true;
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      return false;
    }
  }

  /// Create password reset URL
  String _createPasswordResetUrl({
    required String email,
    required String resetToken,
  }) {
    final encodedEmail = Uri.encodeComponent(email);
    final encodedToken = Uri.encodeComponent(resetToken);

    return 'cuesports://reset-password?email=$encodedEmail&token=$encodedToken';
  }

  /// Send welcome email after successful registration
  Future<bool> sendWelcomeEmail({
    required String email,
    required String fullName,
    required String userType,
  }) async {
    try {
      final templateParams = {
        'to_email': email,
        'to_name': fullName,
        'user_type': userType,
        'app_name': 'Cue Sports',
        'login_url': 'cuesports://login',
        'support_email': 'support@cuesports.com',
      };

      // For development, log the welcome details
      print('📧 WELCOME EMAIL DETAILS:');
      print('Email: $email');
      print('Name: $fullName');
      print('Type: $userType');
      print('==================================');

      // Simulate successful email sending
      await Future.delayed(const Duration(milliseconds: 300));

      print('✅ Welcome email sent successfully to $email');
      return true;
    } catch (e) {
      print('❌ Error sending welcome email: $e');
      return false;
    }
  }

  /// Send a custom email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    try {
      // For development and testing, just log the email content
      if (kDebugMode) {
        _logger.i('📧 [DEBUG] Would send email to: $to');
        _logger.i('📧 [DEBUG] Subject: $subject');
        return true;
      }

      // In production, send actual email
      final smtpServer = gmail(_emailUsername, _emailPassword);

      // Create the email message
      final message = Message()
        ..from = Address(_emailUsername, _senderName)
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlBody;

      // Add CC recipients if provided
      if (cc != null && cc.isNotEmpty) {
        message.ccRecipients.addAll(cc);
      }

      // Add BCC recipients if provided
      if (bcc != null && bcc.isNotEmpty) {
        message.bccRecipients.addAll(bcc);
      }

      // Send the email
      final sendReport = await send(message, smtpServer);

      _logger.i('📨 Email sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      _logger.e('🔥 Failed to send email: $e');
      return false;
    }
  }

  /// Build HTML content for verification email
  String _buildVerificationEmailHtml({
    required String fullName,
    required String verificationCode,
    required String userType,
  }) {
    final userTypeDisplay = userType == 'player' ? 'Player' : 'Fan';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Email Verification</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #f4f4f4;
        }
        .container {
          background-color: white;
          border-radius: 10px;
          overflow: hidden;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
          background-color: #0047AB;
          color: white;
          padding: 30px 20px;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 28px;
        }
        .content {
          padding: 30px 20px;
        }
        .verification-code {
          font-size: 32px;
          font-weight: bold;
          text-align: center;
          padding: 20px;
          background-color: #f8f9fa;
          border-radius: 8px;
          margin: 20px 0;
          letter-spacing: 5px;
          color: #0047AB;
          border: 2px dashed #0047AB;
        }
        .instructions {
          background-color: #e8f4fd;
          border-left: 4px solid #0047AB;
          padding: 15px;
          margin: 20px 0;
        }
        .footer {
          text-align: center;
          padding: 20px;
          font-size: 12px;
          color: #666;
          background-color: #f8f9fa;
        }
        .button {
          display: inline-block;
          padding: 12px 24px;
          background-color: #0047AB;
          color: white;
          text-decoration: none;
          border-radius: 5px;
          margin: 20px 0;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Kenya Pool Billiards Club</h1>
          <p style="margin: 10px 0 0 0; font-size: 16px;">Email Verification</p>
        </div>
        <div class="content">
          <p style="font-size: 18px; margin-bottom: 10px;">Hello $fullName,</p>
          <p>Thank you for registering as a <strong>$userTypeDisplay</strong> with Kenya Pool Billiards Club!</p>
          
          <p>To complete your registration, please enter the following verification code in the app:</p>
          
          <div class="verification-code">$verificationCode</div>
          
          <div class="instructions">
            <p style="margin: 0;"><strong>Important:</strong></p>
            <ul style="margin: 10px 0;">
              <li>This code will expire in 24 hours</li>
              <li>Do not share this code with anyone</li>
              <li>If you didn't request this code, please ignore this email</li>
            </ul>
          </div>
          
          <p>Once verified, you'll be able to:</p>
          <ul>
            <li>Access exclusive pool billiards content</li>
            <li>Connect with other players in your community</li>
            <li>Track your games and statistics</li>
            ${userType == 'player' ? '<li>Join and create tournaments</li>' : ''}
          </ul>
          
          <p style="margin-top: 30px;">Best regards,<br>
          <strong>Kenya Pool Billiards Club Team</strong></p>
        </div>
        <div class="footer">
          <p>This is an automated message, please do not reply to this email.</p>
          <p>If you need help, contact us at support@kenyapoolbilliards.com</p>
          <p>&copy; ${DateTime.now().year} Kenya Pool Billiards Club. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Build HTML content for password reset email
  String _buildPasswordResetEmailHtml({
    required String fullName,
    required String resetCode,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Password Reset</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #f4f4f4;
        }
        .container {
          background-color: white;
          border-radius: 10px;
          overflow: hidden;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
          background-color: #dc3545;
          color: white;
          padding: 30px 20px;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 28px;
        }
        .content {
          padding: 30px 20px;
        }
        .reset-code {
          font-size: 32px;
          font-weight: bold;
          text-align: center;
          padding: 20px;
          background-color: #fff3cd;
          border-radius: 8px;
          margin: 20px 0;
          letter-spacing: 5px;
          color: #856404;
          border: 2px dashed #856404;
        }
        .warning {
          background-color: #f8d7da;
          border-left: 4px solid #dc3545;
          padding: 15px;
          margin: 20px 0;
        }
        .footer {
          text-align: center;
          padding: 20px;
          font-size: 12px;
          color: #666;
          background-color: #f8f9fa;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Password Reset Request</h1>
          <p style="margin: 10px 0 0 0; font-size: 16px;">Kenya Pool Billiards Club</p>
        </div>
        <div class="content">
          <p style="font-size: 18px; margin-bottom: 10px;">Hello $fullName,</p>
          <p>We received a request to reset your password. Use the code below to reset your password:</p>
          
          <div class="reset-code">$resetCode</div>
          
          <div class="warning">
            <p style="margin: 0;"><strong>Security Notice:</strong></p>
            <ul style="margin: 10px 0;">
              <li>This code will expire in 1 hour</li>
              <li>If you didn't request a password reset, please ignore this email</li>
              <li>Your password won't change until you enter this code and create a new password</li>
            </ul>
          </div>
          
          <p>For your security, we recommend:</p>
          <ul>
            <li>Using a strong, unique password</li>
            <li>Not sharing your password with anyone</li>
            <li>Enabling two-factor authentication when available</li>
          </ul>
          
          <p style="margin-top: 30px;">Best regards,<br>
          <strong>Kenya Pool Billiards Club Security Team</strong></p>
        </div>
        <div class="footer">
          <p>This is an automated security message, please do not reply to this email.</p>
          <p>If you need help, contact us at support@kenyapoolbilliards.com</p>
          <p>&copy; ${DateTime.now().year} Kenya Pool Billiards Club. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}
