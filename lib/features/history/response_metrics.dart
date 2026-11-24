// lib/features/history/response_metrics.dart
//
// Response-time numbers for the Level 3 Home and History screens, worked
// out from the incidents the app already has. Plain Dart.
//
// "Started" is the earliest timeline entry. Times for incidents that were
// never acknowledged (cleared on site first) are left out of the
// acknowledge average instead of counted as zero.

import '../../core/models/drainage_models.dart';

extension AlertTimes on DrainageAlert {
  /// When the incident began: the earliest timeline entry, or null.
  DateTime? get startedAt {
    DateTime? first;
    for (final entry in timeline) {
      if (first == null || entry.at.isBefore(first)) first = entry.at;
    }
    return first;
  }

  /// Time from start to Acknowledge. Null if nobody acknowledged.
  Duration? get timeToAcknowledge {
    final start = startedAt;
    final ack = acknowledgedBy;
    if (start == null || ack == null) return null;
    final d = ack.at.difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  /// Time from start to Mark Cleared. Null if not cleared.
  Duration? get timeToClear {
    final start = startedAt;
    final cleared = clearedBy;
    if (start == null || cleared == null) return null;
    final d = cleared.at.difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  /// The time used to page through history: start, else the first stamp.
  DateTime? get pagingTime =>
      startedAt ?? acknowledgedBy?.at ?? clearedBy?.at;
}

class ResponseMetrics {
  const ResponseMetrics({
    required this.total,
    required this.active,
    required this.unacknowledged,
    this.averageAcknowledge,
    this.averageClear,
  });

  factory ResponseMetrics.from(List<DrainageAlert> alerts) {
    var active = 0;
    var unacknowledged = 0;
    var ackMicros = 0;
    var ackCount = 0;
    var clearMicros = 0;
    var clearCount = 0;

    for (final a in alerts) {
      if (a.status.isActive) active++;
      if (!a.isAcknowledged) unacknowledged++;
      final ack = a.timeToAcknowledge;
      if (ack != null) {
        ackMicros += ack.inMicroseconds;
        ackCount++;
      }
      final clear = a.timeToClear;
      if (clear != null) {
        clearMicros += clear.inMicroseconds;
        clearCount++;
      }
    }

    return ResponseMetrics(
      total: alerts.length,
      active: active,
      unacknowledged: unacknowledged,
      averageAcknowledge:
          ackCount == 0 ? null : Duration(microseconds: ackMicros ~/ ackCount),
      averageClear: clearCount == 0
          ? null
          : Duration(microseconds: clearMicros ~/ clearCount),
    );
  }

  final int total;
  final int active;

  /// Incidents nobody acknowledged (including ones cleared on site first).
  final int unacknowledged;

  final Duration? averageAcknowledge;
  final Duration? averageClear;
}
