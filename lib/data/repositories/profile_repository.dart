import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/ids.dart';
import '../models/profile.dart';

/// Data access for [Profile] rows. All queries are parameterized.
class ProfileRepository {
  ProfileRepository(this._db);

  final Database _db;

  static const String _table = 'profiles';

  Future<List<Profile>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'created_at ASC');
    return rows.map(Profile.fromMap).toList(growable: false);
  }

  /// Returns the first profile, creating a default "self" profile if the vault
  /// has none yet. Called once on startup so there is always somewhere to put
  /// documents. Family-profile management arrives in a later increment.
  Future<Profile> ensureDefaultProfile() async {
    final existing = await getAll();
    if (existing.isNotEmpty) return existing.first;

    final now = DateTime.now();
    final profile = Profile(
      id: newId(),
      name: 'Me',
      relationship: 'self',
      createdAt: now,
      updatedAt: now,
    );
    await insert(profile);
    return profile;
  }

  Future<Profile?> getById(String id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Profile.fromMap(rows.first);
  }

  Future<void> insert(Profile profile) async {
    await _db.insert(
      _table,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> update(Profile profile) async {
    await _db.update(
      _table,
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Deletes the profile and — via `ON DELETE CASCADE` — all of its documents.
  Future<void> delete(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
