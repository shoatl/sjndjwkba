// lib/features/roles/home_controller.dart
//
// Shared by the Level 1, Level 2, and Level 3 Home screens.
// It listens to the node, the one shared alert, and the Admin's settings,
// keeps the latest copy, and runs the responder actions.
//
// It owns no timers for escalation. The server does that. The only timers
// here are display clocks: one to re-check "is the data stale?" and the
// countdown ticker.
//
// The shell creates ONE controller, calls start(), shares it with whichever
// Home screen the role needs, and calls dispose() when the user signs out.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/data/alert_repository.dart';
import '../../core/data/config_repository.dart';
import '../../core/data/node_repository.dart';
import '../../core/models/drainage_models.dart';
import '../../core/utils/countdown.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required this.nodeId,
    required NodeRepository nodes,
    required AlertRepository alerts,
    required ConfigRepository configs,
    DateTime Function()? now,
  })  : _nodes = nodes,
        _alerts = alerts,
        _configs = configs,
        _clockNow = now ?? DateTime.now {
    _now = _clockNow();
  }

  final String nodeId;
  final NodeRepository _nodes;
  final AlertRepository _alerts;
  final ConfigRepository _configs;
  final DateTime Function() _clockNow;

  /// Ticks once a second while an alert has a deadline. Display only.
  final CountdownController countdown = CountdownController();

  NodeStatus? _node;
  DrainageAlert? _alert;
  SystemConfig _config = const SystemConfig();
  DateTime _now = DateTime.now();

  bool _nodeLoaded = false;
  bool _alertLoaded = false;
  bool _connectionLost = false;
  bool _busy = false;

  StreamSubscription<NodeStatus>? _nodeSub;
  StreamSubscription<DrainageAlert?>? _alertSub;
  StreamSubscription<SystemConfig>? _configSub;
  Timer? _clock;
  bool _disposed = false;

  // ---- What the screens read ----------------------------------------------

  NodeStatus? get node => _node;

  /// The open alert, or null when there is none. A cleared alert counts as none.
  DrainageAlert? get activeAlert {
    final a = _alert;
    return (a != null && a.status.isActive) ? a : null;
  }

  SystemConfig get config => _config;

  /// "Now" for stale checks and "last seen" text. Refreshes every 15 seconds.
  DateTime get now => _now;

  /// True until the first node and alert answers (or errors) arrive.
  bool get isLoading => !_nodeLoaded || !_alertLoaded;

  /// The phone could not reach the server. This is not an all-clear.
  bool get connectionLost => _connectionLost;

  /// An action (acknowledge, remark, clear) is running. Disable buttons.
  bool get busy => _busy;

  /// Silence is not safety. True when we cannot trust the node's data:
  /// no connection, never reported, or no report within the stale threshold.
  bool get isStale {
    if (_connectionLost) return true;
    final n = _node;
    if (n == null) return true;
    return n.isStale(_now, _config.staleAfter);
  }

  // ---- Lifecycle -----------------------------------------------------------

  /// Begin listening. Safe to call again to retry after an error.
  void start() {
    _subscribe();
    _clock ??= Timer.periodic(const Duration(seconds: 15), (_) {
      _now = _clockNow();
      _notify();
    });
  }

  /// Pull-to-refresh and "Try again" use this.
  void retry() => _subscribe();

  void _subscribe() {
    _nodeSub?.cancel();
    _alertSub?.cancel();
    _configSub?.cancel();

    _connectionLost = false;
    _now = _clockNow();

    _nodeSub = _nodes.watchStatus(nodeId).listen(
      (status) {
        _node = status;
        _nodeLoaded = true;
        _connectionLost = false;
        _now = _clockNow();
        _notify();
      },
      onError: (Object _) {
        _nodeLoaded = true;
        _connectionLost = true;
        _notify();
      },
    );

    _alertSub = _alerts.watchActiveAlert().listen(
      _applyAlert,
      onError: (Object _) {
        _alertLoaded = true;
        _connectionLost = true;
        _notify();
      },
    );

    _configSub = _configs.watch().listen(
      (c) {
        _config = c;
        _notify();
      },
      onError: (Object _) {
        // Keep the last known settings.
      },
    );

    _loadConfigOnce();
  }

  Future<void> _loadConfigOnce() async {
    try {
      _config = await _configs.fetch();
      _notify();
    } catch (_) {
      // Keep defaults until the watch stream delivers real settings.
    }
  }

  void _applyAlert(DrainageAlert? alert) {
    _alert = alert;
    _alertLoaded = true;
    _connectionLost = false;
    // Display only. The server sends the new deadline after every change.
    countdown.update(deadline: activeAlert?.timerDeadline);
    _notify();
  }

  // ---- Responder actions ---------------------------------------------------
  // Each throws AlertException on failure, so the screen can show a message.
  // The returned alert is already applied to this controller.

  Future<DrainageAlert> acknowledge() =>
      _run((a) => _alerts.acknowledge(a.id));

  Future<DrainageAlert> markCleared() =>
      _run((a) => _alerts.markCleared(a.id));

  Future<DrainageAlert> addRemark(String text) =>
      _run((a) => _alerts.addRemark(a.id, text));

  Future<DrainageAlert> _run(
    Future<DrainageAlert> Function(DrainageAlert alert) action,
  ) async {
    final current = activeAlert;
    if (current == null) {
      throw const AlertException(AlertFailure.notFound);
    }
    if (_busy) return current;

    _busy = true;
    _notify();
    try {
      final updated = await action(current);
      _applyAlert(updated);
      return updated;
    } finally {
      _busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nodeSub?.cancel();
    _alertSub?.cancel();
    _configSub?.cancel();
    _clock?.cancel();
    countdown.dispose();
    super.dispose();
  }
}
