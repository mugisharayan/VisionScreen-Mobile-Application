import 'package:mongo_dart/mongo_dart.dart';

import '../../utils/app_constants.dart';

class MongoWorkspaceRemote {
  MongoWorkspaceRemote._();

  static final MongoWorkspaceRemote instance = MongoWorkspaceRemote._();

  static const String _uri = String.fromEnvironment('VS_MONGODB_URI');
  static const String _dbName = String.fromEnvironment('VS_MONGODB_DB');

  Db? _db;

  bool get isConfigured => _uri.isNotEmpty && _dbName.isNotEmpty;

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

    if (operation == AppStrings.syncPendingDelete) {
      outgoing['sync_state'] = AppStrings.syncSynced;
      await collection.replaceOne(
        where.eq('_id', entityId),
        outgoing,
        upsert: true,
      );
    } else {
      outgoing['sync_state'] = AppStrings.syncSynced;
      await collection.replaceOne(
        where.eq('_id', entityId),
        outgoing,
        upsert: true,
      );
    }

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
        'MongoDB sync is not configured. Provide VS_MONGODB_URI and VS_MONGODB_DB.',
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
    if (!isConfigured) return;
    if (_db != null && _db!.isConnected) return;
    final db = await Db.create(_effectiveUri);
    await db.open();
    _db = db;
  }

  Map<String, dynamic>? _normalizeDoc(Map<String, dynamic>? doc) {
    if (doc == null) return null;
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

  String get _effectiveUri {
    if (_dbName.isEmpty) return _uri;
    final parsed = Uri.parse(_uri);
    if (parsed.pathSegments.isNotEmpty &&
        parsed.pathSegments.first.isNotEmpty) {
      return _uri;
    }
    return parsed.replace(path: '/$_dbName').toString();
  }
}
