import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/data/models/document.dart';
import 'package:travelvault/data/models/trip_stop.dart';
import 'package:travelvault/data/repositories/document_repository.dart';
import 'package:travelvault/data/repositories/profile_repository.dart';
import 'package:travelvault/data/repositories/trip_repository.dart';
import 'package:travelvault/features/trips/trip_service.dart';

import '../../support/test_database.dart';

void main() {
  late TestDatabase testDb;
  late TripRepository tripRepository;
  late TripService service;

  setUp(() async {
    testDb = await TestDatabase.open();
    tripRepository = TripRepository(testDb.db);
    service = TripService(repository: tripRepository);
  });

  tearDown(() async {
    await testDb.dispose();
  });

  group('trips', () {
    test('createTrip persists the trip', () async {
      final trip = await service.createTrip(
        name: 'Lisbon',
        destination: 'Portugal',
        startDate: DateTime(2026, 9, 1),
      );

      final loaded = await tripRepository.getById(trip.id);
      expect(loaded, isNotNull);
      expect(loaded!.destination, 'Portugal');
    });

    test('updateTrip writes cleared fields as null', () async {
      final created = await service.createTrip(
        name: 'Lisbon',
        notes: 'original',
      );

      final updated = await service.updateTrip(
        created,
        name: 'Lisbon',
        notes: null,
      );

      expect(updated.notes, isNull);
      expect((await tripRepository.getById(created.id))!.notes, isNull);
    });

    test('deleteTrip cascades to stops and document links', () async {
      final trip = await service.createTrip(name: 'Lisbon');
      await service.addStop(
        tripId: trip.id,
        type: TripStopType.flight,
        title: 'Outbound',
      );

      // A document linked to the trip.
      final profile =
          await ProfileRepository(testDb.db).ensureDefaultProfile();
      final documents = DocumentRepository(testDb.db);
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      await documents.insert(Document(
        id: 'doc-1',
        profileId: profile.id,
        type: DocumentType.passport,
        title: 'Passport',
        createdAt: epoch,
        updatedAt: epoch,
      ));
      await service.linkDocument(trip.id, 'doc-1');

      await service.deleteTrip(trip.id);

      expect(await tripRepository.getById(trip.id), isNull);
      expect(await tripRepository.getStops(trip.id), isEmpty);
      expect(await tripRepository.getLinkedDocuments(trip.id), isEmpty);
      // The document itself survives.
      expect(await documents.getById('doc-1'), isNotNull);
    });
  });

  group('itinerary stops', () {
    test('addStop then getStops returns the stop', () async {
      final trip = await service.createTrip(name: 'Lisbon');
      await service.addStop(
        tripId: trip.id,
        type: TripStopType.lodging,
        title: 'Hotel Baixa',
        location: 'Lisbon',
      );

      final stops = await tripRepository.getStops(trip.id);
      expect(stops, hasLength(1));
      expect(stops.first.title, 'Hotel Baixa');
    });

    test('updateStop changes the type and clears a field', () async {
      final trip = await service.createTrip(name: 'Lisbon');
      final stop = await service.addStop(
        tripId: trip.id,
        type: TripStopType.flight,
        title: 'Flight',
        confirmationNumber: 'ABC123',
      );

      final updated = await service.updateStop(
        stop,
        type: TripStopType.train,
        title: 'Train instead',
        confirmationNumber: null,
      );

      expect(updated.type, TripStopType.train);
      expect(updated.confirmationNumber, isNull);
      expect((await tripRepository.getStops(trip.id)).single.title,
          'Train instead');
    });

    test('deleteStop removes only that stop', () async {
      final trip = await service.createTrip(name: 'Lisbon');
      final keep = await service.addStop(
        tripId: trip.id,
        type: TripStopType.flight,
        title: 'Keep',
      );
      final remove = await service.addStop(
        tripId: trip.id,
        type: TripStopType.activity,
        title: 'Remove',
      );

      await service.deleteStop(remove.id);

      final stops = await tripRepository.getStops(trip.id);
      expect(stops.map((s) => s.id), [keep.id]);
    });
  });

  group('document links', () {
    test('linkDocument then unlinkDocument toggles the link', () async {
      final trip = await service.createTrip(name: 'Lisbon');
      final profile =
          await ProfileRepository(testDb.db).ensureDefaultProfile();
      final documents = DocumentRepository(testDb.db);
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      await documents.insert(Document(
        id: 'doc-1',
        profileId: profile.id,
        type: DocumentType.visa,
        title: 'Visa',
        createdAt: epoch,
        updatedAt: epoch,
      ));

      await service.linkDocument(trip.id, 'doc-1');
      expect(await tripRepository.getLinkedDocuments(trip.id), hasLength(1));

      await service.unlinkDocument(trip.id, 'doc-1');
      expect(await tripRepository.getLinkedDocuments(trip.id), isEmpty);
    });
  });
}
