import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../models/login_attempt_model.dart';

/// Service for all audit logging operations.
/// Logs every critical action: login attempts, status changes, profile modifications.
class AuditService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ──────────────────────────────────────────────────────────────────────────
  // LOGIN ATTEMPTS
  // ──────────────────────────────────────────────────────────────────────────

  /// Logs a login attempt (success or failure) with all required metadata.
  Future<void> logLoginAttempt({
    required String personId,
    required bool success,
    bool mfaUsed = false,
    String? failureReason,
    String? sessionId,
  }) async {
    try {
      final db = await _db.database;
      await db.insert(
          AppConstants.tableLoginAttempts,
          {
            'id': _uuid.v4(),
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'personId': personId,
            'success': success ? 1 : 0,
            'ipAddress': 'local',
            'mfaUsed': mfaUsed ? 1 : 0,
            'failureReason': failureReason,
            'sessionId': sessionId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[AuditService.logLoginAttempt] Error: $e');
    }
  }

  /// Returns the last N login attempts for a person, newest first.
  Future<List<LoginAttemptModel>> getLoginAttempts(String personId,
      {int limit = 20}) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        AppConstants.tableLoginAttempts,
        where: 'personId = ?',
        whereArgs: [personId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return rows.map(LoginAttemptModel.fromMap).toList();
    } catch (e) {
      debugPrint('[AuditService.getLoginAttempts] Error: $e');
      return [];
    }
  }

  /// Returns the last N login attempts for all users (IT Admin dashboard).
  Future<List<LoginAttemptModel>> getAllRecentAttempts({int limit = 10}) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        AppConstants.tableLoginAttempts,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return rows.map(LoginAttemptModel.fromMap).toList();
    } catch (e) {
      debugPrint('[AuditService.getAllRecentAttempts] Error: $e');
      return [];
    }
  }

  /// Returns login attempts filtered by date range and/or result.
  Future<List<LoginAttemptModel>> getFilteredAttempts({
    String? personId,
    DateTime? from,
    DateTime? to,
    bool? successOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _db.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (personId != null) {
        conditions.add('personId = ?');
        args.add(personId);
      }
      if (from != null) {
        conditions.add('timestamp >= ?');
        args.add(from.toUtc().toIso8601String());
      }
      if (to != null) {
        conditions.add('timestamp <= ?');
        args.add(to.toUtc().toIso8601String());
      }
      if (successOnly != null) {
        conditions.add('success = ?');
        args.add(successOnly ? 1 : 0);
      }

      final where = conditions.isEmpty ? null : conditions.join(' AND ');
      final rows = await db.query(
        AppConstants.tableLoginAttempts,
        where: where,
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(LoginAttemptModel.fromMap).toList();
    } catch (e) {
      debugPrint('[AuditService.getFilteredAttempts] Error: $e');
      return [];
    }
  }

  /// Returns the timestamp of the last successful login for a person.
  Future<String?> getLastLoginTimestamp(String personId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        AppConstants.tableLoginAttempts,
        where: 'personId = ? AND success = 1',
        whereArgs: [personId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first['timestamp'] as String?;
    } catch (e) {
      debugPrint('[AuditService.getLastLoginTimestamp] Error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATUS HISTORY
  // ──────────────────────────────────────────────────────────────────────────

  /// Records a status change in the status_history table.
  Future<void> recordStatusChange({
    required String personId,
    required String? oldStatus,
    required String newStatus,
    required String changedBy,
  }) async {
    try {
      final db = await _db.database;
      await db.insert(
          AppConstants.tableStatusHistory,
          {
            'id': _uuid.v4(),
            'personId': personId,
            'oldStatus': oldStatus,
            'newStatus': newStatus,
            'changedBy': changedBy,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[AuditService.recordStatusChange] Error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MODIFICATION LOG
  // ──────────────────────────────────────────────────────────────────────────

  /// Records a field-level profile modification.
  Future<void> recordModification({
    required String personId,
    required String fieldChanged,
    required String oldValue,
    required String newValue,
    required String changedBy,
  }) async {
    try {
      final db = await _db.database;
      await db.insert(
          AppConstants.tableModificationLog,
          {
            'id': _uuid.v4(),
            'personId': personId,
            'fieldChanged': fieldChanged,
            'oldValue': oldValue,
            'newValue': newValue,
            'changedBy': changedBy,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[AuditService.recordModification] Error: $e');
    }
  }
}
