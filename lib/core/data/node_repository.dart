// lib/core/data/node_repository.dart
//
// The contract for the monitoring node's live readings.
// Interface only: no real or fake data. You implement it with your backend
// (MQTT bridge, REST, websocket, etc.).
//
// NodeStatus lives here because it is only used with this repository.
// Adjust the fields to match what your hardware really reports.

import 'dart:async';

/// Where the node's power comes from.
enum PowerSource { mains, battery, unknown }

/// One snapshot of the node, as reported by the server.
class NodeStatus {
  const NodeStatus({
    required this.nodeId,
    required this.waterStage,
    this.lastSeen,
    this.waterLevelPercent,
    this.rainPercent,
    this.powerSource = PowerSource.unknown,
    this.batteryPercent,
  });

  /// Kept so more nodes can be added later. The UI is single-node.
  final String nodeId;

  /// Water stage 0 to 3. 0 = normal, 3 = most severe (over the curb).
  /// Not the same as the escalation level.
  final int waterStage;

  /// When the node last reported. Null if it has never reported.
  final DateTime? lastSeen;

  /// Water level as a percent of the drain depth, if the node sends it.
  final double? waterLevelPercent;

  /// Rain sensor reading as a percent, if the node sends it.
  final double? rainPercent;

  final PowerSource powerSource;

  /// Only meaningful when [powerSource] is battery.
  final int? batteryPercent;

  /// How long ago the node reported. Null if it never has.
  Duration? age(DateTime now) =>
      lastSeen == null ? null : now.difference(lastSeen!);

  /// Silence is not safety. No report within [staleAfter] means the data
  /// cannot be trusted, and the UI must say "No recent data. This is not an
  /// all-clear." Pass the Admin's SystemConfig.staleAfter.
  ///
  /// Prefer a server-provided "now" if you have one, so a wrong phone clock
  /// cannot hide stale data.
  bool isStale(DateTime now, Duration staleAfter) {
    final a = age(now);
    return a == null || a > staleAfter;
  }
}

abstract class NodeRepository {
  /// One-time read of the latest status.
  Future<NodeStatus> fetchStatus(String nodeId);

  /// Live updates. Emit a new [NodeStatus] whenever the node reports.
  /// Errors on the stream mean the connection was lost, not that the
  /// water is fine.
  Stream<NodeStatus> watchStatus(String nodeId);
}
