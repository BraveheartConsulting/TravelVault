/// A person whose travel documents are stored in the vault — the device owner
/// or a family member they manage.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.relationship,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// e.g. "self", "spouse", "child". Free-form; null for the primary profile.
  final String? relationship;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Profile.fromMap(Map<String, Object?> map) {
    return Profile(
      id: map['id']! as String,
      name: map['name']! as String,
      relationship: map['relationship'] as String?,
      avatarPath: map['avatar_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'avatar_path': avatarPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Profile copyWith({
    String? name,
    String? relationship,
    String? avatarPath,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.name == name &&
      other.relationship == relationship &&
      other.avatarPath == avatarPath &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, relationship, avatarPath, createdAt, updatedAt);
}
