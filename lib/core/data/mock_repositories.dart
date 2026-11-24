import 'dart:async';

import '../models/drainage_models.dart';
import '../services/notification_health.dart';
import '../services/notification_service.dart';
import 'alert_repository.dart';
import 'auth_repository.dart';
import 'config_repository.dart';
import 'node_repository.dart';
import 'user_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  AppUser? _current;
  bool _consentAccepted = true;

  static final List<AppUser> _demoUsers = [
    AppUser(
      id: 'u-1',
      name: 'Juan Dela Cruz',
      role: UserRole.level1,
      status: AccountStatus.active,
      phone: '09170000001',
      serviceSpans: [ServiceSpan(start: DateTime(2026, 1, 10))],
    ),
    AppUser(
      id: 'u-2',
      name: 'Maria Santos',
      role: UserRole.level2,
      status: AccountStatus.active,
      phone: '09170000002',
      serviceSpans: [ServiceSpan(start: DateTime(2026, 1, 10))],
    ),
    AppUser(
      id: 'u-3',
      name: 'Kap. Roberto Reyes',
      role: UserRole.level3,
      status: AccountStatus.active,
      phone: '09170000003',
      serviceSpans: [ServiceSpan(start: DateTime(2026, 1, 10))],
    ),
    AppUser(
      id: 'u-admin',
      name: 'System Admin',
      role: UserRole.admin,
      status: AccountStatus.active,
      phone: '09170000000',
      serviceSpans: [ServiceSpan(start: DateTime(2026, 1, 1))],
    ),
  ];

  @override
  Future<SignInResult> signIn({
    required String loginId,
    required String password,
  }) async {
    final trimmed = loginId.trim().toLowerCase();
    final matched = _demoUsers.firstWhere(
      (u) =>
          u.phone == trimmed ||
          u.role.name.toLowerCase() == trimmed ||
          u.name.toLowerCase().contains(trimmed),
      orElse: () => _demoUsers.first,
    );
    _current = matched;
    return SignInResult(user: matched, consentAccepted: _consentAccepted);
  }

  @override
  Future<SignInResult?> restoreSession() async => null;

  @override
  Future<void> requestAccess(AccessRequest request) async {}

  @override
  Future<void> acceptConsent() async {
    _consentAccepted = true;
  }

  @override
  Future<AppUser?> fetchCurrentUser() async => _current;

  @override
  Future<void> signOut() async {
    _current = null;
  }
}

class InMemoryNodeRepository implements NodeRepository {
  @override
  Future<NodeStatus> fetchStatus(String nodeId) async {
    return NodeStatus(
      nodeId: nodeId,
      waterStage: 2,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
      waterLevelPercent: 68.0,
      rainPercent: 45.0,
      powerSource: PowerSource.mains,
    );
  }

  @override
  Stream<NodeStatus> watchStatus(String nodeId) async* {
    yield await fetchStatus(nodeId);
  }
}

class InMemoryAlertRepository implements AlertRepository {
  DrainageAlert? _active = DrainageAlert(
    id: 'alert-101',
    nodeId: 'node-1',
    stage: 2,
    status: AlertStatus.open,
    escalationLevel: 1,
    timerDeadline: DateTime.now().add(const Duration(minutes: 12)),
    timeline: [
      TimelineEntry(
        label: 'Stage 2 clog threshold exceeded',
        at: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      TimelineEntry(
        label: 'Level 1 maintenance notified',
        at: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ],
  );

  final List<DrainageAlert> _history = [
    DrainageAlert(
      id: 'alert-100',
      nodeId: 'node-1',
      stage: 1,
      status: AlertStatus.cleared,
      escalationLevel: 1,
      acknowledgedBy: UserStamp(
        userId: 'u-1',
        at: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
      clearedBy: UserStamp(
        userId: 'u-1',
        at: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      ),
      creditedResponders: const [
        CreditedResponder(
          userId: 'u-1',
          role: UserRole.level1,
          contribution: Contribution.primaryResponder,
        ),
      ],
    ),
  ];

  final _controller = StreamController<DrainageAlert?>.broadcast();

  void _emit() => _controller.add(_active);

  @override
  Stream<DrainageAlert?> watchActiveAlert() async* {
    yield _active;
    yield* _controller.stream;
  }

  @override
  Future<DrainageAlert> fetchAlert(String alertId) async {
    if (_active?.id == alertId) return _active!;
    return _history.firstWhere((a) => a.id == alertId);
  }

  @override
  Future<List<DrainageAlert>> fetchHistory({
    int limit = 20,
    DateTime? before,
  }) async {
    return _history;
  }

  @override
  Future<DrainageAlert> acknowledge(String alertId) async {
    final current = _active!;
    _active = DrainageAlert(
      id: current.id,
      nodeId: current.nodeId,
      stage: current.stage,
      status: AlertStatus.inProgress,
      escalationLevel: current.escalationLevel,
      acknowledgedBy: UserStamp(userId: 'u-1', at: DateTime.now()),
      creditedResponders: [
        ...current.creditedResponders,
        const CreditedResponder(
          userId: 'u-1',
          role: UserRole.level1,
          contribution: Contribution.primaryResponder,
        ),
      ],
      remarks: current.remarks,
      timeline: [
        ...current.timeline,
        TimelineEntry(
          label: 'Acknowledged by responder',
          at: DateTime.now(),
          actorId: 'u-1',
        ),
      ],
    );
    _emit();
    return _active!;
  }

  @override
  Future<DrainageAlert> addRemark(String alertId, String text) async {
    final current = _active!;
    _active = DrainageAlert(
      id: current.id,
      nodeId: current.nodeId,
      stage: current.stage,
      status: current.status,
      escalationLevel: current.escalationLevel,
      timerDeadline: current.timerDeadline,
      acknowledgedBy: current.acknowledgedBy,
      clearedBy: current.clearedBy,
      creditedResponders: current.creditedResponders,
      remarks: [
        ...current.remarks,
        AlertRemark(authorId: 'u-1', text: text, at: DateTime.now()),
      ],
      timeline: [
        ...current.timeline,
        TimelineEntry(
          label: 'Remark posted: $text',
          at: DateTime.now(),
          actorId: 'u-1',
        ),
      ],
    );
    _emit();
    return _active!;
  }

  @override
  Future<DrainageAlert> markCleared(String alertId) async {
    final current = _active!;
    final cleared = DrainageAlert(
      id: current.id,
      nodeId: current.nodeId,
      stage: current.stage,
      status: AlertStatus.cleared,
      escalationLevel: current.escalationLevel,
      acknowledgedBy: current.acknowledgedBy,
      clearedBy: UserStamp(userId: 'u-1', at: DateTime.now()),
      creditedResponders: current.creditedResponders,
      remarks: current.remarks,
      timeline: [
        ...current.timeline,
        TimelineEntry(
          label: 'Marked cleared',
          at: DateTime.now(),
          actorId: 'u-1',
        ),
      ],
    );
    _history.insert(0, cleared);
    _active = null;
    _emit();
    return cleared;
  }

  @override
  Future<DrainageAlert> reassign(String alertId, String assigneeId) async {
    final current = _active!;
    _active = DrainageAlert(
      id: current.id,
      nodeId: current.nodeId,
      stage: current.stage,
      status: current.status,
      escalationLevel: current.escalationLevel,
      timerDeadline: current.timerDeadline,
      acknowledgedBy: current.acknowledgedBy,
      creditedResponders: [
        ...current.creditedResponders,
        CreditedResponder(
          userId: assigneeId,
          role: UserRole.level1,
          contribution: Contribution.supervisorAssigned,
        ),
      ],
      remarks: current.remarks,
      timeline: [
        ...current.timeline,
        TimelineEntry(
          label: 'Reassigned to responder',
          at: DateTime.now(),
          actorId: assigneeId,
        ),
      ],
    );
    _emit();
    return _active!;
  }

  @override
  Future<DrainageAlert> addCoResponders(
    String alertId,
    List<String> userIds,
  ) async {
    final current = _active!;
    _active = DrainageAlert(
      id: current.id,
      nodeId: current.nodeId,
      stage: current.stage,
      status: current.status,
      escalationLevel: current.escalationLevel,
      timerDeadline: current.timerDeadline,
      acknowledgedBy: current.acknowledgedBy,
      creditedResponders: [
        ...current.creditedResponders,
        for (final id in userIds)
          CreditedResponder(
            userId: id,
            role: UserRole.level1,
            contribution: Contribution.coResponder,
          ),
      ],
      remarks: current.remarks,
      timeline: current.timeline,
    );
    _emit();
    return _active!;
  }

  @override
  Future<DrainageAlert> setCreditedResponders(
    String alertId,
    List<CreditedResponder> responders,
  ) async {
    final current = _active!;
    _active = DrainageAlert(
      id: current.id,
      nodeId: current.nodeId,
      stage: current.stage,
      status: current.status,
      escalationLevel: current.escalationLevel,
      timerDeadline: current.timerDeadline,
      acknowledgedBy: current.acknowledgedBy,
      creditedResponders: responders,
      remarks: current.remarks,
      timeline: current.timeline,
    );
    _emit();
    return _active!;
  }
}

typedef PersonLookupMap = Map<String, PersonSummary>;

class InMemoryUserRepository implements UserRepository {
  final List<AppUser> _active = [
    AppUser(
      id: 'u-1',
      name: 'Juan Dela Cruz',
      role: UserRole.level1,
      status: AccountStatus.active,
      phone: '09170000001',
      serviceSpans: [ServiceSpan(start: DateTime(2026, 1, 10))],
    ),
    AppUser(
      id: 'u-2',
      name: 'Maria Santos',
      role: UserRole.level2,
      status: AccountStatus.active,
      phone: '09170000002',
      serviceSpans: [ServiceSpan(start: DateTime(2026, 1, 10))],
    ),
    AppUser(
      id: 'u-3',
      name: 'Kap. Roberto Reyes',
      role: UserRole.level3,
      status: AccountStatus.active,
      phone: '09170000003',
      serviceSpans: [ServiceSpan(start: DateTime(2026, 1, 10))],
    ),
  ];

  final List<AppUser> _pending = [
    const AppUser(
      id: 'u-pending-1',
      name: 'Pedro Penduko',
      role: UserRole.level1,
      status: AccountStatus.pending,
      phone: '09179998888',
    ),
  ];

  final List<AppUser> _archived = [];

  @override
  Future<PersonLookupMap> lookup(Iterable<String> userIds) async {
    final all = [..._active, ..._archived];
    return {
      for (final u in all)
        if (userIds.contains(u.id))
          u.id: PersonSummary(id: u.id, name: u.name, role: u.role),
    };
  }

  @override
  Future<List<PersonSummary>> fetchResponders({Set<UserRole>? roles}) async {
    return _active
        .where(
          (u) =>
              u.role.isFieldRole && (roles == null || roles.contains(u.role)),
        )
        .map((u) => PersonSummary(id: u.id, name: u.name, role: u.role))
        .toList();
  }

  @override
  Future<List<AppUser>> fetchPending() async => List.of(_pending);

  @override
  Future<AppUser> approve({
    required String userId,
    required UserRole role,
    required String verifiedName,
    required String verifiedPhone,
  }) async {
    final idx = _pending.indexWhere((u) => u.id == userId);
    final approved = _pending
        .removeAt(idx)
        .approve(
          assignedRole: role,
          verifiedName: verifiedName,
          verifiedPhone: verifiedPhone,
          at: DateTime.now(),
        );
    _active.add(approved);
    return approved;
  }

  @override
  Future<void> reject(String userId) async {
    _pending.removeWhere((u) => u.id == userId);
  }

  @override
  Future<List<AppUser>> fetchActive({String? query, UserRole? role}) async {
    return _active.where((u) {
      final matchesRole = role == null || u.role == role;
      final matchesQuery =
          query == null ||
          query.isEmpty ||
          u.name.toLowerCase().contains(query.toLowerCase()) ||
          (u.phone?.contains(query) ?? false);
      return matchesRole && matchesQuery;
    }).toList();
  }

  @override
  Future<AppUser> update({
    required String userId,
    String? name,
    String? phone,
    UserRole? role,
  }) async {
    final idx = _active.indexWhere((u) => u.id == userId);
    final old = _active[idx];
    final updated = AppUser(
      id: old.id,
      name: name ?? old.name,
      role: role ?? old.role,
      status: old.status,
      phone: phone ?? old.phone,
      serviceSpans: old.serviceSpans,
    );
    _active[idx] = updated;
    return updated;
  }

  @override
  Future<AppUser> archive(String userId) async {
    final idx = _active.indexWhere((u) => u.id == userId);
    final archived = _active.removeAt(idx).archive(DateTime.now());
    _archived.add(archived);
    return archived;
  }

  @override
  Future<List<AppUser>> fetchArchived() async => List.of(_archived);

  @override
  Future<AppUser> restore({
    required String userId,
    required String verifiedPhone,
    UserRole? newRole,
  }) async {
    final idx = _archived.indexWhere((u) => u.id == userId);
    final restored = _archived
        .removeAt(idx)
        .restore(
          verifiedPhone: verifiedPhone,
          at: DateTime.now(),
          newRole: newRole,
        );
    _active.add(restored);
    return restored;
  }
}

class InMemoryConfigRepository implements ConfigRepository {
  SystemConfig _config = const SystemConfig();
  final _controller = StreamController<SystemConfig>.broadcast();

  @override
  Future<SystemConfig> fetch() async => _config;

  @override
  Stream<SystemConfig> watch() async* {
    yield _config;
    yield* _controller.stream;
  }

  @override
  Future<SystemConfig> update(SystemConfig config) async {
    _config = config;
    _controller.add(_config);
    return _config;
  }

  @override
  Future<List<TimelineEntry>> fetchAuditLog({
    int limit = 50,
    DateTime? before,
  }) async {
    return [
      TimelineEntry(
        label: 'System initialized with default 15m escalation timeout',
        at: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }
}

class InMemoryNotificationService implements NotificationService {
  NotificationSettings _settings = const NotificationSettings();

  @override
  Future<NotificationSettings> loadSettings() async => _settings;

  @override
  Future<NotificationSettings> saveSettings(
    NotificationSettings settings,
  ) async {
    _settings = settings;
    return _settings;
  }

  @override
  Future<NotificationHealth> checkHealth() async {
    return NotificationHealth(
      permission: NotificationPermission.enabled,
      deviceRegistered: true,
      lastDeliveredAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> openSystemSettings() async {}
}
