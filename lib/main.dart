import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bcrypt/bcrypt.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/constants/app_constants.dart';
import 'models/person_model.dart';
import 'models/auth_credentials_model.dart';
import 'models/password_policy_model.dart';
import 'services/identity_service.dart';
import 'services/auth_service.dart';
import 'services/audit_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for desktop (Windows/Linux/macOS).
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Open the database and create all tables.
  try {
    await DatabaseHelper.instance.database;
    debugPrint('[main] Database initialized successfully.');
  } catch (e) {
    debugPrint('[main] FATAL: Could not initialize database: $e');
  }

  // Seed default data if the system is empty.
  try {
    await _seedDefaultData();
  } catch (e) {
    debugPrint('[main] Seed error: $e');
  }

  runApp(const ProviderScope(child: IamApp()));
}

/// Seeds the default IT Admin, Admin Staff accounts, and password policy
/// on first run when the persons table is empty.
Future<void> _seedDefaultData() async {
  final identityService = IdentityService();
  final authService = AuthService();
  final auditService = AuditService();

  final existing = await identityService.getAllPersons();
  if (existing.isNotEmpty) {
    await _ensureSeededAccountsCanLogIn(authService);
    debugPrint('[main] Database already has data. Skipping seed.');
    return;
  }

  debugPrint('[main] Seeding default accounts...');
  final now = DateTime.now().toUtc().toIso8601String();

  // ─── 1. Default IT Admin ───────────────────────────────────────────────────
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

  final adminHash = await _hashInIsolate('Admin@1234');
  final adminCreds = AuthCredentialsModel(
    personId: adminId,
    hashedPassword: adminHash,
    salt: BCrypt.gensalt(logRounds: 12),
    costFactor: 12,
    isFirstLogin: false,
    authLevel: AppConstants.authLevelL4,
    accountLocked: false,
    failedAttempts: 0,
  );

  await identityService.createPerson(adminPerson);
  await authService.createCredentials(adminCreds);
  await auditService.recordStatusChange(
    personId: adminId,
    oldStatus: null,
    newStatus: AppConstants.statusActive,
    changedBy: 'system',
  );

  // ─── 2. Default Admin Staff ────────────────────────────────────────────────
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

  final staffHash = await _hashInIsolate('Staff@1234');
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

  await identityService.createPerson(staffPerson);
  await authService.createCredentials(staffCreds);
  await auditService.recordStatusChange(
    personId: staffId,
    oldStatus: null,
    newStatus: AppConstants.statusActive,
    changedBy: 'system',
  );

  // ─── 3. Default Password Policy ───────────────────────────────────────────
  await authService.savePasswordPolicy(const PasswordPolicyModel());

  debugPrint('[main] ══════════════════════════════════════════════');
  debugPrint('[main] DEFAULT ACCOUNTS CREATED:');
  debugPrint('[main]   IT Admin:    $adminId / Admin@1234');
  debugPrint('[main]   Admin Staff: $staffId / Staff@1234');
  debugPrint('[main] ══════════════════════════════════════════════');
}

/// Clears the first-login flag for bundled seed accounts already in the database.
Future<void> _ensureSeededAccountsCanLogIn(AuthService authService) async {
  const seededAccountIds = <String>[
    'STF202400001',
    'STF202400002',
  ];

  for (final personId in seededAccountIds) {
    final creds = await authService.getCredentials(personId);
    if (creds == null || !creds.isFirstLogin) continue;

    await authService.updateCredentials(creds.copyWith(isFirstLogin: false));
    debugPrint('[main] Cleared first-login flag for $personId.');
  }
}

/// Hashes a password with bcrypt in an isolate (cost factor 12).
Future<String> _hashInIsolate(String plain) async {
  return compute(_bcryptHash, plain);
}

/// Top-level function for compute() — bcrypt must run in isolate on desktop.
String _bcryptHash(String plain) {
  final salt = BCrypt.gensalt(logRounds: 12);
  return BCrypt.hashpw(plain, salt);
}
