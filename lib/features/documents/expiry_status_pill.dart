import 'package:flutter/material.dart';

import '../../data/models/document.dart';
import 'expiry_status.dart';

/// A small coloured pill summarising a document's expiry state.
class ExpiryStatusPill extends StatelessWidget {
  const ExpiryStatusPill({super.key, required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final status = expiryStatusOf(document);
    final (label, color) = switch (status) {
      ExpiryStatus.none => ('No expiry', Colors.blueGrey),
      ExpiryStatus.valid => ('Valid', Colors.green),
      ExpiryStatus.expiringSoon => ('Expiring soon', Colors.orange),
      ExpiryStatus.expired => ('Expired', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
