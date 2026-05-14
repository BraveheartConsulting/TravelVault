import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'encryption_key_manager.dart';

/// Encrypts and decrypts arbitrary byte payloads (document photos) with
/// AES-GCM, using the same device key that protects the database.
///
/// AES-GCM is authenticated: a tampered or truncated ciphertext fails
/// decryption rather than returning garbage. The nonce and MAC are stored
/// alongside the ciphertext via [SecretBox.concatenation].
class FileCrypter {
  FileCrypter(this._keyManager, {AesGcm? algorithm})
    : _algorithm = algorithm ?? AesGcm.with256bits();

  final EncryptionKeyManager _keyManager;
  final AesGcm _algorithm;

  Future<SecretKey> _secretKey() async {
    final keyString = await _keyManager.getOrCreateKey();
    return SecretKey(base64Url.decode(keyString));
  }

  /// Encrypts [plaintext], returning `nonce || ciphertext || mac`.
  Future<Uint8List> encryptBytes(List<int> plaintext) async {
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: await _secretKey(),
    );
    return Uint8List.fromList(secretBox.concatenation());
  }

  /// Decrypts a payload produced by [encryptBytes]. Throws
  /// [SecretBoxAuthenticationError] if the data has been tampered with.
  Future<Uint8List> decryptBytes(List<int> payload) async {
    final secretBox = SecretBox.fromConcatenation(
      payload,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    final clear = await _algorithm.decrypt(
      secretBox,
      secretKey: await _secretKey(),
    );
    return Uint8List.fromList(clear);
  }
}
