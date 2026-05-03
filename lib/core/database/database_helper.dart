import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../constants/app_constants.dart';

/// Singleton DatabaseHelper — the ONLY class that touches sqflite directly.
/// All other code must go through a service (IdentityService, AuthService, AuditService).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  /// Returns the open database, initializing it on first access.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  /// Initializes sqflite FFI for desktop and opens the database file.
  Future<Database> _initDatabase() async {
    // Use sqflite_common_ffi for Windows/Linux/macOS desktop support.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'iam_university.db');

    debugPrint('[DatabaseHelper] Opening database at: $path');

    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Creates all 15 tables on first run.
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[DatabaseHelper] Creating tables (version $version)...');
    try {
      await db.execute(_sqlPersons);
      await db.execute(_sqlStudents);
      await db.execute(_sqlFaculty);
      await db.execute(_sqlStaff);
      await db.execute(_sqlContractors);
      await db.execute(_sqlAuthCredentials);
      await db.execute(_sqlPasswordHistory);
      await db.execute(_sqlMfaMethods);
      await db.execute(_sqlSessions);
      await db.execute(_sqlLoginAttempts);
      await db.execute(_sqlOtpCodes);
      await db.execute(_sqlResetTokens);
      await db.execute(_sqlPasswordPolicy);
      await db.execute(_sqlStatusHistory);
      await db.execute(_sqlModificationLog);
      debugPrint('[DatabaseHelper] All tables created successfully.');
    } catch (e) {
      debugPrint('[DatabaseHelper] Error creating tables: $e');
      rethrow;
    }
  }

  /// Stub for future schema migrations.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('[DatabaseHelper] Upgrading from v$oldVersion to v$newVersion');
    // Add ALTER TABLE statements here for future versions.
  }

  // ─── DDL Statements ────────────────────────────────────────────────────────

  /// Core identity record for every person in the system.
  static const String _sqlPersons = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tablePersons} (
      uniqueId        TEXT PRIMARY KEY,
      firstName       TEXT NOT NULL,
      lastName        TEXT NOT NULL,
      dateOfBirth     TEXT NOT NULL,
      placeOfBirth    TEXT NOT NULL,
      nationality     TEXT NOT NULL,
      gender          TEXT NOT NULL,
      personalEmail   TEXT NOT NULL UNIQUE,
      phoneNumber     TEXT NOT NULL,
      userType        TEXT NOT NULL,
      status          TEXT NOT NULL DEFAULT 'Pending',
      createdAt       TEXT NOT NULL,
      isAlumni        INTEGER NOT NULL DEFAULT 0,
      graduationYear  INTEGER
    )
  ''';

  /// Additional data for all student subtypes (Undergraduate, ContinuingEd, PhD, International).
  static const String _sqlStudents = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableStudents} (
      uniqueId                TEXT PRIMARY KEY,
      nationalIdNumber        TEXT,
      diplomaType             TEXT,
      diplomaYear             INTEGER,
      diplomaHonors           TEXT,
      chosenMajor             TEXT,
      entryYear               INTEGER,
      faculty                 TEXT,
      department              TEXT,
      grp                     TEXT,
      scholarshipStatus       INTEGER NOT NULL DEFAULT 0,
      supervisingProfessorId  TEXT,
      stayStartDate           TEXT,
      stayEndDate             TEXT
    )
  ''';

  /// Additional data for faculty subtypes (Tenured, Adjunct, VisitingResearcher).
  static const String _sqlFaculty = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableFaculty} (
      uniqueId                TEXT PRIMARY KEY,
      rank                    TEXT,
      employmentCategory      TEXT,
      appointmentStartDate    TEXT,
      primaryDepartment       TEXT,
      secondaryDepartments    TEXT,
      officeBuilding          TEXT,
      officeFloor             TEXT,
      officeRoom              TEXT,
      phdInstitution          TEXT,
      researchAreas           TEXT,
      habilitationToSupervise INTEGER NOT NULL DEFAULT 0,
      contractType            TEXT,
      contractStartDate       TEXT,
      contractEndDate         TEXT,
      teachingHoursPerWeek    INTEGER
    )
  ''';

  /// Additional data for staff subtypes (Administrative, Technical, Temporary).
  static const String _sqlStaff = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableStaff} (
      uniqueId            TEXT PRIMARY KEY,
      assignedDepartment  TEXT,
      jobTitle            TEXT,
      grade               TEXT,
      dateOfEntry         TEXT
    )
  ''';

  /// Additional data for contractors and vendors.
  static const String _sqlContractors = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableContractors} (
      uniqueId          TEXT PRIMARY KEY,
      contractPurpose   TEXT,
      accessExpiryDate  TEXT NOT NULL
    )
  ''';

  /// Authentication credentials — bcrypt hash, lock state, MFA level.
  static const String _sqlAuthCredentials = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableAuthCredentials} (
      personId        TEXT PRIMARY KEY,
      hashedPassword  TEXT NOT NULL,
      salt            TEXT NOT NULL,
      costFactor      INTEGER NOT NULL DEFAULT 12,
      isFirstLogin    INTEGER NOT NULL DEFAULT 1,
      authLevel       TEXT NOT NULL DEFAULT 'L1',
      accountLocked   INTEGER NOT NULL DEFAULT 0,
      lockedUntil     TEXT,
      failedAttempts  INTEGER NOT NULL DEFAULT 0
    )
  ''';

  /// JSON array of last N password hashes per person (for history enforcement).
  static const String _sqlPasswordHistory = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tablePasswordHistory} (
      personId  TEXT PRIMARY KEY,
      hashes    TEXT NOT NULL DEFAULT '[]'
    )
  ''';

  /// MFA configuration: TOTP secret, backup codes, security questions.
  static const String _sqlMfaMethods = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableMfaMethods} (
      personId                  TEXT PRIMARY KEY,
      totpSecret                TEXT,
      totpBackupCodes           TEXT,
      totpBackupCodesUsed       TEXT,
      securityQuestion1         TEXT,
      securityAnswer1Hashed     TEXT,
      securityQuestion2         TEXT,
      securityAnswer2Hashed     TEXT,
      otpEnabled                INTEGER NOT NULL DEFAULT 0,
      totpEnabled               INTEGER NOT NULL DEFAULT 0,
      securityQuestionsEnabled  INTEGER NOT NULL DEFAULT 0
    )
  ''';

  /// Active and historical login sessions.
  static const String _sqlSessions = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableSessions} (
      sessionId       TEXT PRIMARY KEY,
      personId        TEXT NOT NULL,
      authLevel       TEXT NOT NULL,
      createdAt       TEXT NOT NULL,
      ipAddress       TEXT NOT NULL DEFAULT 'local',
      invalidatedAt   TEXT
    )
  ''';

  /// Full audit log of every login attempt (success or failure).
  static const String _sqlLoginAttempts = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableLoginAttempts} (
      id              TEXT PRIMARY KEY,
      timestamp       TEXT NOT NULL,
      personId        TEXT NOT NULL,
      success         INTEGER NOT NULL,
      ipAddress       TEXT NOT NULL DEFAULT 'local',
      mfaUsed         INTEGER NOT NULL DEFAULT 0,
      failureReason   TEXT,
      sessionId       TEXT
    )
  ''';

  /// One-time OTP code per person — rate limited, 5-minute expiry.
  static const String _sqlOtpCodes = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableOtpCodes} (
      personId          TEXT PRIMARY KEY,
      code              TEXT NOT NULL,
      generatedAt       TEXT NOT NULL,
      expiresAt         TEXT NOT NULL,
      used              INTEGER NOT NULL DEFAULT 0,
      requestCount      INTEGER NOT NULL DEFAULT 0,
      hourWindowStart   TEXT NOT NULL
    )
  ''';

  /// UUID-based password reset tokens, single-use, 1-hour expiry.
  static const String _sqlResetTokens = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableResetTokens} (
      token         TEXT PRIMARY KEY,
      personId      TEXT NOT NULL,
      generatedAt   TEXT NOT NULL,
      expiresAt     TEXT NOT NULL,
      used          INTEGER NOT NULL DEFAULT 0
    )
  ''';

  /// Single-row password policy configuration (key = 'policy').
  static const String _sqlPasswordPolicy = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tablePasswordPolicy} (
      id                      TEXT PRIMARY KEY DEFAULT 'policy',
      minLength               INTEGER NOT NULL DEFAULT 8,
      maxLength               INTEGER NOT NULL DEFAULT 64,
      minCategories           INTEGER NOT NULL DEFAULT 3,
      historyCount            INTEGER NOT NULL DEFAULT 5,
      maxFailedAttempts       INTEGER NOT NULL DEFAULT 5,
      lockoutDurationMinutes  INTEGER NOT NULL DEFAULT 30
    )
  ''';

  /// History of every status transition for every person.
  static const String _sqlStatusHistory = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableStatusHistory} (
      id          TEXT PRIMARY KEY,
      personId    TEXT NOT NULL,
      oldStatus   TEXT,
      newStatus   TEXT NOT NULL,
      changedBy   TEXT NOT NULL,
      timestamp   TEXT NOT NULL
    )
  ''';

  /// Log of every field-level modification to any person record.
  static const String _sqlModificationLog = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableModificationLog} (
      id            TEXT PRIMARY KEY,
      personId      TEXT NOT NULL,
      fieldChanged  TEXT NOT NULL,
      oldValue      TEXT NOT NULL,
      newValue      TEXT NOT NULL,
      changedBy     TEXT NOT NULL,
      timestamp     TEXT NOT NULL
    )
  ''';
}
