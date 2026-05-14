import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the SQLCipher database encryption key.
///
/// The key is a 256-bit value generated once, on first launch, with a
/// cryptographically secure RNG. It is stored **only** in the platform secure
/// store (iOS Keychain / Android Keystore) and never written anywhere else —
/// not to the database file, not to logs, not to code.
class EncryptionKeyManager {
  EncryptionKeyManager({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const String _keyStorageId = 'travelvault.db.encryption_key';

  /// 32 bytes = 256-bit key.
  static const int _keyLengthBytes = 32;

  final FlutterSecureStorage _secureStorage;

  /// Returns the database encryption key, generating and persisting one on the
  /// first call. Subsequent calls return the same key for the device.
  Future<String> getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyStorageId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final key = _generateKey();
    await _secureStorage.write(key: _keyStorageId, value: key);
    return key;
  }

  /// Whether an encryption key has already been provisioned on this device.
  Future<bool> hasKey() async {
    final existing = await _secureStorage.read(key: _keyStorageId);
    return existing != null && existing.isNotEmpty;
  }

  /// Permanently removes the encryption key. After this call the encrypted
  /// database is unrecoverable — used only for an explicit "reset vault" action.
  Future<void> deleteKey() => _secureStorage.delete(key: _keyStorageId);

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      _keyLengthBytes,
      (_) => random.nextInt(256),
    );
    return base64UrlEncode(bytes);
  }
}
