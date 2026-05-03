/// Model for the [sessions] table — tracks active and invalidated login sessions.
class SessionModel {
  final String sessionId;
  final String personId;
  final String authLevel;
  final String createdAt;
  final String ipAddress;
  final String? invalidatedAt;

  const SessionModel({
    required this.sessionId,
    required this.personId,
    required this.authLevel,
    required this.createdAt,
    this.ipAddress = 'local',
    this.invalidatedAt,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
        sessionId:     map['sessionId'] as String,
        personId:      map['personId'] as String,
        authLevel:     map['authLevel'] as String,
        createdAt:     map['createdAt'] as String,
        ipAddress:     map['ipAddress'] as String? ?? 'local',
        invalidatedAt: map['invalidatedAt'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'sessionId':     sessionId,
        'personId':      personId,
        'authLevel':     authLevel,
        'createdAt':     createdAt,
        'ipAddress':     ipAddress,
        'invalidatedAt': invalidatedAt,
      };

  bool get isActive => invalidatedAt == null;
}
