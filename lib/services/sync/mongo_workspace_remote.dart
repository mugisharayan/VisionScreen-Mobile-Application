import 'package:mongo_dart/mongo_dart.dart';

import '../../utils/app_constants.dart';
import '../../utils/id_utils.dart';

class MongoWorkspaceRemote {
  MongoWorkspaceRemote._();

  static final MongoWorkspaceRemote instance = MongoWorkspaceRemote._();

  static const String _uri = String.fromEnvironment(
    'VS_MONGODB_URI',
    defaultValue:
        'mongodb+srv://blaketucker216_db_user:FeZWB2GAwJYPNw5g@cluster0.ou7k4f2.mongodb.net/visionscreen?retryWrites=true&w=majority',
  );
  static const String _host = String.fromEnvironment('VS_MONGODB_HOST');
  static const String _user = String.fromEnvironment('VS_MONGODB_USER');
  static const String _password = String.fromEnvironment('VS_MONGODB_PASSWORD');
  static const String _dbName = String.fromEnvironment(
    'VS_MONGODB_DB',
    defaultValue: 'visionscreen',
  );
  static const List<Duration> _connectRetryDelays = <Duration>[
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  Db? _db;

  bool get isConfigured => _effectiveUri != null;

  Future<Map<String, dynamic>?> fetchUserByEmail(String email) async {
    await ensureConnected();
    final doc = await _collection('chw_users').findOne(where.eq('_id', email));
    return _normalizeDoc(doc);
  }

  Future<void> upsertFacility(Map<String, dynamic> facility) async {
    await ensureConnected();
    await _upsertDocument('facilities', facility['id'] as String, facility);
  }

  Future<void> upsertMembership(Map<String, dynamic> membership) async {
    await ensureConnected();
    await _upsertDocument(
      'facility_memberships',
      membership['id'] as String,
      membership,
    );
  }

  Future<void> upsertUser(Map<String, dynamic> profile) async {
    await ensureConnected();
    final payload = Map<String, dynamic>.from(profile)
      ..remove('id')
      ..['_id'] = profile['email'];
    await _collection(
      'chw_users',
    ).replaceOne(where.eq('_id', profile['email']), payload, upsert: true);
  }

  Future<Map<String, dynamic>> pushQueuedChange({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await ensureConnected();
    final collectionName = _collectionName(entityType);
    final collection = _collection(collectionName);
    final remote = await collection.findOne(where.eq('_id', entityId));
    final remoteNormalized = _normalizeDoc(remote);
    final localUpdatedAt = payload['updated_at'] as String? ?? '';
    final remoteUpdatedAt = remoteNormalized?['updated_at'] as String? ?? '';

    if (remoteNormalized != null &&
        remoteUpdatedAt.isNotEmpty &&
        localUpdatedAt.isNotEmpty &&
        remoteUpdatedAt.compareTo(localUpdatedAt) > 0) {
      return {'applied': false, 'conflict': true, 'remote': remoteNormalized};
    }

    final outgoing = Map<String, dynamic>.from(payload)..['_id'] = entityId;
    if (entityType == AppStrings.entityScreening) {
      outgoing.remove('id');
    }
    outgoing['sync_state'] = AppStrings.syncSynced;

    await collection.replaceOne(
      where.eq('_id', entityId),
      outgoing,
      upsert: true,
    );

    return {
      'applied': true,
      'conflict': false,
      'remote': _normalizeDoc(
        await collection.findOne(where.eq('_id', entityId)),
      ),
    };
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchWorkspaceData({
    required String facilityId,
  }) async {
    await ensureConnected();
    final facility = _normalizeDoc(
      await _collection('facilities').findOne(where.eq('_id', facilityId)),
    );
    final memberships = await _findAll(
      'facility_memberships',
      where.eq('facility_id', facilityId),
    );
    final patients = await _findAll(
      'patients',
      where.eq('facility_id', facilityId),
    );
    final campaigns = await _findAll(
      'campaigns',
      where.eq('facility_id', facilityId),
    );
    final screenings = await _findAll(
      'screenings',
      where.eq('facility_id', facilityId),
    );

    return {
      'facilities': facility == null ? const [] : [facility],
      'memberships': memberships,
      'patients': patients,
      'campaigns': campaigns,
      'screenings': screenings,
    };
  }

  Future<Map<String, dynamic>> saveWorkspaceBackup({
    required String facilityId,
    required String createdBy,
    required Map<String, dynamic> snapshot,
  }) async {
    await ensureConnected();
    final backupId = IdUtils.generate('backup');
    final createdAt =
        snapshot['created_at'] as String? ??
        DateTime.now().toUtc().toIso8601String();
    final payload = Map<String, dynamic>.from(snapshot)
      ..['_id'] = backupId
      ..['facility_id'] = facilityId
      ..['created_by'] = createdBy
      ..['created_at'] = createdAt
      ..['total_rows'] = _countRows(snapshot['tables'])
      ..['table_counts'] = _tableCounts(snapshot['tables']);

    await _collection('workspace_backups').insertOne(payload);
    await _trimWorkspaceBackups(facilityId);

    return _normalizeDoc(payload)!;
  }

  Future<Map<String, dynamic>?> fetchLatestWorkspaceBackup({
    required String facilityId,
  }) async {
    await ensureConnected();
    final docs = await _collection('workspace_backups')
        .find(
          where
              .eq('facility_id', facilityId)
              .sortBy('created_at', descending: true),
        )
        .take(1)
        .toList();
    if (docs.isEmpty) {
      return null;
    }
    return _normalizeDoc(docs.first);
  }

  Future<void> _trimWorkspaceBackups(String facilityId) async {
    final docs = await _collection('workspace_backups')
        .find(
          where
              .eq('facility_id', facilityId)
              .sortBy('created_at', descending: true),
        )
        .skip(10)
        .toList();
    for (final doc in docs) {
      final id = doc['_id'];
      if (id != null) {
        await _collection('workspace_backups').deleteOne(where.eq('_id', id));
      }
    }
  }

  Future<void> _upsertDocument(
    String collectionName,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final doc = Map<String, dynamic>.from(payload)
      ..remove('id')
      ..['_id'] = id;
    await _collection(
      collectionName,
    ).replaceOne(where.eq('_id', id), doc, upsert: true);
  }

  Future<List<Map<String, dynamic>>> _findAll(
    String collectionName,
    SelectorBuilder selector,
  ) async {
    final docs = await _collection(collectionName).find(selector).toList();
    return docs.map(_normalizeDoc).whereType<Map<String, dynamic>>().toList();
  }

  DbCollection _collection(String name) {
    if (!isConfigured) {
      throw StateError(
        'MongoDB sync is not configured. Provide VS_MONGODB_URI or VS_MONGODB_HOST/USER/PASSWORD.',
      );
    }
    return _dbSync().collection(name);
  }

  Db _dbSync() {
    final db = _db;
    if (db == null || !db.isConnected) {
      throw StateError('MongoDB connection has not been opened.');
    }
    return db;
  }

  Future<void> ensureConnected() async {
    final effectiveUri = _effectiveUri;
    if (effectiveUri == null) {
      return;
    }
    if (_db != null && _db!.isConnected) {
      return;
    }
    Object? lastError;
    for (final delay in _connectRetryDelays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      try {
        final db = await Db.create(effectiveUri);
        await db.open();
        _db = db;
        return;
      } catch (error) {
        lastError = error;
        if (_db?.isConnected ?? false) {
          await _db!.close();
        }
        _db = null;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
  }

  Map<String, dynamic>? _normalizeDoc(Map<String, dynamic>? doc) {
    if (doc == null) {
      return null;
    }
    final normalized = Map<String, dynamic>.from(doc);
    final remoteId = normalized.remove('_id');
    if (remoteId != null) {
      normalized['remote_id'] = remoteId.toString();
      if (!normalized.containsKey('id') &&
          !normalized.containsKey('record_id') &&
          !normalized.containsKey('email')) {
        normalized['id'] = remoteId.toString();
      }
    }
    return normalized;
  }

  String _collectionName(String entityType) {
    switch (entityType) {
      case AppStrings.entityPatient:
        return 'patients';
      case AppStrings.entityCampaign:
        return 'campaigns';
      case AppStrings.entityScreening:
        return 'screenings';
      case AppStrings.entityChwProfile:
        return 'chw_users';
      case AppStrings.entityFacility:
        return 'facilities';
      case AppStrings.entityMembership:
        return 'facility_memberships';
      default:
        throw ArgumentError('Unsupported sync entity: $entityType');
    }
  }

  String? get _effectiveUri {
    if (_uri.isNotEmpty) {
      return _withDatabasePath(_uri);
    }
    if (_host.isEmpty || _user.isEmpty || _password.isEmpty) {
      return null;
    }
    final credentials =
        '${Uri.encodeComponent(_user)}:${Uri.encodeComponent(_password)}';
    final uri =
        'mongodb+srv://$credentials@$_host/$_dbName?retryWrites=true&w=majority';
    return _withDatabasePath(uri);
  }

  String _withDatabasePath(String uri) {
    final parsed = Uri.parse(uri);
    if (parsed.pathSegments.isNotEmpty &&
        parsed.pathSegments.first.isNotEmpty) {
      return uri;
    }
    return parsed.replace(path: '/$_dbName').toString();
  }

  int _countRows(Object? tables) {
    if (tables is! Map<String, dynamic>) {
      return 0;
    }
    return tables.values.fold<int>(0, (total, rows) {
      if (rows is! List) {
        return total;
      }
      return total + rows.length;
    });
  }

  Map<String, int> _tableCounts(Object? tables) {
    if (tables is! Map<String, dynamic>) {
      return const <String, int>{};
    }
    return tables.map((key, rows) {
      final count = rows is List ? rows.length : 0;
      return MapEntry(key, count);
    });
  }
}
