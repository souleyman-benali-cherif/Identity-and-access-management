/// Model for the [contractors] table — external vendors with expiring access.
class ContractorModel {
  final String uniqueId;
  final String? contractPurpose;
  final String accessExpiryDate; // ISO 8601 string

  const ContractorModel({
    required this.uniqueId,
    this.contractPurpose,
    required this.accessExpiryDate,
  });

  /// Creates a ContractorModel from a sqflite row map.
  factory ContractorModel.fromMap(Map<String, dynamic> map) => ContractorModel(
        uniqueId:         map['uniqueId'] as String,
        contractPurpose:  map['contractPurpose'] as String?,
        accessExpiryDate: map['accessExpiryDate'] as String,
      );

  /// Converts this model to a sqflite-compatible map.
  Map<String, dynamic> toMap() => {
        'uniqueId':         uniqueId,
        'contractPurpose':  contractPurpose,
        'accessExpiryDate': accessExpiryDate,
      };

  /// Returns the expiry as a DateTime for comparison logic.
  DateTime get expiryDateTime => DateTime.parse(accessExpiryDate);

  /// True if access has already expired.
  bool get isExpired => expiryDateTime.isBefore(DateTime.now());

  /// True if access expires within 7 days.
  bool get expiresWithinSevenDays {
    final diff = expiryDateTime.difference(DateTime.now());
    return !isExpired && diff.inDays <= 7;
  }
}
