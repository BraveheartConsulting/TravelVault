import '../../data/models/trip.dart';

/// Where a trip sits relative to today, used to badge the trip list.
enum TripStatus {
  /// No start date set yet.
  undated,

  /// Starts in the future.
  upcoming,

  /// Started, not yet ended.
  inProgress,

  /// Ended.
  past,
}

TripStatus tripStatusOf(Trip trip, {DateTime? now}) {
  final start = trip.startDate;
  if (start == null) return TripStatus.undated;

  final reference = now ?? DateTime.now();
  if (start.isAfter(reference)) return TripStatus.upcoming;

  final end = trip.endDate;
  if (end != null && end.isBefore(reference)) return TripStatus.past;
  return TripStatus.inProgress;
}

/// Whole days from [now] until the trip starts. Negative once it has started,
/// null when the trip has no start date.
int? daysUntilStart(Trip trip, {DateTime? now}) {
  final start = trip.startDate;
  if (start == null) return null;

  final reference = now ?? DateTime.now();
  final startDay = DateTime(start.year, start.month, start.day);
  final today = DateTime(reference.year, reference.month, reference.day);
  return startDay.difference(today).inDays;
}
