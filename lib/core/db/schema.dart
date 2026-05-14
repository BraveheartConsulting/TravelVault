import 'package:sqflite_sqlcipher/sqflite.dart';

/// Current schema version. Bump this and add a branch to [migrate] for every
/// schema change once the app has shipped.
const int kSchemaVersion = 1;

/// Enables foreign key enforcement. Must run on every connection, not just on
/// create — SQLite defaults foreign keys to OFF per-connection.
Future<void> configureDatabase(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

/// Builds the schema on a fresh database.
Future<void> createSchema(Database db) async {
  final batch = db.batch();

  batch.execute('''
    CREATE TABLE profiles (
      id          TEXT    PRIMARY KEY,
      name        TEXT    NOT NULL,
      relationship TEXT,
      avatar_path TEXT,
      created_at  INTEGER NOT NULL,
      updated_at  INTEGER NOT NULL
    )
  ''');

  batch.execute('''
    CREATE TABLE documents (
      id              TEXT    PRIMARY KEY,
      profile_id      TEXT    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      type            TEXT    NOT NULL,
      title           TEXT    NOT NULL,
      document_number TEXT,
      issuing_country TEXT,
      issue_date      INTEGER,
      expiry_date     INTEGER,
      fields          TEXT,
      image_paths     TEXT,
      notes           TEXT,
      created_at      INTEGER NOT NULL,
      updated_at      INTEGER NOT NULL
    )
  ''');

  batch.execute('''
    CREATE TABLE trips (
      id          TEXT    PRIMARY KEY,
      name        TEXT    NOT NULL,
      destination TEXT,
      start_date  INTEGER,
      end_date    INTEGER,
      notes       TEXT,
      created_at  INTEGER NOT NULL,
      updated_at  INTEGER NOT NULL
    )
  ''');

  batch.execute('''
    CREATE TABLE trip_stops (
      id                  TEXT    PRIMARY KEY,
      trip_id             TEXT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      type                TEXT    NOT NULL,
      title               TEXT    NOT NULL,
      location            TEXT,
      starts_at           INTEGER,
      ends_at             INTEGER,
      confirmation_number TEXT,
      notes               TEXT,
      sort_order          INTEGER NOT NULL DEFAULT 0,
      created_at          INTEGER NOT NULL,
      updated_at          INTEGER NOT NULL
    )
  ''');

  batch.execute('''
    CREATE TABLE trip_documents (
      trip_id     TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
      PRIMARY KEY (trip_id, document_id)
    )
  ''');

  batch.execute(
    'CREATE INDEX idx_documents_profile_id ON documents(profile_id)',
  );
  batch.execute(
    'CREATE INDEX idx_documents_expiry_date ON documents(expiry_date)',
  );
  batch.execute('CREATE INDEX idx_trip_stops_trip_id ON trip_stops(trip_id)');
  batch.execute(
    'CREATE INDEX idx_trip_documents_document_id ON trip_documents(document_id)',
  );

  await batch.commit(noResult: true);
}

/// Applies migrations when an existing database is older than [kSchemaVersion].
/// No-op today since v1 is the first shipped schema; future versions add
/// `if (oldVersion < N)` branches here.
Future<void> migrate(Database db, int oldVersion, int newVersion) async {
  // Intentionally empty until the second schema version ships.
}
