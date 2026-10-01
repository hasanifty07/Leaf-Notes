import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';

/// Shows deleted notes. Notes here can be restored or removed for good.
/// Anything older than 30 days is auto-purged on app start
/// (see NotesRepository.purgeOldTrash).
class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: ValueListenableBuilder(
        valueListenable: notesRepository.listenable(),
        builder: (context, Box box, _) {
          final notes = notesRepository.getTrashedNotes();

          if (notes.isEmpty) {
            return const Center(child: Text('Trash is empty'));
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title.isEmpty ? 'Untitled' : note.title),
                subtitle: Text(note.preview),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Restore',
                      onPressed: () => notesRepository.restoreFromTrash(note.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      tooltip: 'Delete forever',
                      onPressed: () => notesRepository.deleteForever(note.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
