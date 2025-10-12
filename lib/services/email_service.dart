// services/email_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // 🔑 Utilisez SendGrid (100 emails/jour gratuits)
  static const String _sendGridApiKey = 'VOTRE_CLE_SENDGRID';
  static const String _sendGridUrl = 'https://api.sendgrid.com/v3/mail/send';

  // 🔑 Alternative: Mailjet (200 emails/jour gratuits)
  static const String _mailjetApiKey = 'VOTRE_CLE_MAILJET';
  static const String _mailjetSecret = 'VOTRE_SECRET_MAILJET';
  static const String _mailjetUrl = 'https://api.mailjet.com/v3.1/send';

  static Future<bool> sendVerificationEmail({
    required String toEmail,
    required String userName,
    required String verificationToken,
  }) async {
    try {
      final verificationUrl = 'https://votre-app.com/verify?token=$verificationToken';

      final response = await http.post(
        Uri.parse(_sendGridUrl),
        headers: {
          'Authorization': 'Bearer $_sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [{'email': toEmail}],
              'subject': '🔐 Vérifiez votre email Eventify',
            }
          ],
          'from': {'email': 'noreply@eventify.com', 'name': 'Eventify'},
          'content': [
            {
              'type': 'text/html',
              'value': '''
                <!DOCTYPE html>
                <html>
                <head>
                  <style>
                    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f4f4f4; }
                    .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                    .header { text-align: center; color: #CE1126; }
                    .button { display: inline-block; padding: 12px 30px; background-color: #CE1126; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
                    .footer { margin-top: 30px; text-align: center; color: #666; font-size: 12px; }
                  </style>
                </head>
                <body>
                  <div class="container">
                    <div class="header">
                      <h1>🎉 Bienvenue sur Eventify !</h1>
                    </div>
                    <p>Bonjour <strong>$userName</strong>,</p>
                    <p>Merci de vous être inscrit sur Eventify. Pour activer votre compte, veuillez cliquer sur le bouton ci-dessous :</p>
                    <div style="text-align: center;">
                      <a href="$verificationUrl" class="button">Vérifier mon email</a>
                    </div>
                    <p>Ou copiez ce lien dans votre navigateur :</p>
                    <p style="word-break: break-all; color: #CE1126;">$verificationUrl</p>
                    <p>Ce lien expirera dans 24 heures.</p>
                    <div class="footer">
                      <p>Si vous n'avez pas créé de compte, ignorez simplement cet email.</p>
                      <p>L'équipe Eventify</p>
                    </div>
                  </div>
                </body>
                </html>
              ''',
            }
          ],
        }),
      );

      return response.statusCode == 202;
    } catch (e) {
      print('❌ Erreur envoi email: $e');
      return false;
    }
  }

  // Alternative avec Mailjet
  static Future<bool> sendVerificationEmailWithMailjet({
    required String toEmail,
    required String userName,
    required String verificationToken,
  }) async {
    try {
      final verificationUrl = 'https://votre-app.com/verify?token=$verificationToken';

      final response = await http.post(
        Uri.parse(_mailjetUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_mailjetApiKey:$_mailjetSecret'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Messages': [
            {
              'From': {'Email': 'noreply@eventify.com', 'Name': 'Eventify'},
              'To': [{'Email': toEmail, 'Name': userName}],
              'Subject': '🔐 Vérifiez votre email Eventify',
              'HTMLPart': '''
                <h1>🎉 Bienvenue sur Eventify !</h1>
                <p>Bonjour <strong>$userName</strong>,</p>
                <p>Veuillez cliquer sur le lien pour vérifier votre email :</p>
                <a href="$verificationUrl" style="padding: 10px 20px; background: #CE1126; color: white; text-decoration: none; border-radius: 5px;">Vérifier mon email</a>
                <p>Lien : $verificationUrl</p>
              ''',
            }
          ]
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur Mailjet: $e');
      return false;
    }
  }
}