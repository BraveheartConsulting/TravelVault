import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/document.dart';
import 'document_display.dart';
import 'document_providers.dart';
import 'expiry_status_pill.dart';

/// The vault list shown on the Home dashboard.
class DocumentListView extends ConsumerWidget {
  const DocumentListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentListProvider);

    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'The vault could not be opened.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (documents) {
        if (documents.isEmpty) return const _EmptyVault();
        return RefreshIndicator(
          onRefresh: () => ref.read(documentListProvider.notifier).reload(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: documents.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _DocumentTile(document: documents[index]),
          ),
        );
      },
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final subtitle = document.expiryDate != null
        ? 'Expires ${formatDate(document.expiryDate)}'
        : documentTypeLabel(document.type);

    return ListTile(
      leading: CircleAvatar(child: Icon(documentTypeIcon(document.type))),
      title: Text(document.title),
      subtitle: Text(subtitle),
      trailing: ExpiryStatusPill(document: document),
      onTap: () => context.push('/documents/${document.id}'),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Your vault is empty', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add your passport, visas, and tickets — encrypted and stored '
              'only on this device.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
