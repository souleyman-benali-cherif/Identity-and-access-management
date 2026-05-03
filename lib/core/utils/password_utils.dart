import 'package:flutter/foundation.dart';
import '../../models/person_model.dart';
import '../../models/password_policy_model.dart';
import 'package:bcrypt/bcrypt.dart';

/// Password strength levels shown in the UI.
enum PasswordStrength { weak, medium, strong }

/// Utility class for all password operations — hashing, verification, validation.
/// bcrypt operations run in a compute isolate to avoid blocking the UI thread.
class PasswordUtils {
  PasswordUtils._();

  // ─── Hashing ───────────────────────────────────────────────────────────────

  /// Hashes a plain-text password with bcrypt cost factor 12 in an isolate.
  static Future<String> hashPassword(String plain) async {
    return compute(_bcryptHash, plain);
  }

  /// Verifies a plain-text password against a bcrypt hash in an isolate.
  static Future<bool> verifyPassword(String plain, String hash) async {
    debugPrint('[PasswordUtils.verifyPassword] Verifying password of length ${plain.length} against hash: $hash');
    return compute(_bcryptVerify, _VerifyArgs(plain, hash));
  }

  // ─── Isolate helpers (top-level or static for compute()) ──────────────────

  /// Runs bcrypt hash synchronously inside compute isolate.
  static String _bcryptHash(String plain) {
    final salt = BCrypt.gensalt(logRounds: 12);
    return BCrypt.hashpw(plain, salt);
  }

  /// Runs bcrypt verify synchronously inside compute isolate.
  static bool _bcryptVerify(_VerifyArgs args) {
    try {
      return BCrypt.checkpw(args.plain, args.hash);
    } catch (_) {
      return false;
    }
  }

  // ─── Strength ──────────────────────────────────────────────────────────────

  /// Returns the number of complexity categories satisfied (0–4).
  static int categoriesSatisfied(String password) {
    int count = 0;
    if (password.contains(RegExp(r'[A-Z]'))) count++;
    if (password.contains(RegExp(r'[a-z]'))) count++;
    if (password.contains(RegExp(r'[0-9]'))) count++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) count++;
    return count;
  }

  /// Returns the visual strength label based on category count.
  static PasswordStrength checkStrength(String password) {
    final cats = categoriesSatisfied(password);
    if (cats < 2) return PasswordStrength.weak;
    if (cats == 2) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  // ─── Policy Validation ─────────────────────────────────────────────────────

  /// Returns null if the password passes policy; otherwise returns error message.
  /// ALWAYS reads limits from the provided [policy] — never uses hardcoded values.
  static String? validateAgainstPolicy(String password, PasswordPolicyModel policy) {
    if (password.length < policy.minLength) {
      return 'Password must be at least ${policy.minLength} characters.';
    }
    if (password.length > policy.maxLength) {
      return 'Password must not exceed ${policy.maxLength} characters.';
    }
    final cats = categoriesSatisfied(password);
    if (cats < policy.minCategories) {
      return 'Password must contain at least ${policy.minCategories} '
          'of: uppercase, lowercase, digit, special character (!@#\$%^&*).';
    }
    return null;
  }

  // ─── Personal Info Check ───────────────────────────────────────────────────

  /// Returns true if the password contains any personal information.
  /// Checks first name, last name, uniqueId, and DOB in multiple formats.
  static bool containsPersonalInfo(String password, PersonModel person) {
    final lower = password.toLowerCase();
    if (lower.contains(person.firstName.toLowerCase())) return true;
    if (lower.contains(person.lastName.toLowerCase())) return true;
    if (lower.contains(person.uniqueId.toLowerCase())) return true;

    // Check DOB in YYYY-MM-DD and DD/MM/YYYY formats.
    try {
      final dob = DateTime.parse(person.dateOfBirth);
      final y = dob.year.toString();
      final m = dob.month.toString().padLeft(2, '0');
      final d = dob.day.toString().padLeft(2, '0');
      if (lower.contains('$y-$m-$d')) return true;
      if (lower.contains('$d/$m/$y')) return true;
      if (lower.contains('$d$m$y')) return true;
    } catch (_) {}
    return false;
  }

  // ─── Password History ──────────────────────────────────────────────────────

  /// Returns true if the new plain-text password matches any stored hash.
  /// Runs each bcrypt check in an isolate to avoid blocking.
  static Future<bool> isInHistory(String plain, List<String> hashes) async {
    for (final hash in hashes) {
      if (await verifyPassword(plain, hash)) return true;
    }
    return false;
  }
}

/// Helper class for passing two arguments through compute().
class _VerifyArgs {
  final String plain;
  final String hash;
  const _VerifyArgs(this.plain, this.hash);
}
