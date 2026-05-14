import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/document.dart';
import '../models/trip.dart';
import '../models/trip_stop.dart';

/// Data access for [Trip] rows, their [TripStop] itinerary items, and the
/// trip ↔ document links. All queries are parameterized.
class TripRepository {
  TripRepository(this._db);

  final Database _db;

  static const String _trips = 'trips';
  static const String _stops = 'trip_stops';
  static const String _tripDocuments = 'trip_documents';
  static const String _documents = 'documents';

  // --- Trips ---------------------------------------------------------------

  Future<List<Trip>> getAll() async {
    final rows = await _db.query(_trips, orderBy: 'start_date DESC');
    return rows.map(Trip.fromMap).toList(growable: false);
  }

  Future<Trip?> getById(String id) async {
    final rows = await _db.query(
      _trips,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Trip.fromMap(rows.first);
  }

  Future<void> insert(Trip trip) async {
    await _db.insert(
      _trips,
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> update(Trip trip) async {
    await _db.update(
      _trips,
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  /// Deletes the trip and — via `ON DELETE CASCADE` — its stops and document
  /// links. The linked documents themselves are not deleted.
  Future<void> delete(String id) async {
    await _db.delete(_trips, where: 'id = ?', whereArgs: [id]);
  }

  // --- Itinerary stops -----------------------------------------------------

  Future<List<TripStop>> getStops(String tripId) async {
    final rows = await _db.query(
      _stops,
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'sort_order ASC, starts_at ASC',
    );
    return rows.map(TripStop.fromMap).toList(growable: false);
  }

  Future<void> insertStop(TripStop stop) async {
    await _db.insert(
      _stops,
      stop.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateStop(TripStop stop) async {
    await _db.update(
      _stops,
      stop.toMap(),
      where: 'id = ?',
      whereArgs: [stop.id],
    );
  }

  Future<void> deleteStop(String id) async {
    await _db.delete(_stops, where: 'id = ?', whereArgs: [id]);
  }

  // --- Trip ↔ document links ----------------------------------------------

  Future<void> linkDocument(String tripId, String documentId) async {
    await _db.insert(_tripDocuments, {
      'trip_id': tripId,
      'document_id': documentId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> unlinkDocument(String tripId, String documentId) async {
    await _db.delete(
      _tripDocuments,
      where: 'trip_id = ? AND document_id = ?',
      whereArgs: [tripId, documentId],
    );
  }

  Future<List<Document>> getLinkedDocuments(String tripId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT d.* FROM $_documents d
      INNER JOIN $_tripDocuments td ON td.document_id = d.id
      WHERE td.trip_id = ?
      ORDER BY d.updated_at DESC
      ''',
      [tripId],
    );
    return rows.map(Document.fromMap).toList(growable: false);
  }
}
