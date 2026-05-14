import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crypto/encryption_key_manager.dart';
import '../core/crypto/file_crypter.dart';
import '../core/db/app_database.dart';
import '../core/notifications/expiry_notifier.dart';
import '../core/storage/encrypted_image_store.dart';
import '../data/models/profile.dart';
import '../data/repositories/document_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/trip_repository.dart';

final encryptionKeyManagerProvider =
    Provider<EncryptionKeyManager>((_) => EncryptionKeyManager());

/// Opens the encrypted database once and keeps it alive for the app's lifetime.
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = AppDatabase(keyManager: ref.watch(encryptionKeyManagerProvider));
  await db.open();
  ref.onDispose(db.close);
  return db;
});

/// Reads the opened database — throws if read before [appDatabaseProvider]
/// resolves. Callers that may run before unlock should watch the async
/// provider instead.
AppDatabase _requireDatabase(Ref ref) =>
    ref.watch(appDatabaseProvider).requireValue;

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(_requireDatabase(ref).database),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(_requireDatabase(ref).database),
);

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepository(_requireDatabase(ref).database),
);

// --- Encrypted image storage ----------------------------------------------

final fileCrypterProvider = Provider<FileCrypter>(
  (ref) => FileCrypter(ref.watch(encryptionKeyManagerProvider)),
);

final encryptedImageStoreProvider = Provider<EncryptedImageStore>(
  (ref) => EncryptedImageStore(ref.watch(fileCrypterProvider)),
);

// --- Expiry alerts --------------------------------------------------------

final expiryNotifierProvider =
    Provider<ExpiryNotifier>((_) => ExpiryNotifier());

// --- Startup --------------------------------------------------------------

/// The active profile. For now there is exactly one; it is created on first
/// launch. Resolves only after the database is open.
final currentProfileProvider = FutureProvider<Profile>((ref) async {
  await ref.watch(appDatabaseProvider.future);
  return ref.watch(profileRepositoryProvider).ensureDefaultProfile();
});
