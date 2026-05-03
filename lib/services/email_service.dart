// lib/services/email_service.dart

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {

  // ── Replace with your Gmail credentials ───────────────────────
  static const _fromEmail   = '2022it0076@svce.ac.in';     // ← your Gmail
  static const _appPassword = 'fbvy zeqn axrh llrw';     // ← 16-digit app password

  // ── Send warning email ─────────────────────────────────────────
  static Future<bool> sendWarningEmail({
    required String toEmail,
    required String toName,
  }) async {
    try {
      print('📧 Sending email to $toEmail...');

      final smtpServer = gmail(_fromEmail, _appPassword);

      final message = Message()
        ..from    = Address(_fromEmail, 'SafeChat Admin')
        ..recipients.add(toEmail)
        ..subject = 'SafeChat — Warning Notice'
        ..html    = '''
<div style="font-family: Arial, sans-serif; max-width: 600px; 
            margin: 0 auto; background: #f9f9f9; padding: 30px;
            border-radius: 10px;">

  <div style="background: #0A0E21; padding: 20px; 
              border-radius: 10px; text-align: center;">
    <h2 style="color: #4F8EF7; margin: 0;">🛡️ SafeChat</h2>
    <p style="color: #ffffff70; margin: 5px 0 0;">
      AI-powered safe messaging</p>
  </div>

  <div style="padding: 24px 0;">
    <p style="font-size: 16px; color: #333;">Dear <b>$toName</b>,</p>

    <p style="color: #555; line-height: 1.6;">
      Our AI moderation system has detected <b>repeated harmful 
      messages</b> from your SafeChat account.
    </p>

    <div style="background: #fff3cd; border-left: 4px solid #FFB547;
                padding: 14px; border-radius: 6px; margin: 20px 0;">
      <p style="margin: 0; color: #856404;">
        ⚠️ <b>This is an official warning.</b> Please be respectful 
        to other users. Continued violations will result in your 
        account being <b>permanently blocked</b>.
      </p>
    </div>

    <p style="color: #555; line-height: 1.6;">
      If you believe this is a mistake, please contact our 
      admin team.
    </p>

    <p style="color: #333;">
      Regards,<br>
      <b>SafeChat Admin Team</b>
    </p>
  </div>

  <div style="border-top: 1px solid #eee; padding-top: 16px;
              text-align: center;">
    <p style="color: #999; font-size: 12px;">
      This is an automated message from SafeChat AI Moderation System.
    </p>
  </div>
</div>
''';

      final sendReport = await send(message, smtpServer);
      print('✅ Email sent: ${sendReport.toString()}');
      return true;

    } on MailerException catch (e) {
      print('❌ Mailer error: ${e.message}');
      for (final p in e.problems) {
        print('   Problem: ${p.code} — ${p.msg}');
      }
      return false;
    } catch (e) {
      print('❌ Email error: $e');
      return false;
    }
  }

  // ── Send block notification email ──────────────────────────────
  static Future<bool> sendBlockEmail({
    required String toEmail,
    required String toName,
  }) async {
    try {
      final smtpServer = gmail(_fromEmail, _appPassword);

      final message = Message()
        ..from    = Address(_fromEmail, 'SafeChat Admin')
        ..recipients.add(toEmail)
        ..subject = 'SafeChat — Account Blocked'
        ..html    = '''
<div style="font-family: Arial, sans-serif; max-width: 600px;
            margin: 0 auto; background: #f9f9f9; padding: 30px;
            border-radius: 10px;">

  <div style="background: #0A0E21; padding: 20px;
              border-radius: 10px; text-align: center;">
    <h2 style="color: #FF5C5C; margin: 0;">🛡️ SafeChat</h2>
    <p style="color: #ffffff70; margin: 5px 0 0;">
      AI-powered safe messaging</p>
  </div>

  <div style="padding: 24px 0;">
    <p style="font-size: 16px; color: #333;">Dear <b>$toName</b>,</p>

    <div style="background: #f8d7da; border-left: 4px solid #FF5C5C;
                padding: 14px; border-radius: 6px; margin: 20px 0;">
      <p style="margin: 0; color: #721c24;">
        🚫 <b>Your account has been permanently blocked.</b>
      </p>
    </div>

    <p style="color: #555; line-height: 1.6;">
      Despite receiving previous warnings, your account 
      continued to send harmful messages on SafeChat. 
      As a result, your account has been <b>permanently blocked</b> 
      and you can no longer access the platform.
    </p>

    <p style="color: #333;">
      Regards,<br>
      <b>SafeChat Admin Team</b>
    </p>
  </div>
</div>
''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('❌ Block email error: $e');
      return false;
    }
  }
}