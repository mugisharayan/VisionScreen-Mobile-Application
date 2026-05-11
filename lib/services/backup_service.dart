import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<String> exportJsonBackup() async {
    final database = await _db.db;
    final payload = <String, dynamic>{
      'schema_version': await database.getVersion(),
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'tables': {
        'chw_profiles': await database.query('chw_profiles'),
        'workspace_facilities': await database.query('workspace_facilities'),
        'facility_memberships': await database.query('facility_memberships'),
        'campaigns': await database.query('campaigns'),
        'patients': await database.query('patients'),
        'screenings': await database.query('screenings'),
      },
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/visionscreen-backup-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file.path;
  }

  Future<void> restoreJsonBackup(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Backup file not found: $path');
    }

    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final tables = raw['tables'];
    if (tables is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup format');
    }

    final database = await _db.db;
    await database.transaction((txn) async {
      await _db.clearWorkspaceData(database: txn);

      await _restoreTable(
        txn,
        'workspace_facilities',
        tables['workspace_facilities'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _restoreTable(
        txn,
        'facility_memberships',
        tables['facility_memberships'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _restoreTable(
        txn,
        'chw_profiles',
        tables['chw_profiles'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _restoreTable(
        txn,
        'campaigns',
        tables['campaigns'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _restoreTable(
        txn,
        'patients',
        tables['patients'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _restoreTable(
        txn,
        'screenings',
        tables['screenings'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> _restoreTable(
    DatabaseExecutor database,
    String table,
    Object? rows, {
    required ConflictAlgorithm conflictAlgorithm,
  }) async {
    if (rows is! List) return;
    for (final row in rows) {
      if (row is! Map) continue;
      await database.insert(
        table,
        row.map((key, value) => MapEntry(key.toString(), value)),
        conflictAlgorithm: conflictAlgorithm,
      );
    }
  }
}
