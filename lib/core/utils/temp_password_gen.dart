import 'dart:math';

/// Generates secure temporary passwords that satisfy all 4 complexity categories.
class TempPasswordGenerator {
  static const String _upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const String _lower   = 'abcdefghjkmnpqrstuvwxyz';
  static const String _digits  = '23456789';
  static const String _special = '!@#\$%^&*';

  /// Generates an 8-character temporary password containing at least one
  /// uppercase, one lowercase, one digit, and one special character.
  static String generate() {
    final rng = Random.secure();

    // Guarantee one character from each category.
    final chars = [
      _upper[rng.nextInt(_upper.length)],
      _lower[rng.nextInt(_lower.length)],
      _digits[rng.nextInt(_digits.length)],
      _special[rng.nextInt(_special.length)],
    ];

    // Fill remaining 4 characters from the full pool.
    const pool = _upper + _lower + _digits + _special;
    for (int i = 0; i < 4; i++) {
      chars.add(pool[rng.nextInt(pool.length)]);
    }

    // Shuffle to avoid predictable pattern (e.g. always upper first).
    chars.shuffle(rng);
    return chars.join();
  }
}
