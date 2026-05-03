import 'dart:convert';

/// Model for the [faculty_members] table — covers Tenured, Adjunct, VisitingResearcher.
class FacultyModel {
  final String uniqueId;
  final String? rank;
  final String? employmentCategory;
  final String? appointmentStartDate;
  final String? primaryDepartment;
  final List<String> secondaryDepartments;
  final String? officeBuilding;
  final String? officeFloor;
  final String? officeRoom;
  final String? phdInstitution;
  final List<String> researchAreas;
  final bool habilitationToSupervise;
  final String? contractType;
  final String? contractStartDate;
  final String? contractEndDate; // null if Permanent
  final int? teachingHoursPerWeek;

  const FacultyModel({
    required this.uniqueId,
    this.rank,
    this.employmentCategory,
    this.appointmentStartDate,
    this.primaryDepartment,
    this.secondaryDepartments = const [],
    this.officeBuilding,
    this.officeFloor,
    this.officeRoom,
    this.phdInstitution,
    this.researchAreas = const [],
    this.habilitationToSupervise = false,
    this.contractType,
    this.contractStartDate,
    this.contractEndDate,
    this.teachingHoursPerWeek,
  });

  /// Creates a FacultyModel from a sqflite row map (JSON-encoded lists).
  factory FacultyModel.fromMap(Map<String, dynamic> map) => FacultyModel(
        uniqueId:               map['uniqueId'] as String,
        rank:                   map['rank'] as String?,
        employmentCategory:     map['employmentCategory'] as String?,
        appointmentStartDate:   map['appointmentStartDate'] as String?,
        primaryDepartment:      map['primaryDepartment'] as String?,
        secondaryDepartments:   _decodeList(map['secondaryDepartments']),
        officeBuilding:         map['officeBuilding'] as String?,
        officeFloor:            map['officeFloor'] as String?,
        officeRoom:             map['officeRoom'] as String?,
        phdInstitution:         map['phdInstitution'] as String?,
        researchAreas:          _decodeList(map['researchAreas']),
        habilitationToSupervise: (map['habilitationToSupervise'] as int? ?? 0) == 1,
        contractType:           map['contractType'] as String?,
        contractStartDate:      map['contractStartDate'] as String?,
        contractEndDate:        map['contractEndDate'] as String?,
        teachingHoursPerWeek:   map['teachingHoursPerWeek'] as int?,
      );

  /// Converts this model to a sqflite-compatible map (lists encoded as JSON).
  Map<String, dynamic> toMap() => {
        'uniqueId':               uniqueId,
        'rank':                   rank,
        'employmentCategory':     employmentCategory,
        'appointmentStartDate':   appointmentStartDate,
        'primaryDepartment':      primaryDepartment,
        'secondaryDepartments':   jsonEncode(secondaryDepartments),
        'officeBuilding':         officeBuilding,
        'officeFloor':            officeFloor,
        'officeRoom':             officeRoom,
        'phdInstitution':         phdInstitution,
        'researchAreas':          jsonEncode(researchAreas),
        'habilitationToSupervise': habilitationToSupervise ? 1 : 0,
        'contractType':           contractType,
        'contractStartDate':      contractStartDate,
        'contractEndDate':        contractEndDate,
        'teachingHoursPerWeek':   teachingHoursPerWeek,
      };

  /// Decodes a JSON-encoded list stored as a string.
  static List<String> _decodeList(dynamic raw) {
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw as String);
      return (decoded as List).cast<String>();
    } catch (_) {
      return [];
    }
  }
}
