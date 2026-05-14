import 'package:flutter/material.dart';

import '../../data/models/trip_stop.dart';

String formatDate(DateTime? date) {
  if (date == null) return '—';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String formatDateTime(DateTime? date) {
  if (date == null) return '—';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} $hour:$minute';
}

/// A human-readable span for a trip's date range.
String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'No dates';
  if (start != null && end != null) {
    return '${formatDate(start)}  →  ${formatDate(end)}';
  }
  if (start != null) return 'From ${formatDate(start)}';
  return 'Until ${formatDate(end)}';
}

String tripStopTypeLabel(TripStopType type) => switch (type) {
      TripStopType.flight => 'Flight',
      TripStopType.lodging => 'Lodging',
      TripStopType.carRental => 'Car rental',
      TripStopType.train => 'Train',
      TripStopType.activity => 'Activity',
      TripStopType.note => 'Note',
    };

IconData tripStopTypeIcon(TripStopType type) => switch (type) {
      TripStopType.flight => Icons.flight_takeoff_outlined,
      TripStopType.lodging => Icons.hotel_outlined,
      TripStopType.carRental => Icons.directions_car_outlined,
      TripStopType.train => Icons.train_outlined,
      TripStopType.activity => Icons.local_activity_outlined,
      TripStopType.note => Icons.sticky_note_2_outlined,
    };
