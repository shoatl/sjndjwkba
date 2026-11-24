// lib/core/auth/session.dart
//
// Holds who is signed in and decides which area of the app they may see.
// This is for usability only. The server enforces every permission.
//
// The backend (later) tells us the user and whether they have already
// accepted the consent screen. This file never talks to a server.

import 'package:flutter/foundation.dart';

import '../models/drainage_models.dart';

/// Where the app should send the person right now.
enum AuthDestination {
  login, // Nobody signed in, or the account is archived
  pendingApproval, // Requested access, not yet approved
  consent, // Approved, but has not accepted the privacy consent
  fieldHome, // Level 1 to 3: Home, History, Profile
  adminHome; // Admin: Approvals, Directory, Config, Profile
}

class Session extends ChangeNotifier {
  AppUser? _user;
  bool _consentAccepted = false;

  /// The signed-in person, or null when signed out.
  AppUser? get user => _user;

  bool get isSignedIn => _user != null;

  UserRole? get role => _user?.role;

  bool get consentAccepted => _consentAccepted;

  /// True only for an active account that accepted consent.
  /// Telemetry, alerts, and the personnel directory require this.
  bool get canUseApp =>
      _user != null && _user!.status.canUseApp && _consentAccepted;

  /// The single place that answers "which screen now?".
  AuthDestination get destination {
    final u = _user;
    if (u == null) return AuthDestination.login;

    switch (u.status) {
      case AccountStatus.archived:
        return AuthDestination.login;
      case AccountStatus.pending:
        return AuthDestination.pendingApproval;
      case AccountStatus.active:
        if (!_consentAccepted) return AuthDestination.consent;
        return u.role.isFieldRole
            ? AuthDestination.fieldHome
            : AuthDestination.adminHome;
    }
  }

  /// Call after the server accepts the credentials.
  ///
  /// Returns false and keeps the person signed out if the account is
  /// archived. Archived accounts cannot log in.
  bool signIn(AppUser user, {required bool consentAccepted}) {
    if (user.status == AccountStatus.archived) {
      _clear();
      notifyListeners();
      return false;
    }
    _user = user;
    _consentAccepted = consentAccepted;
    notifyListeners();
    return true;
  }

  /// Call when the person taps Accept on the consent screen.
  /// The account stays unusable until this fires.
  void acceptConsent() {
    if (_user == null) return;
    _consentAccepted = true;
    notifyListeners();
  }

  /// Replace the user with a fresher copy from the server, for example when
  /// a pending account gets approved while the app is open, or the role
  /// changes. An archived update signs the person out.
  void refreshUser(AppUser updated) {
    if (_user == null) return;
    if (updated.status == AccountStatus.archived) {
      signOut();
      return;
    }
    _user = updated;
    notifyListeners();
  }

  void signOut() {
    _clear();
    notifyListeners();
  }

  void _clear() {
    _user = null;
    _consentAccepted = false;
  }
}
