import 'package:flutter/material.dart';
import 'services/notification_service.dart';

/// Quick test app for notifications
/// Run with: flutter run -t lib/quick_test_notifications.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(QuickTestApp());
}

class QuickTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Notifications',
      theme: ThemeData(
        primaryColor: Color(0xFFCE1126),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFFCE1126),
        ),
      ),
      home: QuickTestScreen(),
    );
  }
}

class QuickTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Test Notifications'),
        backgroundColor: Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Icon(
              Icons.notifications_active,
              size: 80,
              color: Color(0xFFCE1126),
            ),
            SizedBox(height: 16),
            Text(
              'Test des Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Cliquez sur les boutons pour tester',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Test 1: Success notification
            _TestButton(
              title: '✅ Notification de Succès',
              description: 'SnackBar vert + notification locale',
              color: Colors.green,
              onPressed: () async {
                await showSuccessNotification(
                  context,
                  message: 'Votre réclamation a été créée avec succès!',
                  title: '✅ Succès',
                  showLocalNotification: true,
                );
              },
            ),
            SizedBox(height: 16),

            // Test 2: Error notification
            _TestButton(
              title: '❌ Notification d\'Erreur',
              description: 'SnackBar rouge (in-app seulement)',
              color: Colors.red,
              onPressed: () {
                showErrorNotification(
                  context,
                  message: 'Une erreur est survenue lors de l\'opération',
                );
              },
            ),
            SizedBox(height: 16),

            // Test 3: Status - Resolved
            _TestButton(
              title: '✅ Réclamation Résolue',
              description: 'Changement de statut: Résolu',
              color: Colors.green[700]!,
              onPressed: () async {
                await notifyStatusChange(
                  context,
                  newStatus: 'resolved',
                  reclamationId: 123,
                  oldStatus: 'pending',
                );
              },
            ),
            SizedBox(height: 16),

            // Test 4: Status - In Progress
            _TestButton(
              title: '🔄 Réclamation En Cours',
              description: 'Changement de statut: En cours',
              color: Colors.blue,
              onPressed: () async {
                await notifyStatusChange(
                  context,
                  newStatus: 'in_progress',
                  reclamationId: 456,
                  oldStatus: 'pending',
                );
              },
            ),
            SizedBox(height: 16),

            // Test 5: Status - Rejected
            _TestButton(
              title: '❌ Réclamation Rejetée',
              description: 'Changement de statut: Rejeté',
              color: Colors.red[700]!,
              onPressed: () async {
                await notifyStatusChange(
                  context,
                  newStatus: 'rejected',
                  reclamationId: 789,
                  oldStatus: 'in_progress',
                );
              },
            ),
            SizedBox(height: 16),

            // Test 6: Local notification only
            _TestButton(
              title: '🔔 Notification Locale Uniquement',
              description: 'Notification système (pas de SnackBar)',
              color: Colors.purple,
              onPressed: () async {
                await NotificationService().showNotification(
                  title: '🔔 Test Notification Locale',
                  body: 'Cette notification apparaît dans la barre système!',
                );
                
                // Show confirmation snackbar
                if (context.mounted) {
                  showStatusNotification(
                    context,
                    message: 'Notification locale envoyée! Vérifiez la barre système.',
                  );
                }
              },
            ),
            SizedBox(height: 16),

            // Test 7: New Response
            _TestButton(
              title: '💬 Nouvelle Réponse',
              description: 'Notification de nouvelle réponse',
              color: Colors.orange,
              onPressed: () async {
                await NotificationService().showNewResponseNotification(999);
                
                if (context.mounted) {
                  showStatusNotification(
                    context,
                    message: 'Vous avez reçu une nouvelle réponse!',
                  );
                }
              },
            ),
            SizedBox(height: 32),

            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• SnackBar: Apparaît en bas de l\'écran\n'
                      '• Notification Locale: Swipez du haut vers le bas pour voir\n'
                      '• Mettez l\'app en arrière-plan pour tester les notifications locales\n'
                      '• Sur Android 13+, autorisez les notifications quand demandé',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const _TestButton({
    required this.title,
    required this.description,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.touch_app,
                  color: color,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
