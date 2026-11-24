// lib/core/data/alert_repository.dart
//
// The contract for the one shared alert, responder actions, and history.
// Interface only: no real or fake data.
//
// The server runs the escalation timers and enforces every permission.
// This repository never decides who may do what. If a person is not allowed,
// the server answers with AlertFailure.notAllowed.
//
// Alerts hold user IDs only. Names come from the user repository.

import 'dart:async';

import '../models/drainage_models.dart';

/// Reasons an alert call can fail. The UI maps these to friendly text.
enum AlertFailure {
  notAllowed, // The server refused this action for this role
  alreadyAcknowledged, // Someone else tapped Acknowledge first
  alreadyCleared, // The alert is closed
  notFound,
  network,
  unknown,
}

class AlertException implements Exception {
  const AlertException(this.failure, [this.message]);

  final AlertFailure failure;

  /// Optional detail from the server, for logs. Do not show raw to people.
  final String? message;

  @override
  String toString() =>
      'AlertException($failure${message == null ? '' : ': $message'})';
}

abstract class AlertRepository {
  // ---- Reading ------------------------------------------------------------

  /// The one shared alert for the node. Emits null when there is no open
  /// alert. Emits again on every change: escalation, acknowledgment,
  /// rising water, cleared, reopened.
  Stream<DrainageAlert?> watchActiveAlert();

  /// One alert by id, for Alert Detail and history.
  Future<DrainageAlert> fetchAlert(String alertId);

  /// Past incidents, newest first. The server scopes the result to the
  /// signed-in role: Level 1 gets only incidents they are credited on,
  /// Level 2 and 3 get all of them.
  ///
  /// Pass the last item's time as [before] to load the next page.
  Future<List<DrainageAlert>> fetchHistory({
    int limit = 20,
    DateTime? before,
  });

  // ---- Responder actions --------------------------------------------------
  // Every action returns the updated alert so the screen can refresh at once.

  /// One tap by one responder. Stops the timer, sets "In progress", and
  /// stamps the person and time. Throws [AlertFailure.alreadyAcknowledged]
  /// if someone else got there first.
  Future<DrainageAlert> acknowledge(String alertId);

  /// Post a field remark. This automatically credits the author.
  /// Works even if nobody acknowledged.
  Future<DrainageAlert> addRemark(String alertId, String text);

  /// Mark cleared. Works even if nobody acknowledged. The node must then
  /// confirm water below stage 1, otherwise the alert reopens by itself.
  Future<DrainageAlert> markCleared(String alertId);

  /// Level 2 and 3 only: hand the alert to a specific Level 1 or Level 2
  /// person.
  Future<DrainageAlert> reassign(String alertId, String assigneeId);

  // ---- Credit -------------------------------------------------------------

  /// Optional "Who else is responding with you?" after Acknowledge or
  /// Mark Cleared. Adds these people as co-responders.
  Future<DrainageAlert> addCoResponders(
    String alertId,
    List<String> userIds,
  );

  /// Level 2, Level 3 and Admin: replace the credited list on any alert.
  /// The server records every change in the incident timeline.
  Future<DrainageAlert> setCreditedResponders(
    String alertId,
    List<CreditedResponder> responders,
  );
}
