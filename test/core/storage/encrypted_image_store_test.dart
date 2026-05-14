import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travelvault/core/crypto/file_crypter.dart';
import 'package:travelvault/core/storage/encrypted_image_store.dart';

import '../../support/test_database.dart';

void main() {
  late Directory tempDir;
  late EncryptedImageStore store;

  final original = Uint8List.fromList(List.generate(800, (i) => (i * 7) % 256));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_store_test');
    store = EncryptedImageStore(
      FileCrypter(inMemoryKeyManager()),
      baseDirectory: tempDir,
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<String> writeSourceImage() async {
    final source = File(p.join(tempDir.path, 'source.jpg'));
    await source.writeAsBytes(original);
    return source.path;
  }

  test('save writes an encrypted file and load returns the original', () async {
    final id = await store.save(await writeSourceImage());

    final storedFile = File(p.join(tempDir.path, 'vault_images', id));
    expect(storedFile.existsSync(), isTrue);
    // What's on disk is not the plaintext image.
    expect(await storedFile.readAsBytes(), isNot(equals(original)));

    expect(await store.load(id), equals(original));
  });

  test('each save produces a unique id', () async {
    final source = await writeSourceImage();
    final idA = await store.save(source);
    final idB = await store.save(source);

    expect(idA, isNot(equals(idB)));
  });

  test('delete removes the encrypted file and is idempotent', () async {
    final id = await store.save(await writeSourceImage());
    final storedFile = File(p.join(tempDir.path, 'vault_images', id));

    await store.delete(id);
    expect(storedFile.existsSync(), isFalse);

    // Deleting again must not throw.
    await store.delete(id);
  });
}
