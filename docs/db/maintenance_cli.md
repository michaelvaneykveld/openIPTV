## Maintenance CLI

Run the maintenance tasks from the command line with Flutter’s `pub run`:

```bash
flutter pub run tool/db_maintenance.dart --all
```

### Available options

- `--all` (default) – run the full maintenance pipeline (`VACUUM`, `ANALYZE`, retention sweep, artwork prune).
- `--vacuum`, `--analyze`, `--sweep`, `--artwork` – execute individual maintenance steps.
- `--force` – bypass cadence and file-size checks for the selected steps.
- `--reset-provider=<providerId>` – remove a provider and cascade-delete related records.
- `--export-import-runs=<path>` – export logged import telemetry as JSON.
- `--help` – show usage.

### Example

```bash
flutter pub run tool/db_maintenance.dart --vacuum --analyze --force
```

This forces both `VACUUM` and `ANALYZE` regardless of cadence thresholds.

