import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/note.dart';

/// Copies notes between the local Hive box and the Supabase `notes` table.
/// Errors are thrown, so the screen can show them.
class BackupService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Uploads all local notes (including trash) and removes cloud copies
  /// of notes that no longer exist on this device. Returns notes uploaded.
  Future<int> backup() async {
    final uid = _client.auth.currentUser!.id;
    final notes = notesRepository.getAllNotes();

    final rows = notes
        .map((n) => {
              'id': n.id,
              'user_id': uid,
              'title': n.title,
              'body': n.body,
              'is_pinned': n.isPinned,
              'is_favorite': n.isFavorite,
              'created_at': n.createdAt.toUtc().toIso8601String(),
              'updated_at': n.updatedAt.toUtc().toIso8601String(),
              'deleted_at': n.deletedAt?.toUtc().toIso8601String(),
            })
        .toList();

    for (var i = 0; i < rows.length; i += 200) {
      final end = (i + 200 > rows.length) ? rows.length : i + 200;
      await _client
          .from('notes')
          .upsert(rows.sublist(i, end), onConflict: 'id,user_id');
    }

    // Mirror permanent deletions.
    final remote = await _client.from('notes').select('id').eq('user_id', uid);
    final localIds = notes.map((n) => n.id).toSet();
    final stale = remote
        .map((r) => r['id'] as String)
        .where((id) => !localIds.contains(id))
        .toList();
    if (stale.isNotEmpty) {
      await _client
          .from('notes')
          .delete()
          .eq('user_id', uid)
          .inFilter('id', stale);
    }
    return notes.length;
  }

  /// Downloads cloud notes. A cloud note only replaces the local one if it
  /// is new or more recently edited, so nothing local gets overwritten
  /// by older data. Returns how many notes were added or updated.
  Future<int> restore() async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client.from('notes').select().eq('user_id', uid);

    var changed = 0;
    for (final r in data) {
      final remote = Note(
        id: r['id'] as String,
        title: (r['title'] as String?) ?? '',
        body: (r['body'] as String?) ?? '',
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(r['updated_at'] as String).toLocal(),
        isPinned: (r['is_pinned'] as bool?) ?? false,
        isFavorite: (r['is_favorite'] as bool?) ?? false,
        deletedAt: r['deleted_at'] != null
            ? DateTime.parse(r['deleted_at'] as String).toLocal()
            : null,
      );
      final local = notesRepository.findById(remote.id);
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        await notesRepository.saveNote(remote);
        changed++;
      }
    }
    return changed;
  }
}
