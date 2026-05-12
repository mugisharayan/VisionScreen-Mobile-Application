# VisionScreen

VisionScreen is an offline-first Flutter app for community health workers to register patients, run visual acuity screenings, manage campaigns, produce referrals, and export local records.

## Current Architecture

- Flutter UI in `lib/screens/`
- Local SQLite persistence in `lib/db/database_helper.dart`
- Thin repositories in `lib/repositories/`
- Workspace snapshot backup/restore in `lib/services/backup_service.dart`
- Optional MongoDB workspace sync in `lib/services/sync/`

The refactor in progress removes misleading cloud/security claims and routes writes through explicit database helpers so sync, backup, analytics, and exports all use the same source of truth.

## Workspace Sync

MongoDB sync is optional and build-configured. When configured, local writes still land in SQLite first and are pushed later through the queued sync pipeline. Cloud backups are captured from the same SQLite source of truth and stored in Atlas as workspace snapshots.

Build with:

```bash
flutter run \
  --dart-define=VS_MONGODB_URI=mongodb+srv://<user>:<password>@<cluster>/<db> \
  --dart-define=VS_MONGODB_DB=<db-name>
```

Or provide the connection in parts:

```bash
flutter run \
  --dart-define=VS_MONGODB_HOST=<cluster-host> \
  --dart-define=VS_MONGODB_USER=<db-user> \
  --dart-define=VS_MONGODB_PASSWORD=<db-password> \
  --dart-define=VS_MONGODB_DB=<db-name>
```

If the sync variables are omitted, the app remains local-only and exposes honest "not configured" states in the UI.

## Local Development

```bash
flutter pub get
flutter test
dart analyze \
  lib/db/database_helper.dart \
  lib/repositories/auth_repository.dart \
  lib/repositories/campaign_repository.dart \
  lib/repositories/patient_repository.dart \
  lib/repositories/screening_repository.dart \
  lib/screens/splash_screen.dart \
  lib/services/backup_service.dart \
  lib/services/sync \
  lib/utils/app_constants.dart \
  lib/utils/id_utils.dart \
  test/widget_test.dart
```

## Platform Notes

- iOS requires camera, photo library, and location permissions for the current screening flows.
- Android includes native channels for brightness and ambient light access.

## Product Areas

- Authentication and session restore
- Patient registration and duplicate detection
- Individual screening
- Bulk campaign screening
- Referral tracking
- Analytics and PDF export
- Cloud backup/restore
- Optional facility workspace sync
