import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travelvault/core/crypto/encryption_key_manager.dart';
import 'package:travelvault/core/db/app_database.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// An [EncryptionKeyManager] backed by an in-memory map — keeps the key
/// generation / persistence logic exercised without touching the platform
/// Keychain.
EncryptionKeyManager inMemoryKeyManager() {
  final store = <String, String>{};
  final storage = _MockSecureStorage();

  when(() => storage.read(key: any(named: 'key'))).thenAnswer(
    (invocation) async => store[invocation.namedArguments[#key] as String],
  );
  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((invocation) async {
    store[invocation.namedArguments[#key] as String] =
        invocation.namedArguments[#value] as String;
  });
  when(() => storage.delete(key: any(named: 'key'))).thenAnswer(
    (invocation) async =>
        store.remove(invocation.namedArguments[#key] as String),
  );

  return EncryptionKeyManager(secureStorage: storage);
}

/// FFI-backed opener: runs the real schema/migration code against a local
/// SQLite file (unencrypted). SQLCipher's encryption itself needs an
/// on-device integration test; this covers schema and query logic.
Future<Database> ffiOpener(
  String path, {
  required String password,
  required int version,
  required OnDatabaseConfigureFn onConfigure,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) {
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: version,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    ),
  );
}

/// An open [AppDatabase] backed by a throwaway temp-dir SQLite file. Call
/// [TestDatabase.dispose] in `tearDown` to close the connection and delete the
/// directory.
class TestDatabase {
  TestDatabase._(this.appDatabase, this._tempDir);

  final AppDatabase appDatabase;
  final Directory _tempDir;

  Database get db => appDatabase.database;

  static Future<TestDatabase> open() async {
    sqfliteFfiInit();
    final tempDir = await Directory.systemTemp.createTemp('travelvault_test');
    final appDatabase = AppDatabase(
      keyManager: inMemoryKeyManager(),
      opener: ffiOpener,
      databasesPath: () async => tempDir.path,
    );
    await appDatabase.open();
    return TestDatabase._(appDatabase, tempDir);
  }

  Future<void> dispose() async {
    await appDatabase.close();
    if (_tempDir.existsSync()) {
      await _tempDir.delete(recursive: true);
    }
  }
}
