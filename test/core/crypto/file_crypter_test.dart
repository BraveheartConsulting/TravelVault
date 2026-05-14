import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/core/crypto/file_crypter.dart';

import '../../support/test_database.dart';

void main() {
  test('round-trips bytes through encryption', () async {
    final crypter = FileCrypter(inMemoryKeyManager());
    final plaintext =
        Uint8List.fromList(List.generate(2048, (i) => i % 256));

    final encrypted = await crypter.encryptBytes(plaintext);
    expect(encrypted, isNot(equals(plaintext)));

    final decrypted = await crypter.decryptBytes(encrypted);
    expect(decrypted, equals(plaintext));
  });

  test('produces a distinct ciphertext each time (random nonce)', () async {
    final crypter = FileCrypter(inMemoryKeyManager());
    final plaintext = Uint8List.fromList(List.filled(64, 7));

    final first = await crypter.encryptBytes(plaintext);
    final second = await crypter.encryptBytes(plaintext);

    expect(first, isNot(equals(second)));
  });

  test('rejects tampered ciphertext', () async {
    final crypter = FileCrypter(inMemoryKeyManager());
    final encrypted =
        await crypter.encryptBytes(Uint8List.fromList([1, 2, 3, 4, 5]));

    // Flip a bit in the authentication tag.
    encrypted[encrypted.length - 1] ^= 0xFF;

    expect(
      () => crypter.decryptBytes(encrypted),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('a different key cannot decrypt the payload', () async {
    final encrypted = await FileCrypter(inMemoryKeyManager())
        .encryptBytes(Uint8List.fromList([9, 9, 9]));

    // A fresh key manager provisions an unrelated key.
    expect(
      () => FileCrypter(inMemoryKeyManager()).decryptBytes(encrypted),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
