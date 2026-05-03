import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../models/person_model.dart';
import '../../models/student_model.dart';
import '../../models/faculty_model.dart';
import '../../models/staff_model.dart';
import '../../models/contractor_model.dart';
import '../../models/status_history_model.dart';
import '../../models/modification_log_model.dart';
import 'package:uuid/uuid.dart';

/// Service for all identity operations — persons, students, faculty, staff, contractors.
/// This is the ONLY class that reads from or writes to the identity-related SQL tables.
/// UI components must NEVER call DatabaseHelper directly.
class IdentityService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ──────────────────────────────────────────────────────────────────────────
  // PERSONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Retrieves a person by their uniqueId, or null if not found.
  Future<PersonModel?> getPersonById(String uniqueId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        AppConstants.tablePersons,
        where: 'uniqueId = ?',
        whereArgs: [uniqueId],
        limit: 1,
      );
      return rows.isEmpty ? null : PersonModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[IdentityService.getPersonById] Error: $e');
      return null;
    }
  }

  /// Retrieves a person by their personal email, or null if not found.
  Future<PersonModel?> getPersonByEmail(String email) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        AppConstants.tablePersons,
        where: 'personalEmail = ?',
        whereArgs: [email.trim().toLowerCase()],
        limit: 1,
      );
      return rows.isEmpty ? null : PersonModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[IdentityService.getPersonByEmail] Error: $e');
      return null;
    }
  }

  /// Looks up a person by uniqueId OR email — used in login.
  Future<PersonModel?> getPersonByIdOrEmail(String input) async {
    final byId = await getPersonById(input.trim());
    if (byId != null) return byId;
    return getPersonByEmail(input.trim());
  }

  /// Checks if an email is completely unique in the system.
  Future<bool> isEmailUnique(String email) async {
    final person = await getPersonByEmail(email);
    return person == null;
  }

  /// Returns all persons in the system.
  Future<List<PersonModel>> getAllPersons() async {
    try {
      final db = await _db.database;
      final rows =
          await db.query(AppConstants.tablePersons, orderBy: 'createdAt DESC');
      return rows.map(PersonModel.fromMap).toList();
    } catch (e) {
      debugPrint('[IdentityService.getAllPersons] Error: $e');
      return [];
    }
  }

  /// Searches persons by name, uniqueId, or email (partial match).
  /// Optionally filters by status and/or userType category.
  Future<List<PersonModel>> searchPersons(
    String query, {
    String? statusFilter,
    String?
        typeCategory, // 'Student', 'Faculty', 'Staff', 'Contractor', 'Alumni'
  }) async {
    try {
      final db = await _db.database;
      final q = '%${query.toLowerCase()}%';
      final conditions = <String>[];
      final args = <dynamic>[];

      conditions.add(
        '(LOWER(firstName) LIKE ? OR LOWER(lastName) LIKE ? OR '
        'LOWER(uniqueId) LIKE ? OR LOWER(personalEmail) LIKE ?)',
      );
      args.addAll([q, q, q, q]);

      if (statusFilter != null && statusFilter != 'All') {
        conditions.add('status = ?');
        args.add(statusFilter);
      }

      if (typeCategory != null && typeCategory != 'All') {
        final types = _typesForCategory(typeCategory);
        if (types.isNotEmpty) {
          final placeholders = List.filled(types.length, '?').join(', ');
          conditions.add('userType IN ($placeholders)');
          args.addAll(types);
        }
      }

      final where = conditions.join(' AND ');
      final rows = await db.query(
        AppConstants.tablePersons,
        where: where,
        whereArgs: args,
        orderBy: 'lastName ASC, firstName ASC',
      );
      return rows.map(PersonModel.fromMap).toList();
    } catch (e) {
      debugPrint('[IdentityService.searchPersons] Error: $e');
      return [];
    }
  }

  /// Checks for a possible duplicate person (same firstName + lastName + DOB).
  /// Returns the existing PersonModel if found, or null.
  Future<PersonModel?> checkDuplicate(
      String firstName, String lastName, String dateOfBirth) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        AppConstants.tablePersons,
        where:
            'LOWER(firstName) = ? AND LOWER(lastName) = ? AND dateOfBirth = ?',
        whereArgs: [
          firstName.trim().toLowerCase(),
          lastName.trim().toLowerCase(),
          dateOfBirth,
        ],
        limit: 1,
      );
      return rows.isEmpty ? null : PersonModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[IdentityService.checkDuplicate] Error: $e');
      return null;
    }
  }

  /// Saves a new person record. Returns the saved model.
  Future<PersonModel> createPerson(PersonModel person) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tablePersons, person.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('[IdentityService] Created person: ${person.uniqueId}');
      return person;
    } catch (e) {
      debugPrint('[IdentityService.createPerson] Error: $e');
      rethrow;
    }
  }

  /// Updates an existing person record.
  Future<void> updatePerson(PersonModel person) async {
    try {
      final db = await _db.database;
      await db.update(
        AppConstants.tablePersons,
        person.toMap(),
        where: 'uniqueId = ?',
        whereArgs: [person.uniqueId],
      );
    } catch (e) {
      debugPrint('[IdentityService.updatePerson] Error: $e');
      rethrow;
    }
  }

  /// Marks an existing student as alumni — updates isAlumni and graduationYear in place.
  /// Does NOT create a new record or new ID as per IAM spec.
  Future<void> markAsAlumni(String uniqueId, int graduationYear) async {
    try {
      final db = await _db.database;
      await db.update(
        AppConstants.tablePersons,
        {'isAlumni': 1, 'graduationYear': graduationYear},
        where: 'uniqueId = ?',
        whereArgs: [uniqueId],
      );
      debugPrint(
          '[IdentityService] Marked $uniqueId as alumni (class of $graduationYear)');
    } catch (e) {
      debugPrint('[IdentityService.markAsAlumni] Error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STUDENTS
  // ──────────────────────────────────────────────────────────────────────────

  /// Retrieves student-specific data for a given uniqueId.
  Future<StudentModel?> getStudent(String uniqueId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableStudents,
          where: 'uniqueId = ?', whereArgs: [uniqueId], limit: 1);
      return rows.isEmpty ? null : StudentModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[IdentityService.getStudent] Error: $e');
      return null;
    }
  }

  /// Saves student-specific data.
  Future<void> saveStudent(StudentModel student) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tableStudents, student.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[IdentityService.saveStudent] Error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FACULTY
  // ──────────────────────────────────────────────────────────────────────────

  /// Retrieves faculty-specific data for a given uniqueId.
  Future<FacultyModel?> getFaculty(String uniqueId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableFaculty,
          where: 'uniqueId = ?', whereArgs: [uniqueId], limit: 1);
      return rows.isEmpty ? null : FacultyModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[IdentityService.getFaculty] Error: $e');
      return null;
    }
  }

  /// Saves faculty-specific data.
  Future<void> saveFaculty(FacultyModel faculty) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tableFaculty, faculty.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[IdentityService.saveFaculty] Error: $e');
      rethrow;
    }
  }

  /// Checks if a professor exists in the faculty table.
  /// This validates that the ID starts with FAC and corresponds to a real record.
  Future<bool> checkProfessorExists(String profId) async {
    if (!profId.startsWith('FAC')) return false;
    final prof = await getFaculty(profId);
    return prof != null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STAFF
  // ──────────────────────────────────────────────────────────────────────────

  /// Retrieves staff-specific data for a given uniqueId.
  Future<StaffModel?> getStaff(String uniqueId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableStaff,
          where: 'uniqueId = ?', whereArgs: [uniqueId], limit: 1);
      return rows.isEmpty ? null : StaffModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[IdentityService.getStaff] Error: $e');
      return null;
    }
  }

  /// Saves staff-specific data.
  Future<void> saveStaff(StaffModel staff) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tableStaff, staff.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[IdentityService.saveStaff] Error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CONTRACTORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Retrieves contractor-specific data for a given uniqueId.
  Future<ContractorModel?> getContractor(String uniqueId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(AppConstants.tableContractors,
          where: 'uniqueId = ?', whereArgs: [uniqueId], limit: 1);
      return rows.isEmpty ? null : ContractorModel.fromMap(rows.first);
    } catch (e) {
      debugPrint('[IdentityService.getContractor] Error: $e');
      return null;
    }
  }

  /// Saves contractor-specific data.
  Future<void> saveContractor(ContractorModel contractor) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tableContractors, contractor.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[IdentityService.saveContractor] Error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATUS LIFECYCLE
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns only the valid next statuses for the given current status.
  /// Implements the strict lifecycle engine per IAM spec Section 6.
  static List<String> getAllowedTransitions(String currentStatus) {
    switch (currentStatus) {
      case AppConstants.statusPending:
        return [AppConstants.statusActive];
      case AppConstants.statusActive:
        return [AppConstants.statusSuspended, AppConstants.statusInactive];
      case AppConstants.statusSuspended:
        return [AppConstants.statusActive];
      case AppConstants.statusInactive:
        return [AppConstants.statusArchived]; // filtered further by 5-year rule
      default:
        return [];
    }
  }

  /// Checks whether a person is eligible for Archived status.
  /// Returns null if eligible, or a message with the eligible date if not.
  Future<String?> checkArchiveEligibility(String personId) async {
    try {
      final db = await _db.database;
      // Find the most recent Inactive status change.
      final rows = await db.query(
        AppConstants.tableStatusHistory,
        where: 'personId = ? AND newStatus = ?',
        whereArgs: [personId, AppConstants.statusInactive],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      if (rows.isEmpty) return 'No Inactive record found for this person.';

      final inactiveAt = DateTime.parse(rows.first['timestamp'] as String);
      final eligibleAt = inactiveAt.add(const Duration(days: 365 * 5));
      if (DateTime.now().isBefore(eligibleAt)) {
        final formatted =
            '${eligibleAt.day}/${eligibleAt.month}/${eligibleAt.year}';
        return 'This account cannot be archived yet. Eligible after $formatted.';
      }
      return null; // eligible
    } catch (e) {
      debugPrint('[IdentityService.checkArchiveEligibility] Error: $e');
      return 'Error checking archive eligibility.';
    }
  }

  /// Updates a person's status and writes to statusHistory.
  Future<void> changeStatus({
    required String personId,
    required String oldStatus,
    required String newStatus,
    required String changedBy,
  }) async {
    try {
      final db = await _db.database;
      await db.update(
        AppConstants.tablePersons,
        {'status': newStatus},
        where: 'uniqueId = ?',
        whereArgs: [personId],
      );
      await db.insert(AppConstants.tableStatusHistory, {
        'id': _uuid.v4(),
        'personId': personId,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'changedBy': changedBy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint(
          '[IdentityService] Status changed for $personId: $oldStatus → $newStatus');
    } catch (e) {
      debugPrint('[IdentityService.changeStatus] Error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATUS HISTORY & MODIFICATION LOG
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns all status history records for a person, newest first.
  Future<List<StatusHistoryModel>> getStatusHistory(String personId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        AppConstants.tableStatusHistory,
        where: 'personId = ?',
        whereArgs: [personId],
        orderBy: 'timestamp DESC',
      );
      return rows.map(StatusHistoryModel.fromMap).toList();
    } catch (e) {
      debugPrint('[IdentityService.getStatusHistory] Error: $e');
      return [];
    }
  }

  /// Returns all modification log records for a person, newest first.
  Future<List<ModificationLogModel>> getModificationLog(String personId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        AppConstants.tableModificationLog,
        where: 'personId = ?',
        whereArgs: [personId],
        orderBy: 'timestamp DESC',
      );
      return rows.map(ModificationLogModel.fromMap).toList();
    } catch (e) {
      debugPrint('[IdentityService.getModificationLog] Error: $e');
      return [];
    }
  }

  /// Writes a field-level modification record to the modification_log table.
  Future<void> logModification({
    required String personId,
    required String fieldChanged,
    required String oldValue,
    required String newValue,
    required String changedBy,
  }) async {
    try {
      final db = await _db.database;
      await db.insert(AppConstants.tableModificationLog, {
        'id': _uuid.v4(),
        'personId': personId,
        'fieldChanged': fieldChanged,
        'oldValue': oldValue,
        'newValue': newValue,
        'changedBy': changedBy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[IdentityService.logModification] Error: $e');
    }
  }

  /// Returns the last N combined activity records (status changes + modifications).
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    try {
      final db = await _db.database;
      final statuses = await db.query(
        AppConstants.tableStatusHistory,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      final mods = await db.query(
        AppConstants.tableModificationLog,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      final combined = [
        ...statuses.map((r) => {...r, '_type': 'status'}),
        ...mods.map((r) => {...r, '_type': 'modification'}),
      ];
      combined.sort((a, b) =>
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      return combined.take(limit).toList();
    } catch (e) {
      debugPrint('[IdentityService.getRecentActivity] Error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DASHBOARD STATS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns counts for the dashboard stat cards.
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final db = await _db.database;
      final all = await db.rawQuery(
          'SELECT userType, status FROM ${AppConstants.tablePersons}');

      final studentTypes = {
        AppConstants.typeUndergraduate,
        AppConstants.typeContinuingEducation,
        AppConstants.typePhD,
        AppConstants.typeInternational,
      };
      final facultyTypes = {
        AppConstants.typeTenured,
        AppConstants.typeAdjunct,
        AppConstants.typeVisitingResearcher,
      };
      final staffTypes = {
        AppConstants.typeAdministrativeStaff,
        AppConstants.typeTechnicalStaff,
        AppConstants.typeTemporaryStaff,
        AppConstants.typeITAdmin,
      };

      int total = all.length;
      int students = 0, faculty = 0, staff = 0;
      int active = 0, pending = 0, suspended = 0, inactive = 0;

      for (final row in all) {
        final type = row['userType'] as String;
        final status = row['status'] as String;
        if (studentTypes.contains(type)) students++;
        if (facultyTypes.contains(type)) faculty++;
        if (staffTypes.contains(type)) staff++;
        if (status == AppConstants.statusActive) active++;
        if (status == AppConstants.statusPending) pending++;
        if (status == AppConstants.statusSuspended) suspended++;
        if (status == AppConstants.statusInactive) inactive++;
      }

      return {
        'total': total,
        'students': students,
        'faculty': faculty,
        'staff': staff,
        'active': active,
        'pending': pending,
        'suspended': suspended,
        'inactive': inactive,
      };
    } catch (e) {
      debugPrint('[IdentityService.getDashboardStats] Error: $e');
      return {};
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Maps a type category label to the list of userType strings it covers.
  List<String> _typesForCategory(String category) {
    switch (category) {
      case 'Student':
        return [
          AppConstants.typeUndergraduate,
          AppConstants.typeContinuingEducation,
          AppConstants.typePhD,
          AppConstants.typeInternational
        ];
      case 'Faculty':
        return [
          AppConstants.typeTenured,
          AppConstants.typeAdjunct,
          AppConstants.typeVisitingResearcher
        ];
      case 'Staff':
        return [
          AppConstants.typeAdministrativeStaff,
          AppConstants.typeTechnicalStaff,
          AppConstants.typeTemporaryStaff,
          AppConstants.typeITAdmin
        ];
      case 'Contractor':
        return [AppConstants.typeContractor];
      case 'Alumni':
        return [AppConstants.typeAlumni];
      default:
        return [];
    }
  }
}
