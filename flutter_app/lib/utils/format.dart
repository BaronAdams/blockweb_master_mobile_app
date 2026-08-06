/// Port of utils/analytics.ts's formatMinutes().
String formatMinutes(double minutes) {
  if (minutes < 1) return '${(minutes * 60).round()}s';
  if (minutes < 60) {
    final whole = minutes.floor();
    final seconds = ((minutes - whole) * 60).round();
    return seconds > 0 ? '${whole}m ${seconds}s' : '${whole}m';
  }
  final h = (minutes / 60).floor();
  final m = (minutes % 60).round();
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}
