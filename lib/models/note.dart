/// A single note.
///
/// This is a plain Dart class — no special Hive annotations or generated
/// code needed. We just turn it into a Map to save it, and rebuild it
/// from a Map when we load it back. Simple and easy to follow.
class Note {
  final String id;
  String title;
  String body;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  bool isFavorite;

  /// null = active note. A timestamp here means "in the trash since...".
  DateTime? deletedAt;

  Note({
    required this.id,
    this.title = '',
    this.body = '',
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isFavorite = false,
    this.deletedAt,
  });

  bool get isInTrash => deletedAt != null;

  /// A short one-line preview of the body, shown in the note list.
  String get preview {
    final oneLine = body.replaceAll('\n', ' ').trim();
    if (oneLine.length <= 80) return oneLine;
    return '${oneLine.substring(0, 80)}...';
  }

  /// Turns this note into a Map so it can be saved to Hive.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  /// Rebuilds a Note from the Map that Hive gives back.
  factory Note.fromMap(Map map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isPinned: map['isPinned'] as bool? ?? false,
      isFavorite: map['isFavorite'] as bool? ?? false,
      deletedAt: map['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'] as int)
          : null,
    );
  }
}
