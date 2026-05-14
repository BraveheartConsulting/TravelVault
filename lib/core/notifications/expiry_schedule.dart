import '../../data/models/document.dart';

/// How far ahead of a document's expiry the user is warned.
const Duration kExpiryLeadTime = Duration(days: 30);

/// A stable, non-negative 31-bit notification id derived from a document id.
/// Lets a document's pending alert be cancelled or replaced without tracking
/// notification ids separately.
int notificationIdFor(String documentId) => documentId.hashCode & 0x7fffffff;

/// When the expiry alert for [document] should fire — [kExpiryLeadTime] before
/// its expiry date.
///
/// Returns null when the document has no expiry date, or when the alert time
/// is already in the past relative to [now] (nothing to schedule).
DateTime? expiryAlertTime(
  Document document, {
  DateTime? now,
  Duration leadTime = kExpiryLeadTime,
}) {
  final expiry = document.expiryDate;
  if (expiry == null) return null;

  final alertAt = expiry.subtract(leadTime);
  final reference = now ?? DateTime.now();
  if (!alertAt.isAfter(reference)) return null;
  return alertAt;
}
