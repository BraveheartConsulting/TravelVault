import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/core/notifications/expiry_schedule.dart';
import 'package:travelvault/data/models/document.dart';

Document _doc({DateTime? expiry}) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return Document(
    id: 'doc-1',
    profileId: 'p-1',
    type: DocumentType.passport,
    title: 'Passport',
    expiryDate: expiry,
    createdAt: epoch,
    updatedAt: epoch,
  );
}

void main() {
  test('alert fires the lead time before expiry', () {
    final alert = expiryAlertTime(
      _doc(expiry: DateTime(2030, 1, 31)),
      now: DateTime(2029, 1, 1),
    );
    expect(alert, DateTime(2030, 1, 1));
  });

  test('no alert when the document has no expiry date', () {
    expect(expiryAlertTime(_doc(), now: DateTime(2029, 1, 1)), isNull);
  });

  test('no alert when the alert time is already in the past', () {
    final alert = expiryAlertTime(
      _doc(expiry: DateTime(2030, 1, 31)),
      now: DateTime(2030, 1, 15),
    );
    expect(alert, isNull);
  });

  test('respects a custom lead time', () {
    final alert = expiryAlertTime(
      _doc(expiry: DateTime(2030, 1, 31)),
      now: DateTime(2029, 1, 1),
      leadTime: const Duration(days: 10),
    );
    expect(alert, DateTime(2030, 1, 21));
  });

  test('notificationIdFor is stable and non-negative', () {
    expect(notificationIdFor('doc-1'), notificationIdFor('doc-1'));
    expect(notificationIdFor('doc-1'), greaterThanOrEqualTo(0));
    expect(notificationIdFor('doc-1'), isNot(notificationIdFor('doc-2')));
  });
}
