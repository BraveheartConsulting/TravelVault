import '../../data/models/document.dart';

/// Traffic-light expiry state for a document, used to colour the vault list.
enum ExpiryStatus {
  /// No expiry date on this document type (e.g. a booking confirmation).
  none,

  /// Valid, with comfortable runway before expiry.
  valid,

  /// Valid, but inside the renewal window — show amber.
  expiringSoon,

  /// Past its expiry date — show red.
  expired,
}

/// How far before expiry a document is flagged amber. Six months is the
/// commonly required passport validity buffer for international entry.
const Duration kExpiringSoonWindow = Duration(days: 180);

ExpiryStatus expiryStatusOf(Document document, {DateTime? now}) {
  final expiry = document.expiryDate;
  if (expiry == null) return ExpiryStatus.none;

  final reference = now ?? DateTime.now();
  if (!expiry.isAfter(reference)) return ExpiryStatus.expired;
  if (expiry.isBefore(reference.add(kExpiringSoonWindow))) {
    return ExpiryStatus.expiringSoon;
  }
  return ExpiryStatus.valid;
}
