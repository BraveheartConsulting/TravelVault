import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/trip.dart';
import '../../data/models/trip_stop.dart';
import '../documents/document_display.dart';
import 'link_documents_sheet.dart';
import 'trip_display.dart';
import 'trip_providers.dart';
import 'trip_status_pill.dart';

/// Detail view for a single trip: its facts, itinerary timeline, and the
/// documents attached to it.
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripListProvider);

    return tripsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (trips) {
        Trip? trip;
        for (final candidate in trips) {
          if (candidate.id == tripId) {
            trip = candidate;
            break;
          }
        }
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This trip no longer exists.')),
          );
        }
        return _DetailView(trip: trip);
      },
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.trip});

  final Trip trip;

  Future<void> _deleteTrip(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text(
          '“${trip.name}”, its itinerary, and its document links will be '
          'removed. The documents themselves stay in your vault.',
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

    await ref.read(tripServiceProvider).deleteTrip(trip.id);
    await ref.read(tripListProvider.notifier).reload();
    if (context.mounted) context.pop();
  }

  Future<void> _deleteStop(
    BuildContext context,
    WidgetRef ref,
    TripStop stop,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete stop?'),
        content: Text('“${stop.title}” will be removed from the itinerary.'),
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

    await ref.read(tripServiceProvider).deleteStop(stop.id);
    ref.invalidate(tripStopsProvider(trip.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stopsAsync = ref.watch(tripStopsProvider(trip.id));
    final linkedAsync = ref.watch(linkedDocumentsProvider(trip.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () =>
                context.push('/trips/${trip.id}/edit', extra: trip),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _deleteTrip(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.destination?.isNotEmpty == true
                      ? trip.destination!
                      : 'No destination set',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TripStatusPill(trip: trip),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatDateRange(trip.startDate, trip.endDate),
            style: theme.textTheme.bodyMedium,
          ),
          if (trip.notes != null && trip.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(trip.notes!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),

          // --- Itinerary ---
          _SectionHeader(
            title: 'Itinerary',
            actionLabel: 'Add stop',
            onAction: () => context.push('/trips/${trip.id}/stops/new'),
          ),
          stopsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text('$error'),
            ),
            data: (stops) => stops.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No itinerary stops yet.'),
                  )
                : Column(
                    children: [
                      for (final stop in stops)
                        _StopTile(
                          stop: stop,
                          onEdit: () => context.push(
                            '/trips/${trip.id}/stops/${stop.id}/edit',
                            extra: stop,
                          ),
                          onDelete: () => _deleteStop(context, ref, stop),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // --- Linked documents ---
          _SectionHeader(
            title: 'Documents',
            actionLabel: 'Attach',
            onAction: () => showLinkDocumentsSheet(context, trip.id),
          ),
          linkedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text('$error'),
            ),
            data: (documents) => documents.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No documents attached to this trip.'),
                  )
                : Column(
                    children: [
                      for (final document in documents)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(documentTypeIcon(document.type)),
                          title: Text(document.title),
                          subtitle: Text(documentTypeLabel(document.type)),
                          onTap: () =>
                              context.push('/documents/${document.id}'),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.onEdit,
    required this.onDelete,
  });

  final TripStop stop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final when = stop.startsAt != null ? formatDateTime(stop.startsAt) : null;
    final subtitleParts = [
      tripStopTypeLabel(stop.type),
      if (stop.location != null && stop.location!.isNotEmpty) stop.location!,
      if (when != null) when,
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(tripStopTypeIcon(stop.type)),
      title: Text(stop.title),
      subtitle: Text(subtitleParts.join('  ·  ')),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete stop',
        onPressed: onDelete,
      ),
      onTap: onEdit,
    );
  }
}
