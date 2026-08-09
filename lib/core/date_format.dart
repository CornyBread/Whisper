/// Compact timestamp for a chat list row: `14:32` today, `Ayer` yesterday,
/// a weekday within the last week, `12/03` beyond that.
String formatChatTimestamp(DateTime when) {
  final now = DateTime.now();
  final date = DateTime(when.year, when.month, when.day);
  final today = DateTime(now.year, now.month, now.day);
  final daysAgo = today.difference(date).inDays;

  if (daysAgo <= 0) {
    final hour = when.hour.toString().padLeft(2, '0');
    final minute = when.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (daysAgo == 1) return 'Ayer';
  if (daysAgo < 7) return _weekdays[when.weekday - 1];
  return '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}';
}

const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
