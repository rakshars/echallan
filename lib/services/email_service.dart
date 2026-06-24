import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static Future<bool> sendChallanEmail({
    required String recipientEmail,
    required String numberPlate,
    required List<String> violationTypes,
    required String location,
    String? description,
    String? imagePath,
  }) async {
    final String username = dotenv.env['SMTP_EMAIL'] ?? '';
    final String password = dotenv.env['SMTP_PASSWORD'] ?? '';

    if (username.isEmpty || password.isEmpty) {
      print('SMTP credentials are not configured in .env');
      return false;
    }

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'CitiWatch Alerts')
      ..recipients.add(recipientEmail)
      ..subject = 'Violation Report Against ${numberPlate.toUpperCase()}'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 8px;">
          <h2 style="color: #1e3a8a; text-align: center;">CitiWatch - Violation Notice</h2>
          <p>Dear Vehicle Owner,</p>
          <p>This is an automated notification regarding a reported violation for the vehicle bearing registration number <strong>${numberPlate.toUpperCase()}</strong>.</p>
          
          <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
            <tr>
              <td style="padding: 10px; border-bottom: 1px solid #e5e7eb; width: 130px;"><strong>Violation(s):</strong></td>
              <td style="padding: 10px; border-bottom: 1px solid #e5e7eb; color: #dc2626; font-weight: bold;">${violationTypes.join(", ")}</td>
            </tr>
            <tr>
              <td style="padding: 10px; border-bottom: 1px solid #e5e7eb;"><strong>Location:</strong></td>
              <td style="padding: 10px; border-bottom: 1px solid #e5e7eb;">$location</td>
            </tr>
            ${description != null && description.isNotEmpty ? '''
            <tr>
              <td style="padding: 10px; border-bottom: 1px solid #e5e7eb;"><strong>Description:</strong></td>
              <td style="padding: 10px; border-bottom: 1px solid #e5e7eb;">$description</td>
            </tr>
            ''' : ''}
            <tr>
              <td style="padding: 10px; border-bottom: 1px solid #e5e7eb;"><strong>Date Reported:</strong></td>
              <td style="padding: 10px; border-bottom: 1px solid #e5e7eb;">${DateTime.now().toLocal().toString().split('.')[0]}</td>
            </tr>
          </table>

          ${imagePath != null ? '''
          <div style="margin-top: 24px; text-align: center;">
            <p style="margin-bottom: 12px;"><strong>Evidence Image Uploaded:</strong></p>
            <a href="$imagePath" target="_blank" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; font-weight: bold;">View Evidence Photo</a>
          </div>
          ''' : ''}
          
          <p style="margin-top: 30px; font-size: 12px; color: #6b7280; text-align: center;">
            Please drive safely and obey traffic rules.<br>
            <em>This is an automated email, please do not reply.</em>
          </p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } on MailerException catch (e) {
      print('Message not sent. \\n' + e.toString());
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    }
  }
}
