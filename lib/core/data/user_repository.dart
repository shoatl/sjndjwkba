// lib/core/data/user_repository.dart
//
// The contract for people: name lookups, the responder picker, and the
// Admin's account management. Interface only: no real or fake data.
//
// The server enforces every permission. Only an Admin may call the
// "Admin only" methods, and the server refuses everyone else.
//
// Privacy: [PersonSummary] has no phone number on purpose. Use it anywhere
// a name is shown to field staff (co-responder picker, Reassign, Acknowledged
// by). Only the Admin directory uses [AppUser], which includes the phone.

import 'dart:async';

import '../models/drainage_models.dart';

/// A person as other staff may see them: name and role only. No phone.
class PersonSummary {
  const PersonSummary({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final UserRole role;
}

/// Reasons a user call can fail.
enum UserFailure {
  notAllowed, // Not an Admin, or not permitted for this role
  notFound,
  invalidValue, // For example a malformed phone number
  phoneInUse, // Another account already uses this number
  network,
  unknown,
}

class UserException implements Exception {
  const UserException(this.failure, [this.message]);

  final UserFailure failure;
  final String? message;

  @override
  String toString() =>
      'UserException($failure${message == null ? '' : ': $message'})';
}

abstract class UserRepository {
  // ---- Names only (all signed-in field roles) ------------------------------

  /// Turn user IDs into names, for "Acknowledged by", remarks, and credits.
  /// Archived people are included, because their name and role are kept.
  /// IDs the server does not know are simply missing from the result.
  Future<Map<String, PersonSummary>> lookup(Iterable<String> userIds);

  /// Active Level 1 to 3 people for the co-responder picker and Reassign.
  /// Pass [roles] to narrow, for example Level 1 and Level 2 for Reassign.
  /// Names only, never phone numbers.
  Future<List<PersonSummary>> fetchResponders({Set<UserRole>? roles});

  // ---- Admin only ----------------------------------------------------------

  /// The Pending Approval queue, oldest request first.
  Future<List<AppUser>> fetchPending();

  /// Approve a pending account. The Admin supplies the verified name,
  /// phone number, and role. Opens the first service span.
  Future<AppUser> approve({
    required String userId,
    required UserRole role,
    required String verifiedName,
    required String verifiedPhone,
  });

  /// Reject a pending request.
  /// Still open: what happens to the stored name and number afterward.
  /// The suggestion is to delete them.
  Future<void> reject(String userId);

  /// Active Personnel Directory. [query] matches name or phone. [role]
  /// filters by role.
  Future<List<AppUser>> fetchActive({String? query, UserRole? role});

  /// Edit an active person. Correct phone numbers matter, because they are
  /// used for the SMS fallback. Leave a field null to keep it unchanged.
  Future<AppUser> update({
    required String userId,
    String? name,
    String? phone,
    UserRole? role,
  });

  /// Archive departing staff. The server removes the phone number,
  /// credentials, push tokens, and notification settings, keeps only name,
  /// role and service dates, and closes the open service span.
  Future<AppUser> archive(String userId);

  /// Archived Users Vault: name, role, and service dates only.
  Future<List<AppUser>> fetchArchived();

  /// Restore an archived account. Needs a newly verified phone number.
  /// The person must also set new credentials and accept consent again.
  Future<AppUser> restore({
    required String userId,
    required String verifiedPhone,
    UserRole? newRole,
  });
}
