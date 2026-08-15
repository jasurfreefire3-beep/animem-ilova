import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Hozirgina';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} daqiqa oldin';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} soat oldin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} kun oldin';
      } else {
        return DateFormat('dd.MM.yyyy').format(date);
      }
    } catch (_) {
      return '';
    }
  }

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
