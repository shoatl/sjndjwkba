// lib/core/utils/time_format.dart
//
// Small text helpers for times and durations. Plain Dart, no packages.
// Pass `now` in (instead of calling DateTime.now here) so results are easy
// to test and the screen controls what "now" is.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Countdown text: `11:42`, or `1:05:00` when an hour or more is left.
/// Negative durations show `00:00`.
String formatCountdown(Duration remaining) {
  final total = remaining.isNegative ? 0 : remaining.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

/// How long ago something happened: `just now`, `5 min ago`, `2 h ago`,
/// `3 days ago`. A time slightly in the future (phone clock drift) counts
/// as `just now`.
String agoText(DateTime then, DateTime now) {
  final d = now.difference(then);
  if (d.inSeconds < 45) return 'just now';
  if (d.inMinutes < 60) {
    final m = d.inMinutes < 1 ? 1 : d.inMinutes;
    return '$m min ago';
  }
  if (d.inHours < 24) return '${d.inHours} h ago';
  final days = d.inDays;
  return days == 1 ? '1 day ago' : '$days days ago';
}

/// For the node's "last seen" line. A node that never reported says so.
String lastSeenText(DateTime? lastSeen, DateTime now) {
  if (lastSeen == null) return 'Never reported';
  return 'Last seen ${agoText(lastSeen, now)}';
}

/// `3:42 PM`, in the phone's local time.
String formatClock(DateTime at) {
  final t = at.toLocal();
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final suffix = t.hour < 12 ? 'AM' : 'PM';
  return '$h12:${_two(t.minute)} $suffix';
}

/// `Nov 24, 2026`, in the phone's local time.
String formatDate(DateTime at) {
  final t = at.toLocal();
  return '${_months[t.month - 1]} ${t.day}, ${t.year}';
}

/// `Nov 24, 2026, 3:42 PM`.
String formatDateTime(DateTime at) => '${formatDate(at)}, ${formatClock(at)}';

/// A span of time for response metrics: `under 1 min`, `12 min`,
/// `1 h 5 min`, `2 h`, `1 d 3 h`.
String formatDuration(Duration d) {
  if (d.isNegative || d.inSeconds < 60) return 'under 1 min';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
  }
  final h = d.inHours % 24;
  return h == 0 ? '${d.inDays} d' : '${d.inDays} d $h h';
}
