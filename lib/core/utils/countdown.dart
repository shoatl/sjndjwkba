// lib/core/utils/countdown.dart
//
// Shows the escalation countdown on screen. DISPLAY ONLY.
// The server owns the timer and does the escalating. When this reaches
// zero the app does nothing except show that the alert is escalating, and
// waits for the server to send the new deadline.
//
// Usage in a screen's State:
//   final _countdown = CountdownController();
//   // when the alert stream emits:
//   _countdown.update(deadline: alert.timerDeadline);
//   // in build:
//   ListenableBuilder(listenable: _countdown,
//       builder: (_, __) => Text(_countdown.text));
//   // in dispose:
//   _countdown.dispose();
//
// Call update() from the stream listener, not from build().

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'time_format.dart';

class CountdownController extends ChangeNotifier {
  CountdownController({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Timer? _timer;
  DateTime? _deadline;
  Duration _serverOffset = Duration.zero;
  Duration? _remaining;

  /// Time left, or null when no timer is running (acknowledged or cleared).
  Duration? get remaining => _remaining;

  /// True while a deadline is set.
  bool get hasDeadline => _deadline != null;

  /// True when the deadline passed and we are waiting for the server to
  /// escalate. Show "Escalating..." rather than 00:00 forever.
  bool get isExpired => _remaining == Duration.zero;

  /// `11:42`, or `--:--` when there is no timer.
  String get text {
    final r = _remaining;
    return r == null ? '--:--' : formatCountdown(r);
  }

  /// Set or clear the deadline.
  ///
  /// [deadline] comes from the server (DrainageAlert.timerDeadline).
  /// Pass null once acknowledged or cleared to stop the timer.
  ///
  /// [serverNow] is the server's current time from the same response. If
  /// you have it, the countdown stays correct even when the phone's clock
  /// is wrong. Without it the phone's clock is trusted.
  void update({DateTime? deadline, DateTime? serverNow}) {
    _timer?.cancel();
    _timer = null;

    _deadline = deadline;
    _serverOffset =
        serverNow == null ? Duration.zero : serverNow.difference(_now());

    if (deadline == null) {
      _remaining = null;
      notifyListeners();
      return;
    }

    _tick();
    if (!isExpired) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final deadline = _deadline;
    if (deadline == null) return;

    final left = deadline.difference(_now().add(_serverOffset));
    _remaining = left.isNegative ? Duration.zero : left;
    notifyListeners();

    if (isExpired) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
