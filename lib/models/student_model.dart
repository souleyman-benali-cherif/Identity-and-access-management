/// Model for the [students] table — covers Undergraduate, ContinuingEducation, PhD, International.
class StudentModel {
  final String uniqueId;
  final String? nationalIdNumber;
  final String? diplomaType;
  final int? diplomaYear;
  final String? diplomaHonors;
  final String? chosenMajor;
  final int? entryYear;
  final String? faculty;
  final String? department;
  final String? grp;
  final bool scholarshipStatus;
  final String? supervisingProfessorId; // PhD only
  final String? stayStartDate;          // International only
  final String? stayEndDate;            // International only

  const StudentModel({
    required this.uniqueId,
    this.nationalIdNumber,
    this.diplomaType,
    this.diplomaYear,
    this.diplomaHonors,
    this.chosenMajor,
    this.entryYear,
    this.faculty,
    this.department,
    this.grp,
    this.scholarshipStatus = false,
    this.supervisingProfessorId,
    this.stayStartDate,
    this.stayEndDate,
  });

  /// Creates a StudentModel from a sqflite row map.
  factory StudentModel.fromMap(Map<String, dynamic> map) => StudentModel(
        uniqueId:               map['uniqueId'] as String,
        nationalIdNumber:       map['nationalIdNumber'] as String?,
        diplomaType:            map['diplomaType'] as String?,
        diplomaYear:            map['diplomaYear'] as int?,
        diplomaHonors:          map['diplomaHonors'] as String?,
        chosenMajor:            map['chosenMajor'] as String?,
        entryYear:              map['entryYear'] as int?,
        faculty:                map['faculty'] as String?,
        department:             map['department'] as String?,
        grp:                    map['grp'] as String?,
        scholarshipStatus:      (map['scholarshipStatus'] as int? ?? 0) == 1,
        supervisingProfessorId: map['supervisingProfessorId'] as String?,
        stayStartDate:          map['stayStartDate'] as String?,
        stayEndDate:            map['stayEndDate'] as String?,
      );

  /// Converts this model to a sqflite-compatible map.
  Map<String, dynamic> toMap() => {
        'uniqueId':               uniqueId,
        'nationalIdNumber':       nationalIdNumber,
        'diplomaType':            diplomaType,
        'diplomaYear':            diplomaYear,
        'diplomaHonors':          diplomaHonors,
        'chosenMajor':            chosenMajor,
        'entryYear':              entryYear,
        'faculty':                faculty,
        'department':             department,
        'grp':                    grp,
        'scholarshipStatus':      scholarshipStatus ? 1 : 0,
        'supervisingProfessorId': supervisingProfessorId,
        'stayStartDate':          stayStartDate,
        'stayEndDate':            stayEndDate,
      };
}
