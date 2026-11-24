// lib/core/services/notification_health.dart
//
// What the Profile "Notification health" card shows. Push can fail silently
// and Level 1 has no SMS backup, so people need to see at a glance whether
// their phone can actually receive alerts.
//
// Plain Dart, no packages. The NotificationService fills this in.

/// The phone's permission to show notifications.
enum NotificationPermission {
  enabled,
  blocked, // The person turned notifications off for this app
  notAsked; // Never asked yet
}

class NotificationHealth {
  const NotificationHealth({
    required this.permission,
    required this.deviceRegistered,
    this.lastDeliveredAt,
  });

  final NotificationPermission permission;

  /// True when this phone's push token is registered with the server.
  final bool deviceRegistered;

  /// When the server last delivered a push to this phone, if it knows.
  final DateTime? lastDeliveredAt;

  bool get isHealthy =>
      permission == NotificationPermission.enabled && deviceRegistered;

  /// One plain sentence about what is wrong, or null when all is well.
  String? get problem {
    if (permission == NotificationPermission.blocked) {
      return 'Notifications are blocked for this app. You will not hear '
          'alerts until you turn them on in your phone settings.';
    }
    if (permission == NotificationPermission.notAsked) {
      return 'Notifications are not turned on yet.';
    }
    if (!deviceRegistered) {
      return 'This phone is not registered with the server yet, so alerts '
          'cannot reach it.';
    }
    return null;
  }
}
