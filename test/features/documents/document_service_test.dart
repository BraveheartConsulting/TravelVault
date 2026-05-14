import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travelvault/core/crypto/file_crypter.dart';
import 'package:travelvault/core/notifications/expiry_notifier.dart';
import 'package:travelvault/core/storage/encrypted_image_store.dart';
import 'package:travelvault/data/models/document.dart';
import 'package:travelvault/data/repositories/document_repository.dart';
import 'package:travelvault/data/repositories/profile_repository.dart';
import 'package:travelvault/features/documents/document_service.dart';

import '../../support/test_database.dart';

/// Records scheduling calls without touching platform notification channels.
class _FakeExpiryNotifier implements ExpiryNotifier {
  final List<String> scheduled = [];
  final List<String> cancelled = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> rescheduleAll(List<Document> documents) async {}

  @override
  Future<void> scheduleForDocument(Document document) async {
    scheduled.add(document.id);
  }

  @override
  Future<void> cancelForDocument(String documentId) async {
    cancelled.add(documentId);
  }
}

void main() {
  late TestDatabase testDb;
  late Directory tempDir;
  late DocumentRepository documents;
  late EncryptedImageStore imageStore;
  late _FakeExpiryNotifier notifier;
  late DocumentService service;
  late String profileId;

  setUp(() async {
    testDb = await TestDatabase.open();
    tempDir = await Directory.systemTemp.createTemp('document_service_test');
    documents = DocumentRepository(testDb.db);
    profileId =
        (await ProfileRepository(testDb.db).ensureDefaultProfile()).id;
    imageStore = EncryptedImageStore(
      FileCrypter(inMemoryKeyManager()),
      baseDirectory: tempDir,
    );
    notifier = _FakeExpiryNotifier();
    service = DocumentService(
      repository: documents,
      imageStore: imageStore,
      notifier: notifier,
    );
  });

  tearDown(() async {
    await testDb.dispose();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<String> writeSourceImage() async {
    final file = File(
      p.join(tempDir.path, 'src_${DateTime.now().microsecondsSinceEpoch}.jpg'),
    );
    await file.writeAsBytes(
      Uint8List.fromList(List.generate(300, (i) => i % 256)),
    );
    return file.path;
  }

  test('create encrypts images, persists the row, and schedules an alert',
      () async {
    final document = await service.create(
      profileId: profileId,
      type: DocumentType.passport,
      title: 'My Passport',
      expiryDate: DateTime(2030, 1, 1),
      newImageSourcePaths: [await writeSourceImage()],
    );

    expect(document.imagePaths, hasLength(1));
    // The stored image decrypts back to the original 300 bytes.
    expect(await imageStore.load(document.imagePaths.first), hasLength(300));
    expect(await documents.getById(document.id), isNotNull);
    expect(notifier.scheduled, contains(document.id));
  });

  test('update clears a field, swaps an image, and reschedules', () async {
    final created = await service.create(
      profileId: profileId,
      type: DocumentType.passport,
      title: 'Passport',
      notes: 'original note',
      newImageSourcePaths: [await writeSourceImage()],
    );
    final oldImageId = created.imagePaths.first;

    final updated = await service.update(
      created,
      type: DocumentType.visa,
      title: 'Passport',
      notes: null, // cleared
      newImageSourcePaths: [await writeSourceImage()],
      removedImageIds: [oldImageId],
    );

    expect(updated.notes, isNull);
    expect(updated.type, DocumentType.visa);
    expect(updated.imagePaths, hasLength(1));
    expect(updated.imagePaths, isNot(contains(oldImageId)));
    // The removed image's encrypted file is gone.
    expect(() => imageStore.load(oldImageId), throwsA(anything));
    expect(notifier.scheduled, contains(updated.id));
  });

  test('delete removes the row, the images, and the pending alert', () async {
    final document = await service.create(
      profileId: profileId,
      type: DocumentType.passport,
      title: 'Passport',
      newImageSourcePaths: [await writeSourceImage()],
    );
    final imageId = document.imagePaths.first;

    await service.delete(document);

    expect(await documents.getById(document.id), isNull);
    expect(() => imageStore.load(imageId), throwsA(anything));
    expect(notifier.cancelled, contains(document.id));
  });
}
