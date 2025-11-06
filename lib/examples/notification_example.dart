import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

/// Example: How to use notifications with Reclamation updates
/// 
/// This file demonstrates:
/// 1. Initializing the notification service
/// 2. Updating reclamation status
/// 3. Showing in-app and local notifications

class ReclamationNotificationExample extends StatefulWidget {
  const ReclamationNotificationExample({super.key});

  @override
  State<ReclamationNotificationExample> createState() =>
      _ReclamationNotificationExampleState();
}

class _ReclamationNotificationExampleState
    extends State<ReclamationNotificationExample> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Initialize notification service when app starts
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  /// Example 1: Update reclamation status with notification
  Future<void> updateReclamationStatus({
    required int reclamationId,
    required String newStatus,
  }) async {
    try {
      // Get the old reclamation
      final allReclamations = await _dbHelper.getAllReclamations();
      final reclamation = allReclamations.firstWhere(
        (r) => r.id == reclamationId,
        orElse: () => throw Exception('Reclamation not found'),
      );

      // Store old status
      final oldStatus = reclamation.status;

      // Update the reclamation status in database
      await _dbHelper.updateReclamationStatus(reclamationId, newStatus);

      // Show notifications (in-app + local)
      if (mounted) {
        await notifyStatusChange(
          context,
          newStatus: newStatus,
          reclamationId: reclamationId,
          oldStatus: oldStatus,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorNotification(
          context,
          message: 'Erreur lors de la mise à jour: $e',
        );
      }
    }
  }

  /// Example 2: Mark reclamation as resolved
  Future<void> markAsResolved(int reclamationId) async {
    await updateReclamationStatus(
      reclamationId: reclamationId,
      newStatus: 'resolved',
    );
  }

  /// Example 3: Mark reclamation as in progress
  Future<void> markAsInProgress(int reclamationId) async {
    await updateReclamationStatus(
      reclamationId: reclamationId,
      newStatus: 'in_progress',
    );
  }

  /// Example 4: Show custom success notification
  Future<void> showCustomNotification(String message) async {
    await showSuccessNotification(
      context,
      message: message,
      title: 'Eventify',
      showLocalNotification: true,
    );
  }

  /// Example 5: Send new response notification
  Future<void> notifyNewResponse(int reclamationId) async {
    // Show local notification
    await _notificationService.showNewResponseNotification(reclamationId);

    // Show in-app notification
    if (mounted) {
      showStatusNotification(
        context,
        message: 'Vous avez reçu une nouvelle réponse à votre réclamation #$reclamationId',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Examples'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Test Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Click buttons below to test different notification types:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Example 1: Resolve reclamation
          ElevatedButton.icon(
            onPressed: () => markAsResolved(1),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark Reclamation #1 as Resolved'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Example 2: In progress
          ElevatedButton.icon(
            onPressed: () => markAsInProgress(1),
            icon: const Icon(Icons.hourglass_empty),
            label: const Text('Mark Reclamation #1 as In Progress'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Example 3: Reject reclamation
          ElevatedButton.icon(
            onPressed: () => updateReclamationStatus(
              reclamationId: 1,
              newStatus: 'rejected',
            ),
            icon: const Icon(Icons.cancel),
            label: const Text('Mark Reclamation #1 as Rejected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Example 4: New response
          ElevatedButton.icon(
            onPressed: () => notifyNewResponse(1),
            icon: const Icon(Icons.message),
            label: const Text('Simulate New Response Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Example 5: Custom notification
          ElevatedButton.icon(
            onPressed: () => showCustomNotification(
              'Ceci est une notification personnalisée!',
            ),
            icon: const Icon(Icons.notifications),
            label: const Text('Show Custom Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCE1126),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Example 6: Test local notification only
          ElevatedButton.icon(
            onPressed: () async {
              await _notificationService.showNotification(
                title: 'Test Local Notification',
                body: 'Cette notification apparaît même si l\'app est en arrière-plan!',
              );
            },
            icon: const Icon(Icons.notification_important),
            label: const Text('Test Local Notification (Background)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Info card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• SnackBar: Apparaît en bas de l\'écran\n'
                    '• Local Notification: Apparaît dans la barre de notifications\n'
                    '• Les notifications locales fonctionnent même quand l\'app est fermée\n'
                    '• Assurez-vous d\'avoir autorisé les notifications dans les paramètres',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Example of integrating notifications in your existing ReclamationListScreen
/// 
/// In your ReclamationsListScreen, add this to the _deleteReclamation method:
/// 
/// ```dart
/// Future<void> _deleteReclamation(int id) async {
///   final confirm = await showDialog<bool>(...);
///   
///   if (confirm == true) {
///     await _dbHelper.deleteReclamation(id);
///     
///     // Show notification after deletion
///     if (mounted) {
///       showSuccessNotification(
///         context,
///         message: 'Réclamation #$id supprimée avec succès',
///         showLocalNotification: false, // Only in-app for deletion
///       );
///     }
///     
///     _loadReclamations();
///   }
/// }
/// ```
/// 
/// For status updates, create a method like this:
/// 
/// ```dart
/// Future<void> _updateStatus(Reclamation reclamation, String newStatus) async {
///   final oldStatus = reclamation.status;
///   final updated = reclamation.copyWith(status: newStatus);
///   
///   await _dbHelper.updateReclamation(updated);
///   
///   if (mounted) {
///     await notifyStatusChange(
///       context,
///       newStatus: newStatus,
///       reclamationId: reclamation.id!,
///       oldStatus: oldStatus,
///     );
///   }
///   
///   _loadReclamations();
/// }
/// ```
