import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../documents/document_display.dart';
import '../documents/document_providers.dart';
import 'trip_providers.dart';

/// Opens the modal sheet for attaching vault documents to a trip.
Future<void> showLinkDocumentsSheet(BuildContext context, String tripId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LinkDocumentsSheet(tripId: tripId),
  );
}

class _LinkDocumentsSheet extends ConsumerWidget {
  const _LinkDocumentsSheet({required this.tripId});

  final String tripId;

  Future<void> _toggle(WidgetRef ref, String documentId, bool link) async {
    final service = ref.read(tripServiceProvider);
    if (link) {
      await service.linkDocument(tripId, documentId);
    } else {
      await service.unlinkDocument(tripId, documentId);
    }
    ref.invalidate(linkedDocumentsProvider(tripId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentListProvider);
    final linkedAsync = ref.watch(linkedDocumentsProvider(tripId));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Attach documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: switch ((documentsAsync, linkedAsync)) {
                (AsyncData(value: final documents), AsyncData(:final value)) =>
                  documents.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Your vault has no documents to attach yet.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          children: [
                            for (final document in documents)
                              CheckboxListTile(
                                secondary: Icon(
                                  documentTypeIcon(document.type),
                                ),
                                title: Text(document.title),
                                subtitle:
                                    Text(documentTypeLabel(document.type)),
                                value: value
                                    .any((d) => d.id == document.id),
                                onChanged: (checked) => _toggle(
                                  ref,
                                  document.id,
                                  checked ?? false,
                                ),
                              ),
                          ],
                        ),
                (AsyncError(:final error), _) ||
                (_, AsyncError(:final error)) =>
                  Center(child: Text('$error')),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}
