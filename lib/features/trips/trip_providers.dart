import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/document.dart';
import '../../data/models/trip.dart';
import '../../data/models/trip_stop.dart';
import 'trip_service.dart';

final tripServiceProvider = Provider<TripService>(
  (ref) => TripService(repository: ref.watch(tripRepositoryProvider)),
);

/// The vault's trips. Loads once the database is open; screens call
/// [TripListController.reload] after a mutation.
final tripListProvider =
    AsyncNotifierProvider<TripListController, List<Trip>>(
  TripListController.new,
);

class TripListController extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    await ref.watch(appDatabaseProvider.future);
    return ref.watch(tripRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(
      () => ref.read(tripRepositoryProvider).getAll(),
    );
  }
}

/// Itinerary stops for one trip. Invalidate after editing stops to refresh.
final tripStopsProvider =
    FutureProvider.family<List<TripStop>, String>((ref, tripId) async {
  await ref.watch(appDatabaseProvider.future);
  return ref.watch(tripRepositoryProvider).getStops(tripId);
});

/// Documents linked to one trip. Invalidate after linking/unlinking.
final linkedDocumentsProvider =
    FutureProvider.family<List<Document>, String>((ref, tripId) async {
  await ref.watch(appDatabaseProvider.future);
  return ref.watch(tripRepositoryProvider).getLinkedDocuments(tripId);
});
