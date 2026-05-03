import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;

  // Use the same logic as the app to find the db path
  // Wait, in flutter sqflite on Windows, getDatabasesPath() returns Documents folder or AppData.
  // We can just use the standard getDatabasesPath() via FFI.
  final dbPath = await databaseFactory.getDatabasesPath();
  final path = join(dbPath, 'iam_university.db');

  stdout.writeln('Database path: $path');
  stdout.writeln('File exists: ${File(path).existsSync()}');

  if (!File(path).existsSync()) {
    stdout.writeln('Database not found!');
    return;
  }

  var db = await databaseFactory.openDatabase(path);

  var persons = await db.query('persons');
  stdout.writeln('Persons count: ${persons.length}');
  for (var p in persons) {
    stdout.writeln(
        'Person: ${p["uniqueId"]} | ${p["personalEmail"]} | ${p["userType"]}');
  }

  var creds = await db.query('auth_credentials');
  stdout.writeln('Credentials count: ${creds.length}');
  for (var c in creds) {
    stdout.writeln(
        'Cred: ${c["personId"]} | FirstLogin: ${c["isFirstLogin"]} | AuthLevel: ${c["authLevel"]} | Locked: ${c["accountLocked"]} | Failed: ${c["failedAttempts"]}');

    // Check password
    if (c['personId'] == 'STF202400001') {
      try {
        final hash = c['hashedPassword'] as String;
        final ok = BCrypt.checkpw('Admin@1234', hash);
        stdout.writeln('Password check for Admin@1234: $ok');
      } catch (e) {
        stdout.writeln('Bcrypt check error: $e');
      }
    }
  }

  await db.close();
}
