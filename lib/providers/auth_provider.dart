import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/identity_service.dart';
import '../../services/audit_service.dart';
import '../../services/emailjs_service.dart';
import '../../models/person_model.dart';
import '../../models/auth_credentials_model.dart';
import '../../models/password_policy_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/password_utils.dart';

// ─── Service Providers ────────────────────────────────────────────────────────

/// Provides the singleton AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provides the singleton IdentityService instance.
final identityServiceProvider =
    Provider<IdentityService>((ref) => IdentityService());

/// Provides the singleton AuditService instance.
final auditServiceProvider = Provider<AuditService>((ref) => AuditService());

/// Provides the singleton EmailJsService instance.
final emailJsServiceProvider =
    Provider<EmailJsService>((ref) => EmailJsService());

// ─── Password Policy Provider ─────────────────────────────────────────────────

/// Always reads password policy from the database (never hardcoded).
final passwordPolicyProvider = FutureProvider<PasswordPolicyModel>((ref) async {
  return ref.read(authServiceProvider).getPasswordPolicy();
});

// ─── Auth State ───────────────────────────────────────────────────────────────

/// Represents which step of the login flow the user is on.
enum LoginStep { none, otp, totp, securityQuestion, complete }

/// Represents the full authentication state of the currently logged-in session.
class AuthState {
  final String? personId;
  final String? authLevel;
  final String? sessionId;
  final LoginStep loginStep;
  final bool isLoading;
  final String? errorMessage;
  final PersonModel? currentPerson;
  final AuthCredentialsModel? credentials;

  const AuthState({
    this.personId,
    this.authLevel,
    this.sessionId,
    this.loginStep = LoginStep.none,
    this.isLoading = false,
    this.errorMessage,
    this.currentPerson,
    this.credentials,
  });

  bool get isAuthenticated =>
      loginStep == LoginStep.complete && personId != null;

  AuthState copyWith({
    String? personId,
    String? authLevel,
    String? sessionId,
    LoginStep? loginStep,
    bool? isLoading,
    String? errorMessage,
    PersonModel? currentPerson,
    AuthCredentialsModel? credentials,
    bool clearError = false,
  }) =>
      AuthState(
        personId: personId ?? this.personId,
        authLevel: authLevel ?? this.authLevel,
        sessionId: sessionId ?? this.sessionId,
        loginStep: loginStep ?? this.loginStep,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPerson: currentPerson ?? this.currentPerson,
        credentials: credentials ?? this.credentials,
      );
}

/// Riverpod StateNotifier managing the full authentication lifecycle.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final IdentityService _identityService;
  final AuditService _auditService;
  final EmailJsService _emailJsService;

  AuthNotifier(
    this._authService,
    this._identityService,
    this._auditService,
    this._emailJsService,
  ) : super(const AuthState());

  /// Clears any visible auth error message (used by login form while editing).
  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }

  // ─── Step 1: Password Login ────────────────────────────────────────────────

  /// Performs the initial login step (username/password).
  /// Strictly follows IAM spec order: find person → check lock → verify password
  /// → check firstLogin → route by auth level.
  Future<LoginResult> login(String identifier, String password) async {
    debugPrint(
        '[AuthNotifier.login] Called with identifier: "$identifier", password length: ${password.length}');
    debugPrint(
        '[AuthNotifier.login] Password code units: ${password.codeUnits}');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint('[AuthNotifier.login] Step 1: Looking up person');
      final person = await _identityService.getPersonByIdOrEmail(identifier);
      debugPrint(
          '[AuthNotifier.login] Person lookup result: ${person != null ? person.uniqueId : "null"}');
      if (person == null) {
        await _recordUnknownAttempt(identifier);
        debugPrint('[AuthNotifier.login] Person not found, setting error');
        state = state.copyWith(
            isLoading: false, errorMessage: 'Invalid username or password.');
        return LoginResult.failed;
      }

      debugPrint('[AuthNotifier.login] Step 2: Getting credentials');
      final creds = await _authService.getCredentials(person.uniqueId);
      debugPrint(
          '[AuthNotifier.login] Credentials result: ${creds != null ? "found" : "null"}');
      if (creds == null) {
        state = state.copyWith(
            isLoading: false, errorMessage: 'Invalid username or password.');
        return LoginResult.failed;
      }

      debugPrint('[AuthNotifier.login] Step 3: Checking lock status');
      if (creds.isCurrentlyLocked) {
        final until = creds.lockedUntilDateTime;
        final msg = until != null
            ? 'Account locked. Try again after ${_formatTime(until)}.'
            : 'Account is locked. Please contact IT administration.';
        debugPrint('[AuthNotifier.login] Account locked: $msg');
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return LoginResult.locked;
      }

      debugPrint('[AuthNotifier.login] Step 4: Verifying password');
      debugPrint('[AuthNotifier.login] Hash from DB: ${creds.hashedPassword}');
      final policy = await _authService.getPasswordPolicy();
      final isCorrect =
          await PasswordUtils.verifyPassword(password, creds.hashedPassword);
      debugPrint(
          '[AuthNotifier.login] Password verification result: $isCorrect');

      if (!isCorrect) {
        debugPrint(
            '[AuthNotifier.login] Password incorrect, handling failed attempt');
        await _authService.handleFailedAttempt(person.uniqueId, policy);
        await _auditService.logLoginAttempt(
          personId: person.uniqueId,
          success: false,
          failureReason: 'Wrong password',
        );
        final updated = await _authService.getCredentials(person.uniqueId);
        if (updated != null && updated.isCurrentlyLocked) {
          final until = updated.lockedUntilDateTime;
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Account locked due to too many failed attempts. '
                'Try again after ${_formatTime(until!)}.',
          );
          return LoginResult.locked;
        }
        state = state.copyWith(
            isLoading: false, errorMessage: 'Invalid username or password.');
        return LoginResult.failed;
      }

      debugPrint(
          '[AuthNotifier.login] Step 5: Password correct, resetting failed attempts');
      await _authService.resetFailedAttempts(person.uniqueId);

      state = state.copyWith(
        personId: person.uniqueId,
        authLevel: creds.authLevel,
        currentPerson: person,
        credentials: creds,
        isLoading: false,
        clearError: true,
      );
      debugPrint(
          '[AuthNotifier.login] State updated, isLoading=false, personId=${person.uniqueId}');

      if (creds.isFirstLogin) {
        debugPrint('[AuthNotifier.login] First login detected');
        return LoginResult.firstLogin;
      }

      return _routeByAuthLevel(creds.authLevel);
    } catch (e, stack) {
      debugPrint('[AuthNotifier.login] EXCEPTION: $e');
      debugPrint('[AuthNotifier.login] Stack trace: $stack');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Login error. Please try again.');
      return LoginResult.failed;
    }
  }

  // ─── Step 2: OTP Verification ──────────────────────────────────────────────

  /// Generates and returns the OTP for display. Returns error string on rate limit.
  Future<({String? code, String? error})> requestOtp() async {
    final personId = state.personId;
    if (personId == null) return (code: null, error: 'Session expired.');

    final person =
        state.currentPerson ?? await _identityService.getPersonById(personId);
    if (person == null) {
      return (code: null, error: 'Session expired. Please log in again.');
    }

    final result = await _authService.generateOtp(personId);
    if (result.error != null || result.code == null) {
      return result;
    }

    final sent = await _emailJsService.sendOtpEmail(
      toEmail: person.personalEmail,
      toName: '${person.firstName} ${person.lastName}',
      otpCode: result.code!,
      appName: 'IAM project',
    );

    if (!sent) {
      await _authService.deleteOtpForPerson(personId);
      return (
        code: null,
        error: 'Could not send OTP email. Please retry in a moment.',
      );
    }

    return (code: null, error: null);
  }

  /// Verifies the entered OTP code and advances the login step if correct.
  Future<OtpResult> verifyOtp(String code) async {
    final personId = state.personId;
    if (personId == null) return OtpResult.sessionExpired;

    final result = await _authService.verifyOtp(personId, code);
    if (!result.success) {
      await _auditService.logLoginAttempt(
        personId: personId,
        success: false,
        failureReason: result.error?.contains('expired') == true
            ? 'OTP expired'
            : 'Wrong OTP',
        mfaUsed: true,
      );
      state = state.copyWith(errorMessage: result.error);
      return OtpResult.failed;
    }

    state = state.copyWith(clearError: true);
    // Advance step based on auth level.
    if (state.authLevel == AppConstants.authLevelL2) {
      return OtpResult.proceedToHome;
    } else {
      return OtpResult.proceedToTotp;
    }
  }

  // ─── Step 3: TOTP Verification ────────────────────────────────────────────

  /// Verifies the entered 6-digit TOTP code (or backup code).
  Future<TotpResult> verifyTotp(String code) async {
    final personId = state.personId;
    if (personId == null) return TotpResult.sessionExpired;

    final mfa = await _authService.getMfaMethods(personId);
    if (mfa == null || mfa.totpSecret == null) return TotpResult.notConfigured;

    final isValid = _authService.verifyTotpCode(mfa.totpSecret!, code);
    if (!isValid) {
      await _auditService.logLoginAttempt(
        personId: personId,
        success: false,
        failureReason: 'Wrong TOTP',
        mfaUsed: true,
      );
      state = state.copyWith(errorMessage: 'Invalid authenticator code.');
      return TotpResult.failed;
    }

    state = state.copyWith(clearError: true);
    if (state.authLevel == AppConstants.authLevelL3) {
      return TotpResult.proceedToHome;
    } else {
      return TotpResult.proceedToSecQuestion;
    }
  }

  /// Uses a backup TOTP code. Marks it used and advances the step.
  Future<TotpResult> useTotpBackupCode(String code) async {
    final personId = state.personId;
    if (personId == null) return TotpResult.sessionExpired;

    final mfa = await _authService.getMfaMethods(personId);
    if (mfa == null) return TotpResult.notConfigured;

    final index = mfa.totpBackupCodes.indexOf(code.trim().toUpperCase());
    if (index == -1 || mfa.totpBackupCodesUsed[index]) {
      state =
          state.copyWith(errorMessage: 'Invalid or already used backup code.');
      return TotpResult.failed;
    }

    // Mark backup code as used.
    final updatedUsed = List<bool>.from(mfa.totpBackupCodesUsed)
      ..[index] = true;
    await _authService
        .saveMfaMethods(mfa.copyWith(totpBackupCodesUsed: updatedUsed));

    state = state.copyWith(clearError: true);
    return state.authLevel == AppConstants.authLevelL3
        ? TotpResult.proceedToHome
        : TotpResult.proceedToSecQuestion;
  }

  // ─── Step 4: Security Questions ───────────────────────────────────────────

  /// Verifies both security question answers. Locks account after 3 wrong attempts.
  Future<SecQResult> verifySecurityQuestions(
      String answer1, String answer2) async {
    final personId = state.personId;
    if (personId == null) return SecQResult.sessionExpired;

    final mfa = await _authService.getMfaMethods(personId);
    if (mfa == null ||
        mfa.securityAnswer1Hashed == null ||
        mfa.securityAnswer2Hashed == null) {
      return SecQResult.notConfigured;
    }

    final a1 = answer1.trim().toLowerCase();
    final a2 = answer2.trim().toLowerCase();
    final ok1 =
        await PasswordUtils.verifyPassword(a1, mfa.securityAnswer1Hashed!);
    final ok2 =
        await PasswordUtils.verifyPassword(a2, mfa.securityAnswer2Hashed!);

    if (!ok1 || !ok2) {
      await _auditService.logLoginAttempt(
        personId: personId,
        success: false,
        failureReason: 'Wrong security answer',
        mfaUsed: true,
      );
      state = state.copyWith(errorMessage: 'Incorrect answer(s).');
      return SecQResult.failed;
    }

    return SecQResult.proceedToHome;
  }

  // ─── Finalize Login ───────────────────────────────────────────────────────

  /// Finalizes authentication — creates session, logs success, sets state to complete.
  Future<void> finalizeLogin() async {
    final personId = state.personId;
    final authLevel = state.authLevel;
    if (personId == null || authLevel == null) return;

    try {
      final sessionId = await _authService.createSession(personId, authLevel);
      await _auditService.logLoginAttempt(
        personId: personId,
        success: true,
        mfaUsed: authLevel != AppConstants.authLevelL1,
        sessionId: sessionId,
      );
      state =
          state.copyWith(sessionId: sessionId, loginStep: LoginStep.complete);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create session.');
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  /// Invalidates the current session and clears all in-memory state.
  Future<void> logout() async {
    final sessionId = state.sessionId;
    if (sessionId != null) {
      await _authService.invalidateSession(sessionId);
    }
    state = const AuthState();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Routes to the correct next step based on auth level.
  LoginResult _routeByAuthLevel(String authLevel) {
    switch (authLevel) {
      case AppConstants.authLevelL1:
        return LoginResult.proceedToHome;
      case AppConstants.authLevelL2:
      case AppConstants.authLevelL3:
      case AppConstants.authLevelL4:
        return LoginResult.proceedToOtp;
      default:
        return LoginResult.proceedToHome;
    }
  }

  /// Logs a failed attempt for an unknown identifier (no personId to increment).
  Future<void> _recordUnknownAttempt(String identifier) async {
    await _auditService.logLoginAttempt(
      personId: 'unknown:$identifier',
      success: false,
      failureReason: 'Wrong password',
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Result Enums ─────────────────────────────────────────────────────────────

enum LoginResult { failed, locked, firstLogin, proceedToOtp, proceedToHome }

enum OtpResult { failed, sessionExpired, proceedToTotp, proceedToHome }

enum TotpResult {
  failed,
  sessionExpired,
  notConfigured,
  proceedToSecQuestion,
  proceedToHome
}

enum SecQResult { failed, sessionExpired, notConfigured, proceedToHome }

// ─── Provider ────────────────────────────────────────────────────────────────

/// The main auth state provider — manages login flow from password to MFA to session.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(identityServiceProvider),
    ref.read(auditServiceProvider),
    ref.read(emailJsServiceProvider),
  );
});
