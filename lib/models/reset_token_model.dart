/// Model for the [reset_tokens] table — UUID-based password reset tokens.
class ResetTokenModel {
  final String token;
  final String personId;
  final String generatedAt;
  final String expiresAt;
  final bool used;

  const ResetTokenModel({
    required this.token,
    required this.personId,
    required this.generatedAt,
    required this.expiresAt,
    this.used = false,
  });

  factory ResetTokenModel.fromMap(Map<String, dynamic> map) => ResetTokenModel(
        token:       map['token'] as String,
        personId:    map['personId'] as String,
        generatedAt: map['generatedAt'] as String,
        expiresAt:   map['expiresAt'] as String,
        used:        (map['used'] as int? ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        'token':       token,
        'personId':    personId,
        'generatedAt': generatedAt,
        'expiresAt':   expiresAt,
        'used':        used ? 1 : 0,
      };

  bool get isExpired => DateTime.now().isAfter(DateTime.parse(expiresAt));
}
