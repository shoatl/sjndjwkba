// lib/core/services/notification_service.dart
//
// The contract for notification settings and the health check. Interface
// only: no real or fake data. You implement it with your push provider
// (Firebase Cloud Messaging, for example) and your settings storage.
//
// The server decides who gets a push or SMS. These settings are the
// person's own preferences, which the server reads.

import 'dart:async';

import 'notification_health.dart';

/// A person's own notification preferences.
class NotificationSettings {
  const NotificationSettings({
    this.pushEnabled = true,
    this.alertSound = true,
    this.smsFallback = true,
  });

  final bool pushEnabled;

  /// Play the loud alert sound for new alerts.
  final bool alertSound;

  /// SMS fallback. Only Level 2 and 3 can use it. Level 1 is push only.
  final bool smsFallback;

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? alertSound,
    bool? smsFallback,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      alertSound: alertSound ?? this.alertSound,
      smsFallback: smsFallback ?? this.smsFallback,
    );
  }
}

abstract class NotificationService {
  /// The signed-in person's saved preferences.
  Future<NotificationSettings> loadSettings();

  /// Save preferences. Returns what was stored.
  Future<NotificationSettings> saveSettings(NotificationSettings settings);

  /// Check permission and device registration.
  Future<NotificationHealth> checkHealth();

  /// Ask the phone for notification permission. Returns true if granted.
  Future<bool> requestPermission();

  /// Open this app's page in the phone's system settings.
  Future<void> openSystemSettings();
}
