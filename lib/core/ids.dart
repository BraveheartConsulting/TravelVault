import 'dart:math';

final Random _random = Random.secure();

/// Generates a 128-bit random identifier as a 32-character hex string. Used
/// for primary keys — no central sequence, no coordination, collision-safe in
/// practice for an on-device single-user database.
String newId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  return bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}
