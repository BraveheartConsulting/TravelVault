import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/data/models/trip.dart';
import 'package:travelvault/features/trips/trip_status.dart';

Trip _trip({DateTime? start, DateTime? end}) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return Trip(
    id: 'trip-1',
    name: 'Trip',
    startDate: start,
    endDate: end,
    createdAt: epoch,
    updatedAt: epoch,
  );
}

void main() {
  final now = DateTime(2026, 6, 15);

  group('tripStatusOf', () {
    test('undated when there is no start date', () {
      expect(tripStatusOf(_trip(), now: now), TripStatus.undated);
    });

    test('upcoming when the start date is in the future', () {
      expect(
        tripStatusOf(_trip(start: DateTime(2026, 7, 1)), now: now),
        TripStatus.upcoming,
      );
    });

    test('inProgress when started and not yet ended', () {
      expect(
        tripStatusOf(
          _trip(start: DateTime(2026, 6, 10), end: DateTime(2026, 6, 20)),
          now: now,
        ),
        TripStatus.inProgress,
      );
    });

    test('past when the end date has passed', () {
      expect(
        tripStatusOf(
          _trip(start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 10)),
          now: now,
        ),
        TripStatus.past,
      );
    });

    test('inProgress when started with no end date', () {
      expect(
        tripStatusOf(_trip(start: DateTime(2026, 6, 1)), now: now),
        TripStatus.inProgress,
      );
    });
  });

  group('daysUntilStart', () {
    test('is null without a start date', () {
      expect(daysUntilStart(_trip(), now: now), isNull);
    });

    test('counts whole days until the start', () {
      expect(daysUntilStart(_trip(start: DateTime(2026, 6, 20)), now: now), 5);
    });

    test('is negative once the trip has started', () {
      expect(daysUntilStart(_trip(start: DateTime(2026, 6, 10)), now: now), -5);
    });
  });
}
