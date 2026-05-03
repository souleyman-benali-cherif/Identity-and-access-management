/// Model for the [auth_credentials] table — password hash, lock state, MFA level.
class AuthCredentialsModel {
  final String personId;
  final String hashedPassword;
  final String salt;
  final int costFactor;
  final bool isFirstLogin;
  final String authLevel; // L1, L2, L3, L4
  final bool accountLocked;
  final String? lockedUntil; // ISO 8601 or null
  final int failedAttempts;

  const AuthCredentialsModel({
    required this.personId,
    required this.hashedPassword,
    required this.salt,
    this.costFactor = 12,
    this.isFirstLogin = true,
    required this.authLevel,
    this.accountLocked = false,
    this.lockedUntil,
    this.failedAttempts = 0,
  });

  /// Creates an AuthCredentialsModel from a sqflite row map.
  factory AuthCredentialsModel.fromMap(Map<String, dynamic> map) => AuthCredentialsModel(
        personId:       map['personId'] as String,
        hashedPassword: map['hashedPassword'] as String,
        salt:           map['salt'] as String,
        costFactor:     map['costFactor'] as int? ?? 12,
        isFirstLogin:   (map['isFirstLogin'] as int? ?? 1) == 1,
        authLevel:      map['authLevel'] as String? ?? 'L1',
        accountLocked:  (map['accountLocked'] as int? ?? 0) == 1,
        lockedUntil:    map['lockedUntil'] as String?,
        failedAttempts: map['failedAttempts'] as int? ?? 0,
      );

  /// Converts this model to a sqflite-compatible map.
  Map<String, dynamic> toMap() => {
        'personId':       personId,
        'hashedPassword': hashedPassword,
        'salt':           salt,
        'costFactor':     costFactor,
        'isFirstLogin':   isFirstLogin ? 1 : 0,
        'authLevel':      authLevel,
        'accountLocked':  accountLocked ? 1 : 0,
        'lockedUntil':    lockedUntil,
        'failedAttempts': failedAttempts,
      };

  /// Returns lockedUntil as a DateTime if set.
  DateTime? get lockedUntilDateTime =>
      lockedUntil != null ? DateTime.parse(lockedUntil!) : null;

  /// True if the account is currently locked (locked flag AND lock hasn't expired).
  bool get isCurrentlyLocked {
    if (!accountLocked) return false;
    final until = lockedUntilDateTime;
    if (until == null) return true;
    return DateTime.now().isBefore(until);
  }

  /// Returns a copy with specified fields replaced.
  AuthCredentialsModel copyWith({
    String? hashedPassword,
    String? salt,
    bool? isFirstLogin,
    String? authLevel,
    bool? accountLocked,
    String? lockedUntil,
    int? failedAttempts,
    bool clearLockedUntil = false,
  }) =>
      AuthCredentialsModel(
        personId:       personId,
        hashedPassword: hashedPassword ?? this.hashedPassword,
        salt:           salt ?? this.salt,
        costFactor:     costFactor,
        isFirstLogin:   isFirstLogin ?? this.isFirstLogin,
        authLevel:      authLevel ?? this.authLevel,
        accountLocked:  accountLocked ?? this.accountLocked,
        lockedUntil:    clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
        failedAttempts: failedAttempts ?? this.failedAttempts,
      );
}
