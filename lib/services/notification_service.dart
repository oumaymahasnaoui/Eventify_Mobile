import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    _initialized = true;
  }

  /// Request notification permissions for Android 13+
  Future<void> _requestAndroidPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap here
    // You can navigate to a specific screen or perform actions
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'reclamation_channel', // Channel ID
      'Réclamations', // Channel name
      channelDescription: 'Notifications pour les réclamations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFFCE1126), // Red color matching your theme
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // Notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show status change notification
  Future<void> showStatusChangeNotification({
    required String oldStatus,
    required String newStatus,
    required int reclamationId,
  }) async {
    final String statusText = _getStatusText(newStatus);
    final String title = 'Réclamation #$reclamationId';
    final String body = 'Statut changé: $statusText';

    await showNotification(
      title: title,
      body: body,
      payload: 'reclamation_$reclamationId',
    );
  }

  /// Show reclamation resolved notification
  Future<void> showResolvedNotification(int reclamationId) async {
    await showNotification(
      title: '✅ Réclamation résolue!',
      body: 'Votre réclamation #$reclamationId a été résolue.',
      payload: 'reclamation_$reclamationId',
    );
  }

  /// Show reclamation in progress notification
  Future<void> showInProgressNotification(int reclamationId) async {
    await showNotification(
      title: '🔄 Réclamation en cours',
      body: 'Votre réclamation #$reclamationId est en cours de traitement.',
      payload: 'reclamation_$reclamationId',
    );
  }

  /// Show reclamation rejected notification
  Future<void> showRejectedNotification(int reclamationId) async {
    await showNotification(
      title: '❌ Réclamation rejetée',
      body: 'Votre réclamation #$reclamationId a été rejetée.',
      payload: 'reclamation_$reclamationId',
    );
  }

  /// Show new response notification
  Future<void> showNewResponseNotification(int reclamationId) async {
    await showNotification(
      title: '💬 Nouvelle réponse',
      body: 'Vous avez reçu une réponse à votre réclamation #$reclamationId.',
      payload: 'reclamation_$reclamationId',
    );
  }

  /// Get status text in French
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'resolved':
        return 'Résolue';
      case 'rejected':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}

/// Global function to show in-app SnackBar notification
void showStatusNotification(
  BuildContext context, {
  required String message,
  bool isSuccess = true,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = isSuccess ? const Color(0xFFCE1126) : Colors.red;
  final icon = isSuccess ? Icons.check_circle : Icons.error;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}

/// Show success notification (in-app + local)
Future<void> showSuccessNotification(
  BuildContext context, {
  required String message,
  String? title,
  bool showLocalNotification = true,
}) async {
  // Show in-app SnackBar
  showStatusNotification(context, message: message, isSuccess: true);

  // Show local notification if enabled
  if (showLocalNotification) {
    await NotificationService().showNotification(
      title: title ?? '✅ Succès',
      body: message,
    );
  }
}

/// Show error notification (in-app only)
void showErrorNotification(
  BuildContext context, {
  required String message,
}) {
  showStatusNotification(context, message: message, isSuccess: false);
}

/// Show reclamation status change notification (both types)
Future<void> notifyStatusChange(
  BuildContext context, {
  required String newStatus,
  required int reclamationId,
  String? oldStatus,
}) async {
  String message = '';
  
  switch (newStatus) {
    case 'resolved':
      message = 'Votre réclamation #$reclamationId a été résolue !';
      await NotificationService().showResolvedNotification(reclamationId);
      break;
    case 'in_progress':
      message = 'Votre réclamation #$reclamationId est en cours de traitement.';
      await NotificationService().showInProgressNotification(reclamationId);
      break;
    case 'rejected':
      message = 'Votre réclamation #$reclamationId a été rejetée.';
      await NotificationService().showRejectedNotification(reclamationId);
      break;
    case 'pending':
      message = 'Votre réclamation #$reclamationId est en attente.';
      break;
  }

  // Show in-app notification
  if (message.isNotEmpty) {
    showStatusNotification(context, message: message);
  }

  // Show local notification for status changes
  if (oldStatus != null && oldStatus != newStatus) {
    await NotificationService().showStatusChangeNotification(
      oldStatus: oldStatus,
      newStatus: newStatus,
      reclamationId: reclamationId,
    );
  }
}
