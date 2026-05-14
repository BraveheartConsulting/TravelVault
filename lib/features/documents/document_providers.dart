import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/document.dart';
import 'document_service.dart';

final documentServiceProvider = Provider<DocumentService>((ref) {
  return DocumentService(
    repository: ref.watch(documentRepositoryProvider),
    imageStore: ref.watch(encryptedImageStoreProvider),
    notifier: ref.watch(expiryNotifierProvider),
  );
});

/// The vault's documents. Loads once the database is open and exposes
/// [DocumentListController.reload] for screens to call after a mutation.
final documentListProvider =
    AsyncNotifierProvider<DocumentListController, List<Document>>(
      DocumentListController.new,
    );

class DocumentListController extends AsyncNotifier<List<Document>> {
  @override
  Future<List<Document>> build() async {
    await ref.watch(appDatabaseProvider.future);
    final documents = await ref.watch(documentRepositoryProvider).getAll();

    // Belt-and-braces: realign pending OS alerts with the current data on
    // every fresh load (handles reinstalls and cleared notifications).
    unawaited(ref.read(expiryNotifierProvider).rescheduleAll(documents));
    return documents;
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(
      () => ref.read(documentRepositoryProvider).getAll(),
    );
  }
}

/// Decrypts a stored image on demand. Keyed by the image's storage id.
final decryptedImageProvider = FutureProvider.family<Uint8List, String>((
  ref,
  imageId,
) {
  return ref.watch(encryptedImageStoreProvider).load(imageId);
});
