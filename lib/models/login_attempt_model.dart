/// Model for the [login_attempts] table — full audit of every auth attempt.
class LoginAttemptModel {
  final String id;
  final String timestamp;
  final String personId;
  final bool success;
  final String ipAddress;
  final bool mfaUsed;
  final String? failureReason;
  final String? sessionId;

  const LoginAttemptModel({
    required this.id,
    required this.timestamp,
    required this.personId,
    required this.success,
    this.ipAddress = 'local',
    this.mfaUsed = false,
    this.failureReason,
    this.sessionId,
  });

  factory LoginAttemptModel.fromMap(Map<String, dynamic> map) => LoginAttemptModel(
        id:            map['id'] as String,
        timestamp:     map['timestamp'] as String,
        personId:      map['personId'] as String,
        success:       (map['success'] as int? ?? 0) == 1,
        ipAddress:     map['ipAddress'] as String? ?? 'local',
        mfaUsed:       (map['mfaUsed'] as int? ?? 0) == 1,
        failureReason: map['failureReason'] as String?,
        sessionId:     map['sessionId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id':            id,
        'timestamp':     timestamp,
        'personId':      personId,
        'success':       success ? 1 : 0,
        'ipAddress':     ipAddress,
        'mfaUsed':       mfaUsed ? 1 : 0,
        'failureReason': failureReason,
        'sessionId':     sessionId,
      };
}
