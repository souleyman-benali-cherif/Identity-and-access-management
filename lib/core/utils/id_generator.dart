import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';

/// Generates unique IDs in the format [PREFIX][YEAR][5-DIGIT-NUMBER].
/// Example: STU202400043
class IdGenerator {
  IdGenerator._();

  /// Generates the next unique ID for the given userType and year.
  /// Queries the persons table for existing IDs with the same prefix+year,
  /// finds the maximum suffix, increments by 1, and pads to 5 digits.
  static Future<String> generateUniqueId(String userType, int year) async {
    try {
      final prefix = AppConstants.idPrefix(userType);
      final yearStr = year.toString();
      final pattern = '$prefix$yearStr%';

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        AppConstants.tablePersons,
        columns: ['uniqueId'],
        where: 'uniqueId LIKE ?',
        whereArgs: [pattern],
      );

      int maxSuffix = 0;
      for (final row in rows) {
        final id = row['uniqueId'] as String;
        final suffixStr = id.substring(prefix.length + yearStr.length);
        final suffix = int.tryParse(suffixStr) ?? 0;
        if (suffix > maxSuffix) maxSuffix = suffix;
      }

      final nextSuffix = (maxSuffix + 1).toString().padLeft(5, '0');
      final newId = '$prefix$yearStr$nextSuffix';
      debugPrint('[IdGenerator] Generated ID: $newId');
      return newId;
    } catch (e) {
      debugPrint('[IdGenerator.generateUniqueId] Error: $e');
      rethrow;
    }
  }
}
