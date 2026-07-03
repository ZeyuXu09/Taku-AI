import 'package:intl/intl.dart';

class GameFormat {
  static String metaLine(DateTime gameAt) {
    final date = DateFormat('MMM d').format(gameAt);
    final time = DateFormat('h:mm a').format(gameAt);
    return '$date · $time';
  }

  static String shortDateTime(DateTime gameAt) {
    return DateFormat('EEE d, h:mm a').format(gameAt);
  }

  static String countdownLabel(DateTime gameAt) {
    final diff = gameAt.difference(DateTime.now());
    if (diff.isNegative) return 'In progress';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return 'Soon';
  }
}
