import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:otp/otp.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/password_utils.dart';
import '../../models/auth_credentials_model.dart';
import '../../models/mfa_methods_model.dart';
import '../../models/session_model.dart';
import '../../models/otp_code_model.dart';
import '../../models/reset_token_model.dart';
import '../../models/password_policy_model.dart';
import '../../models/person_model.dart';

/// Service for all authentication operations.
/// This is the ONLY class that reads from/writes to auth-related SQL tables.
class AuthService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ──────────────────────────────────────────────────────────────────────────
  // PASSWORD POLICY
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads the password policy from the DB. Falls back to defaults if empty.
  /// NEVER hardcodes policy values — always reads from the database.
  Future<PasswordPolicyModel> getPasswordPolicy() async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tablePasswordPolicy,
          where: 'id = ?', whereArgs: ['policy'], limit: 1);
      if (rows.isEmpty) return const PasswordPolicyModel();
      return PasswordPolicyModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[AuthService.getPasswordPolicy] Error: $e');
      return const PasswordPolicyModel();
    }
  }

  /// Saves the password policy to the DB (IT Admin only).
  Future<void> savePasswordPolicy(PasswordPolicyModel policy) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tablePasswordPolicy, policy.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('[AuthService] Password policy updated.');
    } catch (e) {
      debugPrint('[AuthService.savePasswordPolicy] Error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CREDENTIALS
  // ──────────────────────────────────────────────────────────────────────────

  /// Retrieves auth credentials for a person, or null if not found.
  Future<AuthCredentialsModel?> getCredentials(String personId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableAuthCredentials,
          where: 'personId = ?', whereArgs: [personId], limit: 1);
      return rows.isEmpty ? null : AuthCredentialsModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[AuthService.getCredentials] Error: $e');
      return null;
    }
  }

  /// Saves initial auth credentials for a newly created person.
  Future<void> createCredentials(AuthCredentialsModel creds) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tableAuthCredentials, creds.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      // Initialize empty password history.
      await db.insert(AppConstants.tablePasswordHistory,
          {'personId': creds.personId, 'hashes': '[]'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      debugPrint('[AuthService.createCredentials] Error: $e');
      rethrow;
    }
  }

  /// Updates credentials in the DB.
  Future<void> updateCredentials(AuthCredentialsModel creds) async {
    try {
      final db = await _db.database;
      await db.update(AppConstants.tableAuthCredentials, creds.toMap(),
          where: 'personId = ?', whereArgs: [creds.personId]);
    } catch (e) {
      debugPrint('[AuthService.updateCredentials] Error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PASSWORD MANAGEMENT
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the list of last N password hashes for a person.
  Future<List<String>> getPasswordHistory(String personId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tablePasswordHistory,
          where: 'personId = ?', whereArgs: [personId], limit: 1);
      if (rows.isEmpty) return [];
      final raw = rows.first['hashes'] as String? ?? '[]';
      return (jsonDecode(raw) as List).cast<String>();
    } catch (e) {
      debugPrint('[AuthService.getPasswordHistory] Error: $e');
      return [];
    }
  }

  /// Adds a hash to the front of the password history, keeping only the last N.
  Future<void> addToPasswordHistory(
      String personId, String hash, int historyCount) async {
    try {
      final db = await _db.database;
      final history = await getPasswordHistory(personId);
      history.insert(0, hash);
      final trimmed = history.take(historyCount).toList();
      await db.insert(
        AppConstants.tablePasswordHistory,
        {'personId': personId, 'hashes': jsonEncode(trimmed)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[AuthService.addToPasswordHistory] Error: $e');
    }
  }

  /// Changes a person's password — hashes, saves, updates history, clears firstLogin.
  /// Returns null on success or an error string on validation failure.
  Future<String?> changePassword({
    required String personId,
    required String newPlain,
    required PersonModel person,
    required PasswordPolicyModel policy,
  }) async {
    try {
      // Validate against policy (reads from passed policy object — no hardcoding).
      final policyError = PasswordUtils.validateAgainstPolicy(newPlain, policy);
      if (policyError != null) return policyError;

      // Check personal info.
      if (PasswordUtils.containsPersonalInfo(newPlain, person)) {
        return 'Password cannot contain your personal information.';
      }

      // Check history.
      final history = await getPasswordHistory(personId);
      if (await PasswordUtils.isInHistory(newPlain, history)) {
        return 'You cannot reuse a recent password.';
      }

      // Hash new password in isolate.
      final newHash = await PasswordUtils.hashPassword(newPlain);
      final creds = await getCredentials(personId);
      if (creds == null) return 'Credentials not found.';

      // Store old hash in history before replacing.
      await addToPasswordHistory(
          personId, creds.hashedPassword, policy.historyCount);

      // Update credentials.
      await updateCredentials(creds.copyWith(
        hashedPassword: newHash,
        salt: BCrypt.gensalt(logRounds: 12),
        isFirstLogin: false,
      ));
      debugPrint('[AuthService] Password changed for $personId');
      return null; // success
    } catch (e) {
      debugPrint('[AuthService.changePassword] Error: $e');
      return 'An error occurred. Please try again.';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACCOUNT LOCK / UNLOCK
  // ──────────────────────────────────────────────────────────────────────────

  /// Increments failed attempts and locks the account if threshold is reached.
  Future<void> handleFailedAttempt(
      String personId, PasswordPolicyModel policy) async {
    try {
      final creds = await getCredentials(personId);
      if (creds == null) return;
      final newAttempts = creds.failedAttempts + 1;
      final shouldLock = newAttempts >= policy.maxFailedAttempts;
      final lockedUntil = shouldLock
          ? DateTime.now()
              .add(Duration(minutes: policy.lockoutDurationMinutes))
              .toUtc()
              .toIso8601String()
          : creds.lockedUntil;
      await updateCredentials(creds.copyWith(
        failedAttempts: newAttempts,
        accountLocked: shouldLock ? true : creds.accountLocked,
        lockedUntil: lockedUntil,
      ));
    } catch (e) {
      debugPrint('[AuthService.handleFailedAttempt] Error: $e');
    }
  }

  /// Resets failed attempts to 0 after a successful password verification.
  Future<void> resetFailedAttempts(String personId) async {
    try {
      final creds = await getCredentials(personId);
      if (creds == null) return;
      await updateCredentials(creds.copyWith(failedAttempts: 0));
    } catch (e) {
      debugPrint('[AuthService.resetFailedAttempts] Error: $e');
    }
  }

  /// Unlocks an account — clears lock flag, clears lockedUntil, resets failedAttempts.
  Future<void> unlockAccount(String personId) async {
    try {
      final creds = await getCredentials(personId);
      if (creds == null) return;
      await updateCredentials(
        creds.copyWith(
            accountLocked: false, failedAttempts: 0, clearLockedUntil: true),
      );
      debugPrint('[AuthService] Account unlocked for $personId');
    } catch (e) {
      debugPrint('[AuthService.unlockAccount] Error: $e');
    }
  }

  /// Forces a password reset on next login by setting isFirstLogin = true.
  Future<void> forcePasswordReset(String personId) async {
    try {
      final creds = await getCredentials(personId);
      if (creds == null) return;
      await updateCredentials(creds.copyWith(isFirstLogin: true));
      debugPrint('[AuthService] Forced password reset for $personId');
    } catch (e) {
      debugPrint('[AuthService.forcePasswordReset] Error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SESSION MANAGEMENT
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a new active session and returns the sessionId.
  Future<String> createSession(String personId, String authLevel) async {
    try {
      final db = await _db.database;
      final sessionId = _uuid.v4();
      final session = SessionModel(
        sessionId: sessionId,
        personId: personId,
        authLevel: authLevel,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
      await db.insert(AppConstants.tableSessions, session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('[AuthService] Session created: $sessionId for $personId');
      return sessionId;
    } catch (e) {
      debugPrint('[AuthService.createSession] Error: $e');
      rethrow;
    }
  }

  /// Invalidates a single session by sessionId.
  Future<void> invalidateSession(String sessionId) async {
    try {
      final db = await _db.database;
      await db.update(
        AppConstants.tableSessions,
        {'invalidatedAt': DateTime.now().toUtc().toIso8601String()},
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
      debugPrint('[AuthService] Session invalidated: $sessionId');
    } catch (e) {
      debugPrint('[AuthService.invalidateSession] Error: $e');
    }
  }

  /// Invalidates ALL active sessions for a person (used on password reset).
  Future<void> invalidateAllSessions(String personId) async {
    try {
      final db = await _db.database;
      await db.update(
        AppConstants.tableSessions,
        {'invalidatedAt': DateTime.now().toUtc().toIso8601String()},
        where: 'personId = ? AND invalidatedAt IS NULL',
        whereArgs: [personId],
      );
      debugPrint('[AuthService] All sessions invalidated for $personId');
    } catch (e) {
      debugPrint('[AuthService.invalidateAllSessions] Error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OTP
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates an 8-digit OTP, saves to DB, and returns the code.
  /// Returns null and an error message if rate-limited.
  Future<({String? code, String? error})> generateOtp(String personId) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().toUtc();

      // Check existing OTP record for rate limiting.
      final rows = await db.query(AppConstants.tableOtpCodes,
          where: 'personId = ?', whereArgs: [personId], limit: 1);

      if (rows.isNotEmpty) {
        final existing = OtpCodeModel.fromMap(rows.first);
        final windowStart = DateTime.parse(existing.hourWindowStart);
        final windowElapsed = now.difference(windowStart).inMinutes;

        if (windowElapsed < 60 && existing.requestCount >= 3) {
          final waitMinutes = 60 - windowElapsed;
          return (
            code: null,
            error:
                'Too many OTP requests. Please wait $waitMinutes minute(s) before requesting again.'
          );
        }

        final newCount = windowElapsed >= 60 ? 1 : existing.requestCount + 1;
        final windowStartStr = windowElapsed >= 60
            ? now.toIso8601String()
            : existing.hourWindowStart;
        final code = _generateOtpCode();
        final record = OtpCodeModel(
          personId: personId,
          code: code,
          generatedAt: now.toIso8601String(),
          expiresAt: now.add(const Duration(minutes: 5)).toIso8601String(),
          used: false,
          requestCount: newCount,
          hourWindowStart: windowStartStr,
        );
        await db.insert(AppConstants.tableOtpCodes, record.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        return (code: code, error: null);
      }

      // First OTP for this person.
      final code = _generateOtpCode();
      final record = OtpCodeModel(
        personId: personId,
        code: code,
        generatedAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(minutes: 5)).toIso8601String(),
        used: false,
        requestCount: 1,
        hourWindowStart: now.toIso8601String(),
      );
      await db.insert(AppConstants.tableOtpCodes, record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return (code: code, error: null);
    } catch (e) {
      debugPrint('[AuthService.generateOtp] Error: $e');
      return (code: null, error: 'Failed to generate OTP.');
    }
  }

  /// Verifies an entered OTP code against the stored one.
  Future<({bool success, String? error})> verifyOtp(
      String personId, String entered) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableOtpCodes,
          where: 'personId = ?', whereArgs: [personId], limit: 1);
      if (rows.isEmpty) {
        return (
          success: false,
          error: 'No OTP found. Please request a new code.'
        );
      }

      final otp = OtpCodeModel.fromMap(rows.first);
      if (otp.used) {
        return (
          success: false,
          error: 'Code has already been used. Please request a new one.'
        );
      }
      if (otp.isExpired) {
        return (
          success: false,
          error: 'Code has expired. Please request a new one.'
        );
      }
      if (otp.code != entered.trim()) {
        return (success: false, error: 'Incorrect code.');
      }

      // Mark as used.
      await db.update(
        AppConstants.tableOtpCodes,
        {'used': 1},
        where: 'personId = ?',
        whereArgs: [personId],
      );
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[AuthService.verifyOtp] Error: $e');
      return (success: false, error: 'Verification error.');
    }
  }

  /// Deletes the active OTP record for a person.
  Future<void> deleteOtpForPerson(String personId) async {
    try {
      final db = await _db.database;
      await db.delete(
        AppConstants.tableOtpCodes,
        where: 'personId = ?',
        whereArgs: [personId],
      );
    } catch (e) {
      debugPrint('[AuthService.deleteOtpForPerson] Error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TOTP
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates a new TOTP secret key.
  String generateTotpSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rng = Random.secure();
    return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Returns the current 6-digit TOTP code for a given secret (60-second window).
  String getCurrentTotpCode(String secret) {
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }

  /// Verifies a TOTP code with ±1 time-step tolerance.
  bool verifyTotpCode(String secret, String entered) {
    final normalized = entered.replaceAll(' ', '').trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final offset in [-30000, 0, 30000]) {
      final code = OTP.generateTOTPCodeString(
        secret,
        now + offset,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (code == normalized) return true;
    }
    return false;
  }

  /// Builds a standard otpauth URI for authenticator apps.
  String buildTotpProvisioningUri({
    required String secret,
    required String accountName,
    required String issuer,
  }) {
    final label =
        '${Uri.encodeComponent(issuer)}:${Uri.encodeComponent(accountName)}';
    return 'otpauth://totp/$label?secret=$secret&issuer=${Uri.encodeComponent(issuer)}&algorithm=SHA1&digits=6&period=30';
  }

  /// Generates 10 random alphanumeric backup codes.
  List<String> generateBackupCodes() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(
        10,
        (_) =>
            List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MFA METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Retrieves MFA methods for a person, or null if not configured.
  Future<MfaMethodsModel?> getMfaMethods(String personId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableMfaMethods,
          where: 'personId = ?', whereArgs: [personId], limit: 1);
      return rows.isEmpty ? null : MfaMethodsModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[AuthService.getMfaMethods] Error: $e');
      return null;
    }
  }

  /// Saves or updates MFA methods for a person.
  Future<void> saveMfaMethods(MfaMethodsModel methods) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tableMfaMethods, methods.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('[AuthService] MFA methods saved for ${methods.personId}');
    } catch (e) {
      debugPrint('[AuthService.saveMfaMethods] Error: $e');
      rethrow;
    }
  }

  /// Recalculates and updates the authLevel based on enabled MFA methods.
  /// IT Admin always stays L4. International students cannot go below L2.
  Future<void> recalculateAuthLevel(String personId, String userType) async {
    try {
      final creds = await getCredentials(personId);
      if (creds == null) return;

      // IT Admin level is immutable.
      if (userType == AppConstants.typeITAdmin) {
        if (creds.authLevel != AppConstants.authLevelL4) {
          await updateCredentials(
              creds.copyWith(authLevel: AppConstants.authLevelL4));
        }
        return;
      }

      final mfa = await getMfaMethods(personId);
      String level;
      if (mfa == null ||
          (!mfa.otpEnabled &&
              !mfa.totpEnabled &&
              !mfa.securityQuestionsEnabled)) {
        level = AppConstants.authLevelL1;
      } else if (mfa.otpEnabled && mfa.totpEnabled) {
        level = AppConstants.authLevelL3;
      } else if (mfa.otpEnabled) {
        level = AppConstants.authLevelL2;
      } else {
        level = AppConstants.authLevelL1;
      }

      // International students cannot fall below L2.
      if (userType == AppConstants.typeInternational &&
          level == AppConstants.authLevelL1) {
        level = AppConstants.authLevelL2;
      }

      await updateCredentials(creds.copyWith(authLevel: level));
      debugPrint('[AuthService] Auth level recalculated for $personId: $level');
    } catch (e) {
      debugPrint('[AuthService.recalculateAuthLevel] Error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // RESET TOKENS
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates a UUID reset token, saves to DB, and returns it.
  Future<String> generateResetToken(String personId) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().toUtc();
      final token = _uuid.v4();
      await db.insert(
          AppConstants.tableResetTokens,
          {
            'token': token,
            'personId': personId,
            'generatedAt': now.toIso8601String(),
            'expiresAt': now.add(const Duration(hours: 1)).toIso8601String(),
            'used': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('[AuthService] Reset token generated for $personId');
      return token;
    } catch (e) {
      debugPrint('[AuthService.generateResetToken] Error: $e');
      rethrow;
    }
  }

  /// Looks up a reset token and returns the model, or null if not found.
  Future<ResetTokenModel?> getResetToken(String token) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableResetTokens,
          where: 'token = ?', whereArgs: [token], limit: 1);
      return rows.isEmpty ? null : ResetTokenModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[AuthService.getResetToken] Error: $e');
      return null;
    }
  }

  /// Marks a reset token as used.
  Future<void> markTokenUsed(String token) async {
    try {
      final db = await _db.database;
      await db.update(AppConstants.tableResetTokens, {'used': 1},
          where: 'token = ?', whereArgs: [token]);
    } catch (e) {
      debugPrint('[AuthService.markTokenUsed] Error: $e');
    }
  }

  /// Deletes a reset token (used when email delivery fails).
  Future<void> deleteResetToken(String token) async {
    try {
      final db = await _db.database;
      await db.delete(
        AppConstants.tableResetTokens,
        where: 'token = ?',
        whereArgs: [token],
      );
    } catch (e) {
      debugPrint('[AuthService.deleteResetToken] Error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // IT ADMIN — USER AUTH LISTING
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns all credential records, used by IT Admin auth management screen.
  Future<List<AuthCredentialsModel>> getAllCredentials() async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableAuthCredentials);
      return rows.map(AuthCredentialsModel.fromMap).toList();
    } catch (e) {
      debugPrint('[AuthService.getAllCredentials] Error: $e');
      return [];
    }
  }

  /// Returns all currently locked accounts (accountLocked = 1).
  Future<List<AuthCredentialsModel>> getLockedAccounts() async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableAuthCredentials,
          where: 'accountLocked = 1');
      return rows.map(AuthCredentialsModel.fromMap).toList();
    } catch (e) {
      debugPrint('[AuthService.getLockedAccounts] Error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates a random 8-digit numeric OTP code.
  String _generateOtpCode() {
    final rng = Random.secure();
    return List.generate(8, (_) => rng.nextInt(10).toString()).join();
  }
}
