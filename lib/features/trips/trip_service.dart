import '../../core/ids.dart';
import '../../data/models/trip.dart';
import '../../data/models/trip_stop.dart';
import '../../data/repositories/trip_repository.dart';

/// The single mutation point for trips, their itinerary stops, and their
/// links to vault documents.
class TripService {
  TripService({required TripRepository repository}) : _repository = repository;

  final TripRepository _repository;

  // --- Trips ---------------------------------------------------------------

  Future<Trip> createTrip({
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    final now = DateTime.now();
    final trip = Trip(
      id: newId(),
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.insert(trip);
    return trip;
  }

  /// Writes the full field set explicitly so cleared fields are actually
  /// cleared (a `copyWith` would keep stale values for nulls).
  Future<Trip> updateTrip(
    Trip existing, {
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    final updated = Trip(
      id: existing.id,
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await _repository.update(updated);
    return updated;
  }

  /// Deletes the trip; cascades remove its stops and document links (the
  /// documents themselves are untouched).
  Future<void> deleteTrip(String id) => _repository.delete(id);

  // --- Itinerary stops -----------------------------------------------------

  Future<TripStop> addStop({
    required String tripId,
    required TripStopType type,
    required String title,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    String? confirmationNumber,
    String? notes,
    int sortOrder = 0,
  }) async {
    final now = DateTime.now();
    final stop = TripStop(
      id: newId(),
      tripId: tripId,
      type: type,
      title: title,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      confirmationNumber: confirmationNumber,
      notes: notes,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.insertStop(stop);
    return stop;
  }

  Future<TripStop> updateStop(
    TripStop existing, {
    required TripStopType type,
    required String title,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    String? confirmationNumber,
    String? notes,
  }) async {
    final updated = TripStop(
      id: existing.id,
      tripId: existing.tripId,
      type: type,
      title: title,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      confirmationNumber: confirmationNumber,
      notes: notes,
      sortOrder: existing.sortOrder,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await _repository.updateStop(updated);
    return updated;
  }

  Future<void> deleteStop(String id) => _repository.deleteStop(id);

  // --- Document links ------------------------------------------------------

  Future<void> linkDocument(String tripId, String documentId) =>
      _repository.linkDocument(tripId, documentId);

  Future<void> unlinkDocument(String tripId, String documentId) =>
      _repository.unlinkDocument(tripId, documentId);
}
