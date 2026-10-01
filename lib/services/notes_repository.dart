import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

/// Everything about talking to local storage lives in this one class.
/// Screens never touch Hive directly — they only call methods here.
/// If you ever swap Hive for something else, this is the only file
/// that needs to change.
class NotesRepository {
  static const String _boxName = 'notesBox';
  late Box _box;

  Future<void> init() async {
    if (kIsWeb) {
      // Web stores data in the browser (IndexedDB); no folder needed.
      await Hive.initFlutter();
    } else {
      // Desktop/mobile: use the app's private folder instead of
      // Documents (which OneDrive syncs and can lock on Windows).
      final dir = await getApplicationSupportDirectory();
      Hive.init(dir.path);
    }
    _box = await Hive.openBox(_boxName);
  }

  /// Lets widgets automatically rebuild whenever a note changes,
  /// without us having to manually call setState everywhere.
  ValueListenable<Box> listenable() => _box.listenable();

  List<Note> _getAllNotes() {
    return _box.values
        .map((raw) => Note.fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  /// Every note, including ones in the trash (used by backup).
  List<Note> getAllNotes() => _getAllNotes();

  /// Public lookup by id (used by restore).
  Note? findById(String id) => _findById(id);

  /// Active notes (not in trash). Unsorted — the screen applies
  /// whatever sort order the user has chosen (newest, oldest, A-Z, Z-A).
  List<Note> getActiveNotes() {
    return _getAllNotes().where((n) => !n.isInTrash).toList();
  }

  /// Notes currently in the trash, most recently deleted first.
  List<Note> getTrashedNotes() {
    final notes = _getAllNotes().where((n) => n.isInTrash).toList();
    notes.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return notes;
  }

  Future<void> saveNote(Note note) async {
    await _box.put(note.id, note.toMap());
  }

  Future<void> moveToTrash(String id) async {
    final note = _findById(id);
    if (note == null) return;
    note.deletedAt = DateTime.now();
    await saveNote(note);
  }

  Future<void> restoreFromTrash(String id) async {
    final note = _findById(id);
    if (note == null) return;
    note.deletedAt = null;
    await saveNote(note);
  }

  Future<void> deleteForever(String id) async {
    await _box.delete(id);
  }

  /// Call once when the app starts to clear out anything that's been
  /// sitting in the trash for more than 30 days.
  Future<void> purgeOldTrash() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final expired =
        getTrashedNotes().where((n) => n.deletedAt!.isBefore(cutoff)).toList();
    for (final note in expired) {
      await _box.delete(note.id);
    }
  }

  Note? _findById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return Note.fromMap(Map<String, dynamic>.from(raw as Map));
  }
}
