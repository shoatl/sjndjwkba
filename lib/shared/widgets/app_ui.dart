// lib/shared/widgets/app_ui.dart
//
// Small shared UI helpers used by the feature screens: a status pill, a
// person avatar, friendly error text, the text field style, button styles,
// and a toast. No business logic and no color literals.

import 'package:flutter/material.dart';

import '../../core/data/alert_repository.dart';
import '../../core/data/config_repository.dart';
import '../../core/data/user_repository.dart';
import '../../core/models/drainage_models.dart';
import '../../core/theme/app_theme.dart';

// ---- Text for models -------------------------------------------------------

extension UserRoleText on UserRole {
  /// Short badge text: L1, L2, L3, ADMIN.
  String get shortLabel {
    switch (this) {
      case UserRole.level1:
        return 'L1';
      case UserRole.level2:
        return 'L2';
      case UserRole.level3:
        return 'L3';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  /// Plain role name without the level number.
  String get plainLabel {
    switch (this) {
      case UserRole.level1:
        return 'Maintenance';
      case UserRole.level2:
        return 'Barangay official';
      case UserRole.level3:
        return 'Barangay captain';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

extension AlertStatusText on AlertStatus {
  String get label {
    switch (this) {
      case AlertStatus.open:
        return 'Open';
      case AlertStatus.inProgress:
        return 'In progress';
      case AlertStatus.pendingConfirmation:
        return 'Pending confirmation';
      case AlertStatus.critical:
        return 'Critical, unacknowledged';
      case AlertStatus.cleared:
        return 'Cleared';
      case AlertStatus.reopened:
        return 'Reopened';
    }
  }
}

/// Color for an alert's status pill. Words always accompany it.
Color alertColor(BuildContext context, DrainageAlert alert) {
  if (alert.status == AlertStatus.cleared) return context.status.normal;
  if (alert.status == AlertStatus.critical) return context.status.stage3;
  return context.status.forStage(alert.stage);
}

String stageText(int stage) => stage <= 0 ? 'Normal' : 'Stage $stage';

/// Name for a user id, or a neutral fallback when the server did not know it.
String nameOf(Map<String, PersonSummary> names, String id) =>
    names[id]?.name ?? 'Unknown person';

// ---- Errors ----------------------------------------------------------------

String alertFailureText(AlertFailure failure) {
  switch (failure) {
    case AlertFailure.alreadyAcknowledged:
      return 'Someone else already acknowledged this alert.';
    case AlertFailure.alreadyCleared:
      return 'This alert is already cleared.';
    case AlertFailure.notAllowed:
      return 'Your account cannot do this action.';
    case AlertFailure.notFound:
      return 'This alert is no longer open.';
    case AlertFailure.network:
      return 'No connection. Check your internet and try again.';
    case AlertFailure.unknown:
      return 'Something went wrong. Please try again.';
  }
}

String userFailureText(UserFailure failure) {
  switch (failure) {
    case UserFailure.notAllowed:
      return 'Your account cannot do this action.';
    case UserFailure.notFound:
      return 'This person could not be found.';
    case UserFailure.invalidValue:
      return 'Please check the details and try again.';
    case UserFailure.phoneInUse:
      return 'Another account already uses this phone number.';
    case UserFailure.network:
      return 'No connection. Check your internet and try again.';
    case UserFailure.unknown:
      return 'Something went wrong. Please try again.';
  }
}

String configFailureText(ConfigFailure failure) {
  switch (failure) {
    case ConfigFailure.notAllowed:
      return 'Only an Admin can change these settings.';
    case ConfigFailure.invalidValue:
      return 'Each time must be greater than zero.';
    case ConfigFailure.network:
      return 'No connection. Check your internet and try again.';
    case ConfigFailure.unknown:
      return 'Something went wrong. Please try again.';
  }
}

/// One friendly sentence for any error thrown by a repository.
String errorText(Object error) {
  if (error is AlertException) return alertFailureText(error.failure);
  if (error is UserException) return userFailureText(error.failure);
  if (error is ConfigException) return configFailureText(error.failure);
  return 'Something went wrong. Please try again.';
}

// ---- Small widgets ---------------------------------------------------------

/// A small rounded badge: colored dot (or icon) plus words.
class AppPill extends StatelessWidget {
  const AppPill({super.key, required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final tint = color ?? scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withAlpha(32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withAlpha(110)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: tint)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round avatar with the person's first initial.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        initial,
        style: text.titleSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A label and value on one line, used in detail cards.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline error shown inside a sheet or form.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: text.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spinner sized to sit inside a button.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.onFilled = true});

  /// True on a filled button (white spinner), false on an outlined one.
  final bool onFilled;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: onFilled ? scheme.onPrimary : scheme.primary,
      ),
    );
  }
}

// ---- Styles and helpers ----------------------------------------------------

InputDecoration appInputDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
  String? hint,
}) {
  final scheme = context.colors;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: scheme.outline.withAlpha(140)),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: scheme.surfaceContainerHighest.withAlpha(120),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: scheme.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  );
}

ButtonStyle bigFilledStyle() => FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

ButtonStyle bigOutlinedStyle() => OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

void showAppToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Loose phone check: optional +, then 10 to 13 digits. Spaces and dashes are
/// ignored. The server does the real validation.
bool looksLikePhone(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
  return RegExp(r'^\+?[0-9]{10,13}$').hasMatch(cleaned);
}
