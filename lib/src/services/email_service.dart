import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  // Injected at build time via --dart-define (see .env file)
  static const _smtpUsername = String.fromEnvironment('SMTP_USERNAME');
  static const _smtpPassword = String.fromEnvironment('SMTP_PASSWORD');

  /// Sends a registration OTP email to the user.
  Future<void> sendOtpEmail({
    required String toEmail,
    required String otp,
  }) async {
    await _sendOtpEmail(
      toEmail: toEmail,
      otp: otp,
      subject: 'CoreHealth — Mã xác thực của bạn',
      intro: 'Mã xác thực tài khoản của bạn:',
    );
  }

  Future<void> sendPasswordResetEmail({
    required String toEmail,
    required String otp,
  }) async {
    await _sendOtpEmail(
      toEmail: toEmail,
      otp: otp,
      subject: 'CoreHealth — Mã đặt lại mật khẩu',
      intro: 'Mã đặt lại mật khẩu CoreHealth của bạn:',
    );
  }

  Future<void> _sendOtpEmail({
    required String toEmail,
    required String otp,
    required String subject,
    required String intro,
  }) async {
    if (_smtpUsername.isEmpty || _smtpPassword.isEmpty) {
      if (kReleaseMode) {
        throw StateError(
          'Missing SMTP_USERNAME or SMTP_PASSWORD dart-define.',
        );
      }
      debugPrint(
        'Skipping OTP email because SMTP is not configured. '
        'Recipient: $toEmail, OTP: $otp',
      );
      return;
    }

    final smtpServer = gmail(_smtpUsername, _smtpPassword);

    final message = Message()
      ..from = const Address(_smtpUsername, 'CoreHealth')
      ..recipients.add(toEmail)
      ..subject = subject
      ..html = '''
        <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px">
          <h2 style="color:#22c55e">CoreHealth</h2>
          <p>$intro</p>
          <div style="font-size:36px;font-weight:800;letter-spacing:10px;color:#111;background:#f4f4f4;padding:20px;border-radius:12px;text-align:center">$otp</div>
          <p style="color:#666;font-size:13px;margin-top:16px">Mã có hiệu lực trong 10 phút. Không chia sẻ mã này với ai.</p>
        </div>
      ''';

    await send(message, smtpServer);
  }
}
