/// Model for the [staff_members] table — covers Administrative, Technical, Temporary staff.
class StaffModel {
  final String uniqueId;
  final String? assignedDepartment;
  final String? jobTitle;
  final String? grade;
  final String? dateOfEntry; // ISO 8601 string

  const StaffModel({
    required this.uniqueId,
    this.assignedDepartment,
    this.jobTitle,
    this.grade,
    this.dateOfEntry,
  });

  /// Creates a StaffModel from a sqflite row map.
  factory StaffModel.fromMap(Map<String, dynamic> map) => StaffModel(
        uniqueId:           map['uniqueId'] as String,
        assignedDepartment: map['assignedDepartment'] as String?,
        jobTitle:           map['jobTitle'] as String?,
        grade:              map['grade'] as String?,
        dateOfEntry:        map['dateOfEntry'] as String?,
      );

  /// Converts this model to a sqflite-compatible map.
  Map<String, dynamic> toMap() => {
        'uniqueId':           uniqueId,
        'assignedDepartment': assignedDepartment,
        'jobTitle':           jobTitle,
        'grade':              grade,
        'dateOfEntry':        dateOfEntry,
      };
}
