import 'dart:math';

/// Generates a short, locally-unique ID — good enough for a single-device
/// local database (no cross-device sync, so no collision risk across users).
String generateId() {
  final rand = Random();
  final ts = DateTime.now().microsecondsSinceEpoch;
  final rnd = rand.nextInt(0xFFFFFF);
  return '${ts.toRadixString(36)}${rnd.toRadixString(36)}';
}
