import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/password_utils.dart';
import '../../models/auth_credentials_model.dart';
import '../../models/password_policy_model.dart';
import '../../models/person_model.dart';
import 'audit_service.dart';
import 'auth_service.dart';
import 'identity_service.dart';

/// Clears all demo data and restores only the two default seeded accounts.
class DemoResetService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final IdentityService _identityService = IdentityService();
  final AuthService _authService = AuthService();
  final AuditService _auditService = AuditService();

  Future<void> resetAndReseedDefaults() async {
    await _wipeAllTables();
    await _seedDefaultAccounts();
  }

  Future<void> _wipeAllTables() async {
    final db = await _db.database;

    final tables = <String>[
      AppConstants.tableStudents,
      AppConstants.tableFaculty,
      AppConstants.tableStaff,
      AppConstants.tableContractors,
      AppConstants.tableMfaMethods,
      AppConstants.tableSessions,
      AppConstants.tableLoginAttempts,
      AppConstants.tableOtpCodes,
      AppConstants.tableResetTokens,
      AppConstants.tablePasswordHistory,
      AppConstants.tableStatusHistory,
      AppConstants.tableModificationLog,
      AppConstants.tableAuthCredentials,
      AppConstants.tablePersons,
      AppConstants.tablePasswordPolicy,
    ];

    await db.transaction((txn) async {
      for (final table in tables) {
        await txn.delete(table);
      }
    });
  }

  Future<void> _seedDefaultAccounts() async {
    final now = DateTime.now().toUtc().toIso8601String();

    const adminId = 'STF202400001';
    final adminPerson = PersonModel(
      uniqueId: adminId,
      firstName: 'Admin',
      lastName: 'System',
      dateOfBirth: '1990-01-01',
      placeOfBirth: 'Batna',
      nationality: 'Algerian',
      gender: 'Male',
      personalEmail: 'soulimanbenali123@gmail.com',
      phoneNumber: '0000000000',
      userType: AppConstants.typeITAdmin,
      status: AppConstants.statusActive,
      createdAt: now,
      isAlumni: false,
    );

    const staffId = 'STF202400002';
    final staffPerson = PersonModel(
      uniqueId: staffId,
      firstName: 'Staff',
      lastName: 'Admin',
      dateOfBirth: '1990-01-01',
      placeOfBirth: 'Batna',
      nationality: 'Algerian',
      gender: 'Female',
      personalEmail: 'fethibensassi04@gmail.com',
      phoneNumber: '0000000001',
      userType: AppConstants.typeAdministrativeStaff,
      status: AppConstants.statusActive,
      createdAt: now,
      isAlumni: false,
    );

    final adminHash = await PasswordUtils.hashPassword('Admin@1234');
    final adminCreds = AuthCredentialsModel(
      personId: adminId,
      hashedPassword: adminHash,
      salt: BCrypt.gensalt(logRounds: 12),
      costFactor: 12,
      isFirstLogin: true,
      authLevel: AppConstants.authLevelL4,
      accountLocked: false,
      failedAttempts: 0,
    );

    final staffHash = await PasswordUtils.hashPassword('Staff@1234');
    final staffCreds = AuthCredentialsModel(
      personId: staffId,
      hashedPassword: staffHash,
      salt: BCrypt.gensalt(logRounds: 12),
      costFactor: 12,
      isFirstLogin: false,
      authLevel: AppConstants.authLevelL2,
      accountLocked: false,
      failedAttempts: 0,
    );

    await _identityService.createPerson(adminPerson);
    await _authService.createCredentials(adminCreds);
    await _forceNonFirstLogin(adminId);
    await _auditService.recordStatusChange(
      personId: adminId,
      oldStatus: null,
      newStatus: AppConstants.statusActive,
      changedBy: 'system',
    );

    await _identityService.createPerson(staffPerson);
    await _authService.createCredentials(staffCreds);
    await _forceNonFirstLogin(staffId);
    await _auditService.recordStatusChange(
      personId: staffId,
      oldStatus: null,
      newStatus: AppConstants.statusActive,
      changedBy: 'system',
    );

    await _authService.savePasswordPolicy(const PasswordPolicyModel());

    debugPrint('[DemoResetService] Demo data reset complete.');
  }

  Future<void> _forceNonFirstLogin(String personId) async {
    final creds = await _authService.getCredentials(personId);
    if (creds == null || !creds.isFirstLogin) return;
    await _authService.updateCredentials(creds.copyWith(isFirstLogin: false));
  }
}
