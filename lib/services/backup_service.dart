import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

class BackupSnapshot {
  const BackupSnapshot({
    required this.schemaVersion,
    required this.createdAt,
    required this.tables,
  });

  final int schemaVersion;
  final String createdAt;
  final Map<String, List<Map<String, dynamic>>> tables;

  int get totalRows =>
      tables.values.fold(0, (total, rows) => total + rows.length);

  Map<String, dynamic> toMap() {
    return {
      'schema_version': schemaVersion,
      'created_at': createdAt,
      'tables': tables,
    };
  }

  static BackupSnapshot fromMap(Map<String, dynamic> raw) {
    final tablesRaw = raw['tables'];
    if (tablesRaw is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup format: missing tables.');
    }

    return BackupSnapshot(
      schemaVersion: (raw['schema_version'] as int?) ?? 0,
      createdAt: raw['created_at'] as String? ?? '',
      tables: tablesRaw.map(
        (key, value) => MapEntry(key, _normalizeRows(key, value)),
      ),
    );
  }

  static List<Map<String, dynamic>> _normalizeRows(String table, Object? rows) {
    if (rows == null) {
      return const <Map<String, dynamic>>[];
    }
    if (rows is! List) {
      throw FormatException('Invalid backup format for table $table.');
    }

    final normalized = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (row is! Map) {
        throw FormatException('Invalid row in backup table $table.');
      }
      normalized.add(row.map((key, value) => MapEntry(key.toString(), value)));
    }
    return normalized;
  }
}

class RestoreSummary {
  const RestoreSummary({
    required this.tablesRestored,
    required this.rowsRestored,
  });

  final int tablesRestored;
  final int rowsRestored;
}

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const List<String> _backupTables = <String>[
    'chw_profiles',
    'workspace_facilities',
    'facility_memberships',
    'campaigns',
    'patients',
    'screenings',
    'sync_queue',
  ];

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<BackupSnapshot> createWorkspaceSnapshot() async {
    final database = await _db.db;
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in _backupTables) {
      tables[table] = await database.query(table);
    }

    return BackupSnapshot(
      schemaVersion: await database.getVersion(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
      tables: tables,
    );
  }

  Future<RestoreSummary> restoreWorkspaceSnapshot(
    Map<String, dynamic> rawSnapshot,
  ) async {
    final snapshot = BackupSnapshot.fromMap(rawSnapshot);
    final database = await _db.db;
    var tablesRestored = 0;
    var rowsRestored = 0;

    await database.transaction((txn) async {
      await _db.clearRestorableData(database: txn);

      for (final table in _backupTables) {
        final rows = snapshot.tables[table] ?? const <Map<String, dynamic>>[];
        await _restoreTable(
          txn,
          table,
          rows,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        tablesRestored++;
        rowsRestored += rows.length;
      }
    });

    return RestoreSummary(
      tablesRestored: tablesRestored,
      rowsRestored: rowsRestored,
    );
  }

  Future<void> _restoreTable(
    DatabaseExecutor database,
    String table,
    List<Map<String, dynamic>> rows, {
    required ConflictAlgorithm conflictAlgorithm,
  }) async {
    for (final row in rows) {
      await database.insert(table, row, conflictAlgorithm: conflictAlgorithm);
    }
  }
}
