import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/file_crypter.dart';

/// Stores document photos as AES-GCM encrypted `.enc` files inside the app's
/// private documents directory. Plaintext image bytes only ever exist in
/// memory — nothing readable is written to the filesystem.
///
/// The database stores the opaque [String] id returned by [save], not an
/// absolute path, so the store keeps working if the app's container path
/// changes across installs or OS updates.
class EncryptedImageStore {
  EncryptedImageStore(this._crypter, {Directory? baseDirectory})
    : _baseDirectoryOverride = baseDirectory;

  final FileCrypter _crypter;
  final Directory? _baseDirectoryOverride;

  static const String _subdirectory = 'vault_images';

  final Random _random = Random.secure();

  Future<Directory> _imagesDir() async {
    final base =
        _baseDirectoryOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _subdirectory));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Encrypts the file at [sourcePath] into the vault and returns its storage
  /// id. The source file is left untouched — callers own its cleanup.
  Future<String> save(String sourcePath) async {
    final plaintext = await File(sourcePath).readAsBytes();
    final encrypted = await _crypter.encryptBytes(plaintext);

    final id =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${_random.nextInt(1 << 32).toRadixString(16)}.enc';
    final dir = await _imagesDir();
    await File(p.join(dir.path, id)).writeAsBytes(encrypted, flush: true);
    return id;
  }

  /// Decrypts and returns the image bytes for [id].
  Future<Uint8List> load(String id) async {
    final dir = await _imagesDir();
    final encrypted = await File(p.join(dir.path, id)).readAsBytes();
    return _crypter.decryptBytes(encrypted);
  }

  /// Removes the encrypted file for [id]. A missing file is not an error —
  /// deletion is idempotent.
  Future<void> delete(String id) async {
    final dir = await _imagesDir();
    final file = File(p.join(dir.path, id));
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
