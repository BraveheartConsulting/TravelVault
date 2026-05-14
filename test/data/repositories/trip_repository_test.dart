import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/data/models/document.dart';
import 'package:travelvault/data/models/profile.dart';
import 'package:travelvault/data/models/trip.dart';
import 'package:travelvault/data/models/trip_stop.dart';
import 'package:travelvault/data/repositories/document_repository.dart';
import 'package:travelvault/data/repositories/profile_repository.dart';
import 'package:travelvault/data/repositories/trip_repository.dart';

import '../../support/test_database.dart';

void main() {
  late TestDatabase testDb;
  late TripRepository trips;
  late DocumentRepository documents;
  late ProfileRepository profiles;

  final epoch = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  setUp(() async {
    testDb = await TestDatabase.open();
    trips = TripRepository(testDb.db);
    documents = DocumentRepository(testDb.db);
    profiles = ProfileRepository(testDb.db);
    await profiles.insert(
      Profile(id: 'p1', name: 'Owner', createdAt: epoch, updatedAt: epoch),
    );
  });

  tearDown(() async {
    await testDb.dispose();
  });

  Trip trip(String id) => Trip(
        id: id,
        name: 'Trip $id',
        destination: 'Lisbon',
        startDate: epoch,
        createdAt: epoch,
        updatedAt: epoch,
      );

  test('insert then getById round-trips a trip', () async {
    await trips.insert(trip('t1'));

    final loaded = await trips.getById('t1');

    expect(loaded, isNotNull);
    expect(loaded!.destination, 'Lisbon');
  });

  test('stops are returned ordered by sort order then start time', () async {
    await trips.insert(trip('t1'));
    await trips.insertStop(TripStop(
      id: 's2',
      tripId: 't1',
      type: TripStopType.lodging,
      title: 'Hotel',
      sortOrder: 1,
      createdAt: epoch,
      updatedAt: epoch,
    ));
    await trips.insertStop(TripStop(
      id: 's1',
      tripId: 't1',
      type: TripStopType.flight,
      title: 'Outbound flight',
      sortOrder: 0,
      createdAt: epoch,
      updatedAt: epoch,
    ));

    final stops = await trips.getStops('t1');

    expect(stops.map((s) => s.id), ['s1', 's2']);
  });

  test('linkDocument exposes the document via getLinkedDocuments', () async {
    await trips.insert(trip('t1'));
    await documents.insert(Document(
      id: 'd1',
      profileId: 'p1',
      type: DocumentType.visa,
      title: 'Schengen visa',
      createdAt: epoch,
      updatedAt: epoch,
    ));

    await trips.linkDocument('t1', 'd1');

    final linked = await trips.getLinkedDocuments('t1');
    expect(linked.map((d) => d.id), ['d1']);
  });

  test('linkDocument is idempotent', () async {
    await trips.insert(trip('t1'));
    await documents.insert(Document(
      id: 'd1',
      profileId: 'p1',
      type: DocumentType.ticket,
      title: 'Boarding pass',
      createdAt: epoch,
      updatedAt: epoch,
    ));

    await trips.linkDocument('t1', 'd1');
    await trips.linkDocument('t1', 'd1');

    expect(await trips.getLinkedDocuments('t1'), hasLength(1));
  });

  test('unlinkDocument removes the link but keeps the document', () async {
    await trips.insert(trip('t1'));
    await documents.insert(Document(
      id: 'd1',
      profileId: 'p1',
      type: DocumentType.booking,
      title: 'Hotel booking',
      createdAt: epoch,
      updatedAt: epoch,
    ));
    await trips.linkDocument('t1', 'd1');

    await trips.unlinkDocument('t1', 'd1');

    expect(await trips.getLinkedDocuments('t1'), isEmpty);
    expect(await documents.getById('d1'), isNotNull);
  });

  test('deleting a trip cascades to stops and links only', () async {
    await trips.insert(trip('t1'));
    await documents.insert(Document(
      id: 'd1',
      profileId: 'p1',
      type: DocumentType.passport,
      title: 'Passport',
      createdAt: epoch,
      updatedAt: epoch,
    ));
    await trips.insertStop(TripStop(
      id: 's1',
      tripId: 't1',
      type: TripStopType.flight,
      title: 'Flight',
      createdAt: epoch,
      updatedAt: epoch,
    ));
    await trips.linkDocument('t1', 'd1');

    await trips.delete('t1');

    expect(await trips.getStops('t1'), isEmpty);
    expect(await trips.getLinkedDocuments('t1'), isEmpty);
    // The document itself survives — it belongs to the profile, not the trip.
    expect(await documents.getById('d1'), isNotNull);
  });
}
