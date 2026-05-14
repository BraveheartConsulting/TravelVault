import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/data/repositories/profile_repository.dart';

import '../../support/test_database.dart';

void main() {
  late TestDatabase testDb;
  late ProfileRepository profiles;

  setUp(() async {
    testDb = await TestDatabase.open();
    profiles = ProfileRepository(testDb.db);
  });

  tearDown(() async {
    await testDb.dispose();
  });

  test('ensureDefaultProfile creates a "self" profile when empty', () async {
    expect(await profiles.getAll(), isEmpty);

    final profile = await profiles.ensureDefaultProfile();

    expect(profile.relationship, 'self');
    expect(await profiles.getAll(), hasLength(1));
  });

  test('ensureDefaultProfile is idempotent', () async {
    final first = await profiles.ensureDefaultProfile();
    final second = await profiles.ensureDefaultProfile();

    expect(second.id, first.id);
    expect(await profiles.getAll(), hasLength(1));
  });
}
