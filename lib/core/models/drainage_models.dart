enum UserRole {
  level1,
  level2,
  level3,
  admin;

  String get label {
    switch (this) {
      case UserRole.level1:
        return 'Level 1, Maintenance';
      case UserRole.level2:
        return 'Level 2, Barangay official';
      case UserRole.level3:
        return 'Level 3, Barangay captain';
      case UserRole.admin:
        return 'Admin';
    }
  }

  bool get isFieldRole => this != UserRole.admin;
  bool get canRespond => isFieldRole;
  bool get canReassign => this == UserRole.level2 || this == UserRole.level3;
  bool get canManageCredits =>
      this == UserRole.level2 ||
      this == UserRole.level3 ||
      this == UserRole.admin;
  bool get canManageUsers => this == UserRole.admin;
  bool get seesAllHistory => this == UserRole.level2 || this == UserRole.level3;
  bool get receivesSmsFallback =>
      this == UserRole.level2 || this == UserRole.level3;
}

enum AccountStatus {
  pending,
  active,
  archived;

  bool get canUseApp => this == AccountStatus.active;
}

class ServiceSpan {
  const ServiceSpan({required this.start, this.end});

  final DateTime start;
  final DateTime? end;

  bool get isOpen => end == null;

  ServiceSpan closedAt(DateTime endDate) =>
      ServiceSpan(start: start, end: endDate);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.phone,
    this.serviceSpans = const [],
  });

  final String id;
  final String name;
  final UserRole role;
  final AccountStatus status;
  final String? phone;
  final List<ServiceSpan> serviceSpans;

  AppUser approve({
    required UserRole assignedRole,
    required String verifiedName,
    required String verifiedPhone,
    required DateTime at,
  }) {
    return AppUser(
      id: id,
      name: verifiedName,
      role: assignedRole,
      status: AccountStatus.active,
      phone: verifiedPhone,
      serviceSpans: [
        ...serviceSpans,
        ServiceSpan(start: at),
      ],
    );
  }

  AppUser archive(DateTime at) {
    final spans = [for (final s in serviceSpans) s.isOpen ? s.closedAt(at) : s];
    return AppUser(
      id: id,
      name: name,
      role: role,
      status: AccountStatus.archived,
      phone: null,
      serviceSpans: spans,
    );
  }

  AppUser restore({
    required String verifiedPhone,
    required DateTime at,
    UserRole? newRole,
  }) {
    return AppUser(
      id: id,
      name: name,
      role: newRole ?? role,
      status: AccountStatus.active,
      phone: verifiedPhone,
      serviceSpans: [
        ...serviceSpans,
        ServiceSpan(start: at),
      ],
    );
  }
}

enum AlertStatus {
  open,
  inProgress,
  pendingConfirmation,
  critical,
  cleared,
  reopened;

  bool get isActive => this != AlertStatus.cleared;
}

enum Contribution {
  primaryResponder,
  coResponder,
  remarkContributor,
  supervisorAssigned;

  String get label {
    switch (this) {
      case Contribution.primaryResponder:
        return 'Primary responder';
      case Contribution.coResponder:
        return 'Co-responder';
      case Contribution.remarkContributor:
        return 'Remark';
      case Contribution.supervisorAssigned:
        return 'Assigned';
    }
  }
}

class UserStamp {
  const UserStamp({required this.userId, required this.at});

  final String userId;
  final DateTime at;
}

class CreditedResponder {
  const CreditedResponder({
    required this.userId,
    required this.role,
    required this.contribution,
  });

  final String userId;
  final UserRole role;
  final Contribution contribution;
}

class AlertRemark {
  const AlertRemark({
    required this.authorId,
    required this.text,
    required this.at,
  });

  final String authorId;
  final String text;
  final DateTime at;
}

class TimelineEntry {
  const TimelineEntry({required this.label, required this.at, this.actorId});

  final String label;
  final DateTime at;
  final String? actorId;
}

class DrainageAlert {
  const DrainageAlert({
    required this.id,
    required this.nodeId,
    required this.stage,
    required this.status,
    required this.escalationLevel,
    this.timerDeadline,
    this.acknowledgedBy,
    this.clearedBy,
    this.creditedResponders = const [],
    this.remarks = const [],
    this.timeline = const [],
  });

  final String id;
  final String nodeId;
  final int stage;
  final AlertStatus status;
  final int escalationLevel;
  final DateTime? timerDeadline;
  final UserStamp? acknowledgedBy;
  final UserStamp? clearedBy;
  final List<CreditedResponder> creditedResponders;
  final List<AlertRemark> remarks;
  final List<TimelineEntry> timeline;

  bool get isAcknowledged => acknowledgedBy != null;

  bool isUserCredited(String userId) =>
      creditedResponders.any((c) => c.userId == userId);

  Contribution? contributionOf(String userId) {
    for (final c in creditedResponders) {
      if (c.userId == userId) return c.contribution;
    }
    return null;
  }
}

class SystemConfig {
  const SystemConfig({
    this.escalationTimeout = const Duration(minutes: 15),
    this.staleAfter = const Duration(minutes: 10),
  });

  final Duration escalationTimeout;
  final Duration staleAfter;
}
