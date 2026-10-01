/// Small date-formatting helpers so we don't need to add the intl package
/// just for a couple of date strings.
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _time(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute $period';
}

/// e.g. "Sep 24" — used in the note list.
String formatShortDate(DateTime dt) {
  return '${_months[dt.month - 1]} ${dt.day}';
}

/// e.g. "Sep 24, 2026, 2:22 PM" — used in the editor header.
String formatFullDate(DateTime dt) {
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}, ${_time(dt)}';
}
