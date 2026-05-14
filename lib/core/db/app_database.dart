import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../crypto/encryption_key_manager.dart';
import 'schema.dart';

/// Opens a [Database] connection. Abstracted so tests can substitute an
/// unencrypted FFI database while production uses SQLCipher.
typedef DatabaseOpener = Future<Database> Function(
  String path, {
  required String password,
  required int version,
  required OnDatabaseConfigureFn onConfigure,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
});

/// Resolves the directory the database file lives in. Abstracted so tests can
/// point at a temp directory instead of the platform databases path.
typedef DatabasesPathResolver = Future<String> Function();

Future<Database> _sqlCipherOpener(
  String path, {
  required String password,
  required int version,
  required OnDatabaseConfigureFn onConfigure,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) {
  return openDatabase(
    path,
    password: password,
    version: version,
    onConfigure: onConfigure,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
  );
}

/// Owns the single SQLCipher-encrypted database connection for the app.
///
/// The connection is opened with a key sourced from [EncryptionKeyManager],
/// so the database file on disk is unreadable without the device's Keychain /
/// Keystore entry.
class AppDatabase {
  AppDatabase({
    required EncryptionKeyManager keyManager,
    DatabaseOpener opener = _sqlCipherOpener,
    DatabasesPathResolver databasesPath = getDatabasesPath,
    String databaseName = 'travelvault.db',
  })  : _keyManager = keyManager,
        _opener = opener,
        _databasesPath = databasesPath,
        _databaseName = databaseName;

  final EncryptionKeyManager _keyManager;
  final DatabaseOpener _opener;
  final DatabasesPathResolver _databasesPath;
  final String _databaseName;

  Database? _db;

  /// The open connection. Throws [StateError] if [open] has not completed.
  Database get database {
    final db = _db;
    if (db == null) {
      throw StateError('AppDatabase.open() must be awaited before use.');
    }
    return db;
  }

  bool get isOpen => _db != null;

  /// Opens (and creates/migrates) the encrypted database. Idempotent.
  Future<Database> open() async {
    final existing = _db;
    if (existing != null) return existing;

    final password = await _keyManager.getOrCreateKey();
    final path = p.join(await _databasesPath(), _databaseName);

    final db = await _opener(
      path,
      password: password,
      version: kSchemaVersion,
      onConfigure: configureDatabase,
      onCreate: (db, version) => createSchema(db),
      onUpgrade: migrate,
    );
    _db = db;
    return db;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
