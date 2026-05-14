import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/data/models/document.dart';
import 'package:travelvault/data/models/profile.dart';
import 'package:travelvault/data/repositories/document_repository.dart';
import 'package:travelvault/data/repositories/profile_repository.dart';

import '../../support/test_database.dart';

void main() {
  late TestDatabase testDb;
  late ProfileRepository profiles;
  late DocumentRepository documents;

  final epoch = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  Profile profile(String id) =>
      Profile(id: id, name: 'Owner $id', createdAt: epoch, updatedAt: epoch);

  Document document(
    String id,
    String profileId, {
    DateTime? expiryDate,
    DocumentType type = DocumentType.passport,
  }) => Document(
    id: id,
    profileId: profileId,
    type: type,
    title: 'Doc $id',
    expiryDate: expiryDate,
    fields: const {'mrz': 'P<UTODOE'},
    imagePaths: const ['vault/$id.enc'],
    createdAt: epoch,
    updatedAt: epoch,
  );

  setUp(() async {
    testDb = await TestDatabase.open();
    profiles = ProfileRepository(testDb.db);
    documents = DocumentRepository(testDb.db);
    await profiles.insert(profile('p1'));
    await profiles.insert(profile('p2'));
  });

  tearDown(() async {
    await testDb.dispose();
  });

  test('insert then getById round-trips every field', () async {
    final doc = document('d1', 'p1', expiryDate: epoch);
    await documents.insert(doc);

    final loaded = await documents.getById('d1');

    expect(loaded, isNotNull);
    expect(loaded!.profileId, 'p1');
    expect(loaded.type, DocumentType.passport);
    expect(loaded.fields, {'mrz': 'P<UTODOE'});
    expect(loaded.imagePaths, ['vault/d1.enc']);
    expect(loaded.expiryDate, epoch);
  });

  test('getByProfile only returns that profile\'s documents', () async {
    await documents.insert(document('d1', 'p1'));
    await documents.insert(document('d2', 'p1'));
    await documents.insert(document('d3', 'p2'));

    final forP1 = await documents.getByProfile('p1');

    expect(forP1.map((d) => d.id), unorderedEquals(['d1', 'd2']));
  });

  test('update persists changes', () async {
    await documents.insert(document('d1', 'p1'));

    final updated = (await documents.getById(
      'd1',
    ))!.copyWith(title: 'Renewed Passport', updatedAt: epoch);
    await documents.update(updated);

    expect((await documents.getById('d1'))!.title, 'Renewed Passport');
  });

  test('delete removes the document', () async {
    await documents.insert(document('d1', 'p1'));
    await documents.delete('d1');

    expect(await documents.getById('d1'), isNull);
  });

  test('getExpiringBefore returns soon-to-expire docs in order', () async {
    final soon = DateTime(2030, 1, 1);
    final later = DateTime(2030, 6, 1);
    final cutoff = DateTime(2030, 3, 1);

    await documents.insert(document('d-later', 'p1', expiryDate: later));
    await documents.insert(document('d-soon', 'p1', expiryDate: soon));
    await documents.insert(document('d-none', 'p1'));

    final expiring = await documents.getExpiringBefore(cutoff);

    expect(expiring.map((d) => d.id), ['d-soon']);
  });

  test('deleting a profile cascades to its documents', () async {
    await documents.insert(document('d1', 'p1'));
    await profiles.delete('p1');

    expect(await documents.getById('d1'), isNull);
  });
}
