import 'dart:convert';

/// The kind of travel document. Stored as the [name] string in the database so
/// new types can be added without a migration.
enum DocumentType {
  passport,
  visa,
  idCard,
  ticket,
  booking,
  insurance,
  other;

  static DocumentType fromName(String value) {
    return DocumentType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => DocumentType.other,
    );
  }
}

/// A single stored travel document belonging to a [Profile].
///
/// [fields] holds structured key/value data (e.g. MRZ-extracted passport
/// fields, a booking reference). [imagePaths] points at encrypted-at-rest image
/// files on the device — the paths, never the image bytes, live in the DB.
class Document {
  const Document({
    required this.id,
    required this.profileId,
    required this.type,
    required this.title,
    this.documentNumber,
    this.issuingCountry,
    this.issueDate,
    this.expiryDate,
    this.fields = const {},
    this.imagePaths = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final DocumentType type;
  final String title;
  final String? documentNumber;
  final String? issuingCountry;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final Map<String, String> fields;
  final List<String> imagePaths;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether the document is expired as of [now].
  bool isExpired({DateTime? now}) {
    final expiry = expiryDate;
    if (expiry == null) return false;
    return expiry.isBefore(now ?? DateTime.now());
  }

  factory Document.fromMap(Map<String, Object?> map) {
    return Document(
      id: map['id']! as String,
      profileId: map['profile_id']! as String,
      type: DocumentType.fromName(map['type']! as String),
      title: map['title']! as String,
      documentNumber: map['document_number'] as String?,
      issuingCountry: map['issuing_country'] as String?,
      issueDate: _dateFromMillis(map['issue_date'] as int?),
      expiryDate: _dateFromMillis(map['expiry_date'] as int?),
      fields: _decodeFields(map['fields'] as String?),
      imagePaths: _decodeImagePaths(map['image_paths'] as String?),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'type': type.name,
      'title': title,
      'document_number': documentNumber,
      'issuing_country': issuingCountry,
      'issue_date': issueDate?.millisecondsSinceEpoch,
      'expiry_date': expiryDate?.millisecondsSinceEpoch,
      'fields': jsonEncode(fields),
      'image_paths': jsonEncode(imagePaths),
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Document copyWith({
    DocumentType? type,
    String? title,
    String? documentNumber,
    String? issuingCountry,
    DateTime? issueDate,
    DateTime? expiryDate,
    Map<String, String>? fields,
    List<String>? imagePaths,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id,
      profileId: profileId,
      type: type ?? this.type,
      title: title ?? this.title,
      documentNumber: documentNumber ?? this.documentNumber,
      issuingCountry: issuingCountry ?? this.issuingCountry,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      fields: fields ?? this.fields,
      imagePaths: imagePaths ?? this.imagePaths,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _dateFromMillis(int? millis) =>
      millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);

  static Map<String, String> _decodeFields(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  static List<String> _decodeImagePaths(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<Object?>;
    return decoded.map((e) => e! as String).toList(growable: false);
  }
}
