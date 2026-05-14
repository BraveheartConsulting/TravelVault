import 'package:flutter/material.dart';

import '../../data/models/document.dart';

/// Human-readable label for a document type.
String documentTypeLabel(DocumentType type) => switch (type) {
      DocumentType.passport => 'Passport',
      DocumentType.visa => 'Visa',
      DocumentType.idCard => 'ID card',
      DocumentType.ticket => 'Ticket',
      DocumentType.booking => 'Booking',
      DocumentType.insurance => 'Insurance',
      DocumentType.other => 'Other',
    };

/// Icon for a document type, used in lists and detail headers.
IconData documentTypeIcon(DocumentType type) => switch (type) {
      DocumentType.passport => Icons.menu_book_outlined,
      DocumentType.visa => Icons.approval_outlined,
      DocumentType.idCard => Icons.badge_outlined,
      DocumentType.ticket => Icons.confirmation_number_outlined,
      DocumentType.booking => Icons.hotel_outlined,
      DocumentType.insurance => Icons.health_and_safety_outlined,
      DocumentType.other => Icons.description_outlined,
    };

/// Formats a date as `YYYY-MM-DD`, or an em dash when null.
String formatDate(DateTime? date) {
  if (date == null) return '—';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
