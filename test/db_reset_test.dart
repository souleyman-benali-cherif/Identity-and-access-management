import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  test('Reset database', () async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'iam_university.db');

    stdout.writeln('DB Path: $path');

    if (File(path).existsSync()) {
      stdout.writeln('Deleting existing database...');
      await databaseFactory.deleteDatabase(path);
      stdout.writeln('Deleted.');
    } else {
      stdout.writeln('Database does not exist.');
    }
  });
}
