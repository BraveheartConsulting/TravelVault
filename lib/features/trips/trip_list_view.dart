import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/trip.dart';
import 'trip_display.dart';
import 'trip_providers.dart';
import 'trip_status_pill.dart';

/// The trips tab on the Home dashboard.
class TripListView extends ConsumerWidget {
  const TripListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripListProvider);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Trips could not be loaded.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (trips) {
        if (trips.isEmpty) return const _EmptyTrips();
        return RefreshIndicator(
          onRefresh: () => ref.read(tripListProvider.notifier).reload(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _TripTile(trip: trips[index]),
          ),
        );
      },
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (trip.destination != null && trip.destination!.isNotEmpty)
        trip.destination!,
      formatDateRange(trip.startDate, trip.endDate),
    ];

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.luggage_outlined)),
      title: Text(trip.name),
      subtitle: Text(subtitleParts.join('  ·  ')),
      trailing: TripStatusPill(trip: trip),
      onTap: () => context.push('/trips/${trip.id}'),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

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
              Icons.luggage_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No trips yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Plan a trip, build its itinerary, and attach the documents '
              'you need for it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
