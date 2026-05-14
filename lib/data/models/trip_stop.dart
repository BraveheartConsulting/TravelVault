/// The kind of itinerary item. Stored as the [name] string so new types can be
/// added without a migration.
enum TripStopType {
  flight,
  lodging,
  carRental,
  train,
  activity,
  note;

  static TripStopType fromName(String value) {
    return TripStopType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TripStopType.note,
    );
  }
}

/// A single entry on a [Trip]'s itinerary timeline.
class TripStop {
  const TripStop({
    required this.id,
    required this.tripId,
    required this.type,
    required this.title,
    this.location,
    this.startsAt,
    this.endsAt,
    this.confirmationNumber,
    this.notes,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tripId;
  final TripStopType type;
  final String title;
  final String? location;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? confirmationNumber;
  final String? notes;

  /// Manual ordering for stops that share (or lack) a timestamp.
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TripStop.fromMap(Map<String, Object?> map) {
    return TripStop(
      id: map['id']! as String,
      tripId: map['trip_id']! as String,
      type: TripStopType.fromName(map['type']! as String),
      title: map['title']! as String,
      location: map['location'] as String?,
      startsAt: _dateFromMillis(map['starts_at'] as int?),
      endsAt: _dateFromMillis(map['ends_at'] as int?),
      confirmationNumber: map['confirmation_number'] as String?,
      notes: map['notes'] as String?,
      sortOrder: map['sort_order']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'type': type.name,
      'title': title,
      'location': location,
      'starts_at': startsAt?.millisecondsSinceEpoch,
      'ends_at': endsAt?.millisecondsSinceEpoch,
      'confirmation_number': confirmationNumber,
      'notes': notes,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  TripStop copyWith({
    TripStopType? type,
    String? title,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    String? confirmationNumber,
    String? notes,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return TripStop(
      id: id,
      tripId: tripId,
      type: type ?? this.type,
      title: title ?? this.title,
      location: location ?? this.location,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _dateFromMillis(int? millis) =>
      millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
}
