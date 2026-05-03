/// Model for the [status_history] table — every status transition per person.
class StatusHistoryModel {
  final String id;
  final String personId;
  final String? oldStatus; // null on first creation
  final String newStatus;
  final String changedBy;  // uniqueId of operator
  final String timestamp;  // ISO 8601 UTC

  const StatusHistoryModel({
    required this.id,
    required this.personId,
    this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    required this.timestamp,
  });

  factory StatusHistoryModel.fromMap(Map<String, dynamic> map) => StatusHistoryModel(
        id:         map['id'] as String,
        personId:   map['personId'] as String,
        oldStatus:  map['oldStatus'] as String?,
        newStatus:  map['newStatus'] as String,
        changedBy:  map['changedBy'] as String,
        timestamp:  map['timestamp'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id':        id,
        'personId':  personId,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'changedBy': changedBy,
        'timestamp': timestamp,
      };
}
