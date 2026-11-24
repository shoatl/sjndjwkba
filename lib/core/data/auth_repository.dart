// lib/core/data/auth_repository.dart
//
// The contract between the app and your backend for accounts.
// This file has no real or fake data. Screens depend on this interface only,
// so you can plug in your own implementation (REST, Firebase Auth, etc.)
// without touching any UI.
//
// The server decides everything: whether credentials are valid, whether the
// account is pending or archived, and whether consent was accepted.

import '../models/drainage_models.dart';

/// What the server returns after a successful sign in.
class SignInResult {
  const SignInResult({required this.user, required this.consentAccepted});

  final AppUser user;

  /// False for a newly approved account, and again after a restore.
  final bool consentAccepted;
}

/// What the person submits on the Request Access form.
/// No role is chosen here. The Admin assigns it on approval.
class AccessRequest {
  const AccessRequest({
    required this.name,
    required this.phone,
    required this.password,
  });

  final String name;
  final String phone;
  final String password;
}

/// Reasons an account call can fail. The UI maps these to friendly text.
enum AuthFailure {
  invalidCredentials,
  accountArchived, // Blocked from login until an Admin restores it
  phoneAlreadyRequested, // A request or account already uses this number
  network,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure, [this.message]);

  final AuthFailure failure;

  /// Optional detail from the server, for logs. Do not show raw to people.
  final String? message;

  @override
  String toString() => 'AuthException($failure${message == null ? '' : ': $message'})';
}

abstract class AuthRepository {
  /// Check credentials. Throws [AuthException] on failure.
  /// [loginId] is whatever your backend uses to identify a person
  /// (phone number or username). The screen only passes through what was typed.
  Future<SignInResult> signIn({
    required String loginId,
    required String password,
  });

  /// Called on app start. Returns the saved session, or null if signed out.
  Future<SignInResult?> restoreSession();

  /// Submit a Request Access form. The account starts as Pending.
  /// Throws [AuthException] on failure.
  Future<void> requestAccess(AccessRequest request);

  /// Record the Data Privacy Act consent (RA 10173) for the signed-in user.
  /// The account stays unusable until this succeeds.
  Future<void> acceptConsent();

  /// Latest copy of the signed-in user, for example to check whether a
  /// Pending account has been approved. Null if signed out.
  Future<AppUser?> fetchCurrentUser();

  /// End the session and remove this device's push token on the server.
  Future<void> signOut();
}
