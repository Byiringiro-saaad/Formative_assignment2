import 'package:intl/intl.dart';

/// "2 hours ago", "1 day ago", ... for recent times, or a date for older ones.
String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return _plural(diff.inMinutes, 'minute');
  if (diff.inHours < 24) return _plural(diff.inHours, 'hour');
  if (diff.inDays < 7) return _plural(diff.inDays, 'day');
  return DateFormat('MMM d, yyyy').format(time);
}

String _plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'} ago';

/// "Oct 15, 2026 at 10:24 AM"
String fullDateTime(DateTime time) =>
    DateFormat("MMM d, yyyy 'at' h:mm a").format(time);

/// "Oct 15, 10:24 AM"
String shortDateTime(DateTime time) => DateFormat('MMM d, h:mm a').format(time);
