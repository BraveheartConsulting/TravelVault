import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/document.dart';
import 'document_display.dart';
import 'document_providers.dart';
import 'expiry_status_pill.dart';

/// Read-only view of a single document, with edit and delete actions.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(documentListProvider);

    return listAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (documents) {
        Document? document;
        for (final candidate in documents) {
          if (candidate.id == documentId) {
            document = candidate;
            break;
          }
        }
        if (document == null) {
          // The document was deleted while this screen was open.
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This document no longer exists.')),
          );
        }
        return _DetailView(document: document);
      },
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.document});

  final Document document;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          '“${document.title}” and its photos will be permanently removed '
          'from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(documentServiceProvider).delete(document);
    await ref.read(documentListProvider.notifier).reload();
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push(
              '/documents/${document.id}/edit',
              extra: document,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Icon(documentTypeIcon(document.type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  documentTypeLabel(document.type),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              ExpiryStatusPill(document: document),
            ],
          ),
          const SizedBox(height: 24),
          _Field(label: 'Document number', value: document.documentNumber),
          _Field(label: 'Issuing country', value: document.issuingCountry),
          _Field(label: 'Issue date', value: formatDate(document.issueDate)),
          _Field(label: 'Expiry date', value: formatDate(document.expiryDate)),
          _Field(label: 'Notes', value: document.notes),
          if (document.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Photos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final imageId in document.imagePaths)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DocumentImage(imageId: imageId),
              ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final display = (value == null || value!.isEmpty) ? '—' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          Text(display, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Decrypts and renders one stored document photo.
class _DocumentImage extends ConsumerWidget {
  const _DocumentImage({required this.imageId});

  final String imageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(decryptedImageProvider(imageId));
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageAsync.when(
        loading: () => const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox(
          height: 160,
          child: Center(child: Text('Could not decrypt this photo.')),
        ),
        data: (bytes) => Image.memory(bytes, fit: BoxFit.contain),
      ),
    );
  }
}
