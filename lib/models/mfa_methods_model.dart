import 'dart:convert';

/// Model for the [mfa_methods] table — TOTP, backup codes, security questions.
class MfaMethodsModel {
  final String personId;
  final String? totpSecret;
  final List<String> totpBackupCodes;      // 10 alphanumeric codes
  final List<bool> totpBackupCodesUsed;    // parallel bool list, true = used
  final String? securityQuestion1;
  final String? securityAnswer1Hashed;     // bcrypt hash, lowercased answer
  final String? securityQuestion2;
  final String? securityAnswer2Hashed;     // bcrypt hash, lowercased answer
  final bool otpEnabled;
  final bool totpEnabled;
  final bool securityQuestionsEnabled;

  const MfaMethodsModel({
    required this.personId,
    this.totpSecret,
    this.totpBackupCodes = const [],
    this.totpBackupCodesUsed = const [],
    this.securityQuestion1,
    this.securityAnswer1Hashed,
    this.securityQuestion2,
    this.securityAnswer2Hashed,
    this.otpEnabled = false,
    this.totpEnabled = false,
    this.securityQuestionsEnabled = false,
  });

  /// Creates a MfaMethodsModel from a sqflite row map.
  factory MfaMethodsModel.fromMap(Map<String, dynamic> map) => MfaMethodsModel(
        personId:                 map['personId'] as String,
        totpSecret:               map['totpSecret'] as String?,
        totpBackupCodes:          _decodeStringList(map['totpBackupCodes']),
        totpBackupCodesUsed:      _decodeBoolList(map['totpBackupCodesUsed']),
        securityQuestion1:        map['securityQuestion1'] as String?,
        securityAnswer1Hashed:    map['securityAnswer1Hashed'] as String?,
        securityQuestion2:        map['securityQuestion2'] as String?,
        securityAnswer2Hashed:    map['securityAnswer2Hashed'] as String?,
        otpEnabled:               (map['otpEnabled'] as int? ?? 0) == 1,
        totpEnabled:              (map['totpEnabled'] as int? ?? 0) == 1,
        securityQuestionsEnabled: (map['securityQuestionsEnabled'] as int? ?? 0) == 1,
      );

  /// Converts this model to a sqflite-compatible map.
  Map<String, dynamic> toMap() => {
        'personId':                 personId,
        'totpSecret':               totpSecret,
        'totpBackupCodes':          jsonEncode(totpBackupCodes),
        'totpBackupCodesUsed':      jsonEncode(totpBackupCodesUsed.map((b) => b ? 1 : 0).toList()),
        'securityQuestion1':        securityQuestion1,
        'securityAnswer1Hashed':    securityAnswer1Hashed,
        'securityQuestion2':        securityQuestion2,
        'securityAnswer2Hashed':    securityAnswer2Hashed,
        'otpEnabled':               otpEnabled ? 1 : 0,
        'totpEnabled':              totpEnabled ? 1 : 0,
        'securityQuestionsEnabled': securityQuestionsEnabled ? 1 : 0,
      };

  /// Returns how many backup codes are still unused.
  int get remainingBackupCodes =>
      totpBackupCodesUsed.where((used) => !used).length;

  /// Returns a copy with specified fields replaced.
  MfaMethodsModel copyWith({
    String? totpSecret,
    List<String>? totpBackupCodes,
    List<bool>? totpBackupCodesUsed,
    String? securityQuestion1,
    String? securityAnswer1Hashed,
    String? securityQuestion2,
    String? securityAnswer2Hashed,
    bool? otpEnabled,
    bool? totpEnabled,
    bool? securityQuestionsEnabled,
  }) =>
      MfaMethodsModel(
        personId:                 personId,
        totpSecret:               totpSecret ?? this.totpSecret,
        totpBackupCodes:          totpBackupCodes ?? this.totpBackupCodes,
        totpBackupCodesUsed:      totpBackupCodesUsed ?? this.totpBackupCodesUsed,
        securityQuestion1:        securityQuestion1 ?? this.securityQuestion1,
        securityAnswer1Hashed:    securityAnswer1Hashed ?? this.securityAnswer1Hashed,
        securityQuestion2:        securityQuestion2 ?? this.securityQuestion2,
        securityAnswer2Hashed:    securityAnswer2Hashed ?? this.securityAnswer2Hashed,
        otpEnabled:               otpEnabled ?? this.otpEnabled,
        totpEnabled:              totpEnabled ?? this.totpEnabled,
        securityQuestionsEnabled: securityQuestionsEnabled ?? this.securityQuestionsEnabled,
      );

  /// Decodes a JSON-encoded string list.
  static List<String> _decodeStringList(dynamic raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw as String) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Decodes a JSON-encoded int list to bool list.
  static List<bool> _decodeBoolList(dynamic raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw as String) as List).map((v) => (v as int) == 1).toList();
    } catch (_) {
      return [];
    }
  }
}
