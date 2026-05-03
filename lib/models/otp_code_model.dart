/// Model for the [otp_codes] table — one active OTP per person, rate-limited.
class OtpCodeModel {
  final String personId;
  final String code;
  final String generatedAt;
  final String expiresAt;
  final bool used;
  final int requestCount;
  final String hourWindowStart;

  const OtpCodeModel({
    required this.personId,
    required this.code,
    required this.generatedAt,
    required this.expiresAt,
    this.used = false,
    this.requestCount = 1,
    required this.hourWindowStart,
  });

  factory OtpCodeModel.fromMap(Map<String, dynamic> map) => OtpCodeModel(
        personId:        map['personId'] as String,
        code:            map['code'] as String,
        generatedAt:     map['generatedAt'] as String,
        expiresAt:       map['expiresAt'] as String,
        used:            (map['used'] as int? ?? 0) == 1,
        requestCount:    map['requestCount'] as int? ?? 1,
        hourWindowStart: map['hourWindowStart'] as String,
      );

  Map<String, dynamic> toMap() => {
        'personId':        personId,
        'code':            code,
        'generatedAt':     generatedAt,
        'expiresAt':       expiresAt,
        'used':            used ? 1 : 0,
        'requestCount':    requestCount,
        'hourWindowStart': hourWindowStart,
      };

  bool get isExpired => DateTime.now().isAfter(DateTime.parse(expiresAt));
}
