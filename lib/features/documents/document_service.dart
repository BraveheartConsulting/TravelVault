import '../../core/ids.dart';
import '../../core/notifications/expiry_notifier.dart';
import '../../core/storage/encrypted_image_store.dart';
import '../../data/models/document.dart';
import '../../data/repositories/document_repository.dart';

/// The single mutation point for documents. Keeps the three side effects of a
/// document change — encrypted image files, the database row, and the pending
/// expiry alert — consistent with each other.
class DocumentService {
  DocumentService({
    required DocumentRepository repository,
    required EncryptedImageStore imageStore,
    required ExpiryNotifier notifier,
  })  : _repository = repository,
        _imageStore = imageStore,
        _notifier = notifier;

  final DocumentRepository _repository;
  final EncryptedImageStore _imageStore;
  final ExpiryNotifier _notifier;

  /// Encrypts any picked images, persists the new document, and schedules its
  /// expiry alert.
  Future<Document> create({
    required String profileId,
    required DocumentType type,
    required String title,
    String? documentNumber,
    String? issuingCountry,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    List<String> newImageSourcePaths = const [],
  }) async {
    final imageIds = <String>[];
    for (final sourcePath in newImageSourcePaths) {
      imageIds.add(await _imageStore.save(sourcePath));
    }

    final now = DateTime.now();
    final document = Document(
      id: newId(),
      profileId: profileId,
      type: type,
      title: title,
      documentNumber: documentNumber,
      issuingCountry: issuingCountry,
      issueDate: issueDate,
      expiryDate: expiryDate,
      notes: notes,
      imagePaths: imageIds,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insert(document);
    await _notifier.scheduleForDocument(document);
    return document;
  }

  /// Applies edits to [existing]. Newly picked images are encrypted and
  /// appended; images in [removedImageIds] are deleted from disk. The full
  /// field set is written explicitly so cleared fields are actually cleared.
  Future<Document> update(
    Document existing, {
    required DocumentType type,
    required String title,
    String? documentNumber,
    String? issuingCountry,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    List<String> newImageSourcePaths = const [],
    List<String> removedImageIds = const [],
  }) async {
    for (final id in removedImageIds) {
      await _imageStore.delete(id);
    }

    final imageIds = existing.imagePaths
        .where((id) => !removedImageIds.contains(id))
        .toList();
    for (final sourcePath in newImageSourcePaths) {
      imageIds.add(await _imageStore.save(sourcePath));
    }

    final updated = Document(
      id: existing.id,
      profileId: existing.profileId,
      type: type,
      title: title,
      documentNumber: documentNumber,
      issuingCountry: issuingCountry,
      issueDate: issueDate,
      expiryDate: expiryDate,
      notes: notes,
      imagePaths: imageIds,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    await _repository.update(updated);
    await _notifier.scheduleForDocument(updated);
    return updated;
  }

  /// Deletes the document, its encrypted images, and its pending alert.
  Future<void> delete(Document document) async {
    for (final id in document.imagePaths) {
      await _imageStore.delete(id);
    }
    await _repository.delete(document.id);
    await _notifier.cancelForDocument(document.id);
  }
}
