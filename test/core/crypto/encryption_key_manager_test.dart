import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelvault/core/crypto/encryption_key_manager.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;
  late Map<String, String> store;
  late EncryptionKeyManager manager;

  setUp(() {
    store = <String, String>{};
    storage = _MockSecureStorage();

    when(() => storage.read(key: any(named: 'key'))).thenAnswer(
      (i) async => store[i.namedArguments[#key] as String],
    );
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((i) async {
      store[i.namedArguments[#key] as String] =
          i.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer(
      (i) async => store.remove(i.namedArguments[#key] as String),
    );

    manager = EncryptionKeyManager(secureStorage: storage);
  });

  test('generates and persists a 256-bit key on first use', () async {
    expect(await manager.hasKey(), isFalse);

    final key = await manager.getOrCreateKey();

    expect(await manager.hasKey(), isTrue);
    // base64url of 32 random bytes.
    expect(base64Url.decode(key), hasLength(32));
    verify(() => storage.write(key: any(named: 'key'), value: key)).called(1);
  });

  test('returns the same key on subsequent calls', () async {
    final first = await manager.getOrCreateKey();
    final second = await manager.getOrCreateKey();

    expect(second, equals(first));
    // Written exactly once — the second call reads the cached value.
    verify(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .called(1);
  });

  test('generates distinct keys across independent installs', () async {
    final keyA = await manager.getOrCreateKey();

    store.clear();
    final keyB = await manager.getOrCreateKey();

    expect(keyB, isNot(equals(keyA)));
  });

  test('deleteKey removes the stored key', () async {
    await manager.getOrCreateKey();
    expect(await manager.hasKey(), isTrue);

    await manager.deleteKey();

    expect(await manager.hasKey(), isFalse);
  });
}
