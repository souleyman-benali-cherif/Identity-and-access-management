import '../core/constants/app_constants.dart';

/// Model for the [password_policy] table — single row, key = 'policy'.
/// All values must be read from DB; never hardcode policy values in business logic.
class PasswordPolicyModel {
  final int minLength;
  final int maxLength;
  final int minCategories;
  final int historyCount;
  final int maxFailedAttempts;
  final int lockoutDurationMinutes;

  const PasswordPolicyModel({
    this.minLength             = AppConstants.defaultMinLength,
    this.maxLength             = AppConstants.defaultMaxLength,
    this.minCategories         = AppConstants.defaultMinCategories,
    this.historyCount          = AppConstants.defaultHistoryCount,
    this.maxFailedAttempts     = AppConstants.defaultMaxFailedAttempts,
    this.lockoutDurationMinutes = AppConstants.defaultLockoutDurationMinutes,
  });

  factory PasswordPolicyModel.fromMap(Map<String, dynamic> map) => PasswordPolicyModel(
        minLength:             map['minLength'] as int? ?? AppConstants.defaultMinLength,
        maxLength:             map['maxLength'] as int? ?? AppConstants.defaultMaxLength,
        minCategories:         map['minCategories'] as int? ?? AppConstants.defaultMinCategories,
        historyCount:          map['historyCount'] as int? ?? AppConstants.defaultHistoryCount,
        maxFailedAttempts:     map['maxFailedAttempts'] as int? ?? AppConstants.defaultMaxFailedAttempts,
        lockoutDurationMinutes: map['lockoutDurationMinutes'] as int? ?? AppConstants.defaultLockoutDurationMinutes,
      );

  Map<String, dynamic> toMap() => {
        'id':                     'policy',
        'minLength':              minLength,
        'maxLength':              maxLength,
        'minCategories':          minCategories,
        'historyCount':           historyCount,
        'maxFailedAttempts':      maxFailedAttempts,
        'lockoutDurationMinutes': lockoutDurationMinutes,
      };
}
