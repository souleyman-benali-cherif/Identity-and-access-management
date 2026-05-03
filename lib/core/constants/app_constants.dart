/// Application-wide constants for table names, default policy values, and prefix maps.
class AppConstants {
  AppConstants._();

  // ─── SQL Table Names ───────────────────────────────────────────────────────
  static const String tablePersons         = 'persons';
  static const String tableStudents        = 'students';
  static const String tableFaculty         = 'faculty_members';
  static const String tableStaff           = 'staff_members';
  static const String tableContractors     = 'contractors';
  static const String tableAuthCredentials = 'auth_credentials';
  static const String tablePasswordHistory = 'password_history';
  static const String tableMfaMethods      = 'mfa_methods';
  static const String tableSessions        = 'sessions';
  static const String tableLoginAttempts   = 'login_attempts';
  static const String tableOtpCodes        = 'otp_codes';
  static const String tableResetTokens     = 'reset_tokens';
  static const String tablePasswordPolicy  = 'password_policy';
  static const String tableStatusHistory   = 'status_history';
  static const String tableModificationLog = 'modification_log';

  // ─── Password Policy Defaults ──────────────────────────────────────────────
  static const int defaultMinLength             = 8;
  static const int defaultMaxLength             = 64;
  static const int defaultMinCategories         = 3;
  static const int defaultHistoryCount          = 5;
  static const int defaultMaxFailedAttempts     = 5;
  static const int defaultLockoutDurationMinutes = 30;

  // ─── Auth Levels ───────────────────────────────────────────────────────────
  static const String authLevelL1 = 'L1';
  static const String authLevelL2 = 'L2';
  static const String authLevelL3 = 'L3';
  static const String authLevelL4 = 'L4';

  // ─── User Types ────────────────────────────────────────────────────────────
  static const String typeUndergraduate       = 'Undergraduate';
  static const String typeContinuingEducation = 'ContinuingEducation';
  static const String typePhD                 = 'PhD';
  static const String typeInternational       = 'International';
  static const String typeTenured             = 'Tenured';
  static const String typeAdjunct             = 'Adjunct';
  static const String typeVisitingResearcher  = 'VisitingResearcher';
  static const String typeAdministrativeStaff = 'AdministrativeStaff';
  static const String typeTechnicalStaff      = 'TechnicalStaff';
  static const String typeTemporaryStaff      = 'TemporaryStaff';
  static const String typeContractor          = 'Contractor';
  static const String typeAlumni              = 'Alumni';
  static const String typeITAdmin             = 'ITAdmin';

  // ─── Status Values ─────────────────────────────────────────────────────────
  static const String statusPending   = 'Pending';
  static const String statusActive    = 'Active';
  static const String statusSuspended = 'Suspended';
  static const String statusInactive  = 'Inactive';
  static const String statusArchived  = 'Archived';

  // ─── Diploma Honors ────────────────────────────────────────────────────────
  static const List<String> diplomaHonors = ['None', 'Good', 'Very Good', 'Excellent'];

  // ─── Faculty Ranks ─────────────────────────────────────────────────────────
  static const List<String> facultyRanks = [
    'Professor',
    'Associate Professor',
    'Assistant Professor',
    'Lecturer',
    'Teaching Assistant',
  ];

  // ─── Contract Types ────────────────────────────────────────────────────────
  static const List<String> contractTypes = ['Permanent', 'Fixed-term', 'Hourly'];

  // ─── Security Questions Pool ───────────────────────────────────────────────
  static const List<String> securityQuestions = [
    "What was your first pet's name?",
    "In which city were you born?",
    "What was your childhood nickname?",
  ];

  // ─── ID Prefix Map ─────────────────────────────────────────────────────────
  /// Returns the ID prefix for a given userType.
  static String idPrefix(String userType) {
    switch (userType) {
      case typeUndergraduate:
      case typeContinuingEducation:
      case typeInternational:
        return 'STU';
      case typePhD:
        return 'PHD';
      case typeTenured:
      case typeAdjunct:
      case typeVisitingResearcher:
        return 'FAC';
      case typeAdministrativeStaff:
      case typeTechnicalStaff:
      case typeITAdmin:
        return 'STF';
      case typeTemporaryStaff:
      case typeContractor:
        return 'TMP';
      default:
        return 'USR';
    }
  }

  // ─── Default Auth Level by User Type ───────────────────────────────────────
  /// Returns the default auth level string for a given userType.
  static String defaultAuthLevel(String userType) {
    switch (userType) {
      case typeUndergraduate:
      case typeContinuingEducation:
      case typePhD:
      case typeContractor:
      case typeAlumni:
        return authLevelL1;
      case typeInternational:
      case typeTenured:
      case typeAdjunct:
      case typeVisitingResearcher:
      case typeAdministrativeStaff:
      case typeTechnicalStaff:
      case typeTemporaryStaff:
        return authLevelL2;
      case typeITAdmin:
        return authLevelL4;
      default:
        return authLevelL1;
    }
  }
}
