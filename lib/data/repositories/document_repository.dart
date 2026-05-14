import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/document.dart';

/// Data access for [Document] rows. All queries are parameterized.
class DocumentRepository {
  DocumentRepository(this._db);

  final Database _db;

  static const String _table = 'documents';

  Future<List<Document>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'updated_at DESC');
    return rows.map(Document.fromMap).toList(growable: false);
  }

  Future<List<Document>> getByProfile(String profileId) async {
    final rows = await _db.query(
      _table,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Document.fromMap).toList(growable: false);
  }

  Future<Document?> getById(String id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Document.fromMap(rows.first);
  }

  /// Documents whose expiry falls on or before [cutoff], soonest first.
  /// Drives the expiry-alert feature in a later increment.
  Future<List<Document>> getExpiringBefore(DateTime cutoff) async {
    final rows = await _db.query(
      _table,
      where: 'expiry_date IS NOT NULL AND expiry_date <= ?',
      whereArgs: [cutoff.millisecondsSinceEpoch],
      orderBy: 'expiry_date ASC',
    );
    return rows.map(Document.fromMap).toList(growable: false);
  }

  Future<void> insert(Document document) async {
    await _db.insert(
      _table,
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> update(Document document) async {
    await _db.update(
      _table,
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
