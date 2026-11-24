// lib/core/data/config_repository.dart
//
// The contract for Admin-editable settings and the master audit log.
// Interface only: no real or fake data.
//
// Settings live on the server so they change without redeploying the app.
// Every signed-in person reads them (the stale threshold and the countdown
// need them). Only an Admin may update them, and the server enforces it.

import 'dart:async';

import '../models/drainage_models.dart';

/// Reasons a config call can fail.
enum ConfigFailure {
  notAllowed, // Not an Admin
  invalidValue, // For example a zero or negative duration
  network,
  unknown,
}

class ConfigException implements Exception {
  const ConfigException(this.failure, [this.message]);

  final ConfigFailure failure;
  final String? message;

  @override
  String toString() =>
      'ConfigException($failure${message == null ? '' : ': $message'})';
}

abstract class ConfigRepository {
  /// The current settings.
  Future<SystemConfig> fetch();

  /// Emits whenever an Admin changes the settings, so a running countdown
  /// or stale check uses the new values.
  Stream<SystemConfig> watch();

  /// Admin only. Saves the new settings and returns what the server stored.
  /// Durations must be greater than zero, or the server rejects them with
  /// [ConfigFailure.invalidValue].
  Future<SystemConfig> update(SystemConfig config);

  /// Admin only. Master audit log of role changes and escalations,
  /// newest first. Pass the last item's time as [before] for the next page.
  Future<List<TimelineEntry>> fetchAuditLog({
    int limit = 50,
    DateTime? before,
  });
}
