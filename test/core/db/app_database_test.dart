import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/core/db/schema.dart';

import '../../support/test_database.dart';

void main() {
  late TestDatabase testDb;

  setUp(() async {
    testDb = await TestDatabase.open();
  });

  tearDown(() async {
    await testDb.dispose();
  });

  test('creates every table in the schema', () async {
    final tables = await testDb.db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final names = tables.map((r) => r['name'] as String).toSet();

    expect(
      names,
      containsAll(<String>[
        'profiles',
        'documents',
        'trips',
        'trip_stops',
        'trip_documents',
      ]),
    );
  });

  test('reports the current schema version', () async {
    final version = await testDb.db.getVersion();
    expect(version, kSchemaVersion);
  });

  test('enforces foreign keys — orphan documents are rejected', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    expect(
      () => testDb.db.insert('documents', {
        'id': 'doc-1',
        'profile_id': 'missing-profile',
        'type': 'passport',
        'title': 'Orphan',
        'created_at': now,
        'updated_at': now,
      }),
      throwsA(anything),
    );
  });

  test('cascades deletes from profiles to documents', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await testDb.db.insert('profiles', {
      'id': 'p-1',
      'name': 'Alex',
      'created_at': now,
      'updated_at': now,
    });
    await testDb.db.insert('documents', {
      'id': 'd-1',
      'profile_id': 'p-1',
      'type': 'passport',
      'title': 'Passport',
      'created_at': now,
      'updated_at': now,
    });

    await testDb.db.delete('profiles', where: 'id = ?', whereArgs: ['p-1']);

    final remaining = await testDb.db.query('documents');
    expect(remaining, isEmpty);
  });
}
