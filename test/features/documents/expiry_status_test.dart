import 'package:flutter_test/flutter_test.dart';
import 'package:travelvault/data/models/document.dart';
import 'package:travelvault/features/documents/expiry_status.dart';

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
  final now = DateTime(2026, 1, 1);

  test('no expiry date -> none', () {
    expect(expiryStatusOf(_doc(), now: now), ExpiryStatus.none);
  });

  test('expiry in the past -> expired', () {
    expect(
      expiryStatusOf(_doc(expiry: DateTime(2025, 12, 31)), now: now),
      ExpiryStatus.expired,
    );
  });

  test('expiry within the renewal window -> expiringSoon', () {
    expect(
      expiryStatusOf(_doc(expiry: DateTime(2026, 3, 1)), now: now),
      ExpiryStatus.expiringSoon,
    );
  });

  test('expiry beyond the renewal window -> valid', () {
    expect(
      expiryStatusOf(_doc(expiry: DateTime(2027, 1, 1)), now: now),
      ExpiryStatus.valid,
    );
  });

  test('expiry exactly now counts as expired', () {
    expect(expiryStatusOf(_doc(expiry: now), now: now), ExpiryStatus.expired);
  });
}
