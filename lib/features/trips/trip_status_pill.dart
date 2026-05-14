import 'package:flutter/material.dart';

import '../../data/models/trip.dart';
import 'trip_status.dart';

/// A small coloured pill summarising where a trip sits in time.
class TripStatusPill extends StatelessWidget {
  const TripStatusPill({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final status = tripStatusOf(trip);
    final (label, color) = switch (status) {
      TripStatus.undated => ('No dates', Colors.blueGrey),
      TripStatus.upcoming => (_upcomingLabel(), Colors.indigo),
      TripStatus.inProgress => ('In progress', Colors.green),
      TripStatus.past => ('Past', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _upcomingLabel() {
    final days = daysUntilStart(trip);
    if (days == null) return 'Upcoming';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }
}
