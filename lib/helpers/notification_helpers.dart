/// Re-export notification functions from notification_service.dart
/// 
/// All notification functions are already available in notification_service.dart:
/// - showSuccessNotification()
/// - showErrorNotification()
/// - showStatusNotification()
/// - notifyStatusChange()
/// 
/// Import them directly:
/// ```dart
/// import 'package:eventify/services/notification_service.dart';
/// ```
/// 
/// Quick Usage Examples:
/// 
/// 1. Show success message with local notification:
/// ```dart
/// await showSuccessNotification(
///   context,
///   message: 'Votre réclamation a été créée avec succès!',
///   title: 'Succès',
///   showLocalNotification: true,
/// );
/// ```
/// 
/// 2. Show error message (in-app only):
/// ```dart
/// showErrorNotification(
///   context,
///   message: 'Une erreur est survenue',
/// );
/// ```
/// 
/// 3. Show simple status message:
/// ```dart
/// showStatusNotification(
///   context,
///   message: 'Opération réussie!',
///   isSuccess: true,
/// );
/// ```
/// 
/// 4. Notify status change (in-app + local):
/// ```dart
/// await notifyStatusChange(
///   context,
///   newStatus: 'resolved',
///   reclamationId: 123,
///   oldStatus: 'pending',
/// );
/// ```
/// 
/// 5. Show specific local notifications:
/// ```dart
/// final notificationService = NotificationService();
/// 
/// // Resolved
/// await notificationService.showResolvedNotification(reclamationId);
/// 
/// // In Progress
/// await notificationService.showInProgressNotification(reclamationId);
/// 
/// // Rejected
/// await notificationService.showRejectedNotification(reclamationId);
/// 
/// // New Response
/// await notificationService.showNewResponseNotification(reclamationId);
/// 
/// // Custom notification
/// await notificationService.showNotification(
///   title: 'Custom Title',
///   body: 'Custom message here',
///   payload: 'optional_data',
/// );
/// ```
/// 
/// Integration with DatabaseHelper:
/// ```dart
/// Future<void> updateReclamationWithNotification(
///   BuildContext context,
///   int id,
///   String newStatus,
/// ) async {
///   // Get old reclamation
///   final oldReclamation = await DatabaseHelper().getReclamationById(id);
///   
///   // Update in database
///   await DatabaseHelper().updateReclamationStatus(id, newStatus);
///   
///   // Show notification
///   if (context.mounted && oldReclamation != null) {
///     await notifyStatusChange(
///       context,
///       newStatus: newStatus,
///       reclamationId: id,
///       oldStatus: oldReclamation.status,
///     );
///   }
/// }
/// ```

export '../services/notification_service.dart';
