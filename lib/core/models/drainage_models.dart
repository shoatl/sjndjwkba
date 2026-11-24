import 'dart:async';
import 'package:flutter/material.dart';

enum UserRole { level1, level2, level3, admin }
enum AccountStatus { pending, active, archived }
enum AlertStatus { open, inProgress, pendingConfirmation, critical, cleared, reopened }
enum Contribution { acknowledgement, markingCleared, remark, reassignment, coResponder }

extension UserRoleDetails on UserRole {
  String get label {
    switch (this) {
      case UserRole.level1: return 'Level 1 - Maintenance';
      case UserRole.level2: return 'Level 2 - Official';
      case UserRole.level3: return 'Level 3 - Captain';
      case UserRole.admin: return 'Admin';
    }
  }
  String get plainLabel => label;
  bool get isFieldRole => this != UserRole.admin;
  bool get receivesSmsFallback => this == UserRole.level2 || this == UserRole.level3;
  bool get seesAllHistory => this != UserRole.level1;
  bool get canRespond => isFieldRole;
  bool get canReassign => this == UserRole.level2 || this == UserRole.level3;
  bool get canManageCredits => this == UserRole.level2 || this == UserRole.level3 || this == UserRole.admin;
  bool get canManageUsers => this == UserRole.admin;
}

extension AccountStatusDetails on AccountStatus {
  bool get canUseApp => this == AccountStatus.active;
}

extension AlertStatusDetails on AlertStatus {
  bool get isActive => this != AlertStatus.cleared;
  String get label {
    switch (this) {
      case AlertStatus.open: return 'Open';
      case AlertStatus.inProgress: return 'In progress';
      case AlertStatus.pendingConfirmation: return 'Pending confirmation';
      case AlertStatus.critical: return 'Critical, unacknowledged';
      case AlertStatus.cleared: return 'Cleared';
      case AlertStatus.reopened: return 'Reopened';
    }
  }
}

extension ContributionDetails on Contribution {
  String get label {
    switch (this) {
      case Contribution.acknowledgement: return 'Acknowledged';
      case Contribution.markingCleared: return 'Marked cleared';
      case Contribution.remark: return 'Remark';
      case Contribution.reassignment: return 'Reassigned';
      case Contribution.coResponder: return 'Co-responder';
    }
  }
}

class ServiceSpan {
  const ServiceSpan({required this.start, this.end});
  final DateTime start;
  final DateTime? end;
}

class AppUser {
  const AppUser({required this.id, required this.name, required this.role, required this.status, this.phone, this.serviceSpans = const []});
  final String id;
  final String name;
  final String? phone;
  final UserRole role;
  final AccountStatus status;
  final List<ServiceSpan> serviceSpans;
}

class SystemConfig {
  const SystemConfig({this.escalationTimeout = const Duration(minutes: 5), this.staleAfter = const Duration(minutes: 10)});
  final Duration escalationTimeout;
  final Duration staleAfter;
}

class TimelineEntry {
  const TimelineEntry({required this.at, required this.label, this.actorId});
  final DateTime at;
  final String label;
  final String? actorId;
}

class AlertRemark {
  const AlertRemark({required this.authorId, required this.text, required this.at});
  final String authorId;
  final String text;
  final DateTime at;
}

class CreditedResponder {
  const CreditedResponder({required this.userId, required this.role, required this.contribution});
  final String userId;
  final UserRole role;
  final Contribution contribution;
}

class DrainageAlert {
  const DrainageAlert({required this.id, required this.nodeId, required this.stage, required this.status, required this.escalationLevel, this.acknowledgedBy, this.clearedBy, this.assignedTo, this.timerDeadline, this.timeline = const [], this.remarks = const [], this.creditedResponders = const []});
  final String id;
  final String nodeId;
  final int stage;
  final AlertStatus status;
  final int escalationLevel;
  final TimelineEntry? acknowledgedBy;
  final TimelineEntry? clearedBy;
  final String? assignedTo;
  final DateTime? timerDeadline;
  final List<TimelineEntry> timeline;
  final List<AlertRemark> remarks;
  final List<CreditedResponder> creditedResponders;

  bool get isAcknowledged => acknowledgedBy != null;
  Contribution? contributionOf(String userId) {
    for (final responder in creditedResponders) {
      if (responder.userId == userId) return responder.contribution;
    }
    return null;
  }

  DrainageAlert copyWith({AlertStatus? status, int? escalationLevel, TimelineEntry? acknowledgedBy, bool clearAcknowledgedBy = false, TimelineEntry? clearedBy, bool clearClearedBy = false, DateTime? timerDeadline, bool clearTimerDeadline = false, String? assignedTo, List<TimelineEntry>? timeline, List<AlertRemark>? remarks, List<CreditedResponder>? creditedResponders}) {
    return DrainageAlert(id: id, nodeId: nodeId, stage: stage, status: status ?? this.status, escalationLevel: escalationLevel ?? this.escalationLevel, acknowledgedBy: clearAcknowledgedBy ? null : acknowledgedBy ?? this.acknowledgedBy, clearedBy: clearClearedBy ? null : clearedBy ?? this.clearedBy, assignedTo: assignedTo ?? this.assignedTo, timerDeadline: clearTimerDeadline ? null : timerDeadline ?? this.timerDeadline, timeline: timeline ?? this.timeline, remarks: remarks ?? this.remarks, creditedResponders: creditedResponders ?? this.creditedResponders);
  }
}
