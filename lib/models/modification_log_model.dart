/// Model for the [modification_log] table — field-level change audit per person.
class ModificationLogModel {
  final String id;
  final String personId;
  final String fieldChanged;
  final String oldValue;
  final String newValue;
  final String changedBy; // uniqueId of operator
  final String timestamp; // ISO 8601 UTC

  const ModificationLogModel({
    required this.id,
    required this.personId,
    required this.fieldChanged,
    required this.oldValue,
    required this.newValue,
    required this.changedBy,
    required this.timestamp,
  });

  factory ModificationLogModel.fromMap(Map<String, dynamic> map) => ModificationLogModel(
        id:           map['id'] as String,
        personId:     map['personId'] as String,
        fieldChanged: map['fieldChanged'] as String,
        oldValue:     map['oldValue'] as String,
        newValue:     map['newValue'] as String,
        changedBy:    map['changedBy'] as String,
        timestamp:    map['timestamp'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id':           id,
        'personId':     personId,
        'fieldChanged': fieldChanged,
        'oldValue':     oldValue,
        'newValue':     newValue,
        'changedBy':    changedBy,
        'timestamp':    timestamp,
      };
}
