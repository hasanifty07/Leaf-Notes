import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/note_tile.dart';
import 'note_editor_screen.dart';
import 'trash_screen.dart';
import 'auth_screen.dart';

/// The order notes can be listed in. Pinned notes always float to the
/// top regardless of which of these is chosen.
enum SortOption { newest, oldest, titleAZ, titleZA }

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _showFavoritesOnly = false;
  SortOption _sortOption = SortOption.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Pinned notes always come first; within each group, sort by
  /// whichever option the user picked.
  int _compareNotes(Note a, Note b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    switch (_sortOption) {
      case SortOption.newest:
        return b.updatedAt.compareTo(a.updatedAt);
      case SortOption.oldest:
        return a.updatedAt.compareTo(b.updatedAt);
      case SortOption.titleAZ:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case SortOption.titleZA:
        return b.title.toLowerCase().compareTo(a.title.toLowerCase());
    }
  }

  String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return 'Date modified (newest)';
      case SortOption.oldest:
        return 'Date modified (oldest)';
      case SortOption.titleAZ:
        return 'Name (A–Z)';
      case SortOption.titleZA:
        return 'Name (Z–A)';
    }
  }

  Future<void> _logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header: logo + app name + trash icon
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppTheme.mintDark),
                    ),
                    child: Image.asset(
                      'assets/icon/adaptive_foreground.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Leaf Notes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forest,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort, color: AppTheme.forest),
                    tooltip: 'Sort',
                    onSelected: (option) => setState(() => _sortOption = option),
                    itemBuilder: (context) => SortOption.values.map((option) {
                      return PopupMenuItem(
                        value: option,
                        child: Row(
                          children: [
                            if (option == _sortOption)
                              const Icon(Icons.check, size: 18, color: AppTheme.leafDark)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(_sortLabel(option)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.forest),
                    tooltip: 'Trash',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrashScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppTheme.forest),
                    tooltip: 'Log out',
                    onPressed: _logout,
                  ),
                ],
              ),
            ),

            // Prominent "New Note" button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openEditor(null),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'New Note',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.leafDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.mintDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.mintDark),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value.toLowerCase()),
              ),
            ),
            const SizedBox(height: 8),

            // Filter: All notes vs. Favorites only
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !_showFavoritesOnly,
                    onSelected: (_) => setState(() => _showFavoritesOnly = false),
                    selectedColor: AppTheme.mint,
                    labelStyle: TextStyle(
                      color: AppTheme.forest,
                      fontWeight: !_showFavoritesOnly ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: const BorderSide(color: AppTheme.mintDark),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.favorite,
                      size: 16,
                      color: _showFavoritesOnly ? Colors.redAccent : AppTheme.forest.withValues(alpha: 0.4),
                    ),
                    label: const Text('Favorites'),
                    selected: _showFavoritesOnly,
                    onSelected: (_) => setState(() => _showFavoritesOnly = true),
                    selectedColor: AppTheme.mint,
                    labelStyle: TextStyle(
                      color: AppTheme.forest,
                      fontWeight: _showFavoritesOnly ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: const BorderSide(color: AppTheme.mintDark),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Note list — rebuilds automatically whenever data changes.
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: notesRepository.listenable(),
                builder: (context, Box box, _) {
                  var notes = notesRepository.getActiveNotes();

                  if (_showFavoritesOnly) {
                    notes = notes.where((n) => n.isFavorite).toList();
                  }

                  if (_query.isNotEmpty) {
                    notes = notes.where((n) {
                      return n.title.toLowerCase().contains(_query) ||
                          n.body.toLowerCase().contains(_query);
                    }).toList();
                  }

                  notes.sort(_compareNotes);

                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined,
                              size: 64, color: AppTheme.mintDark),
                          const SizedBox(height: 12),
                          Text(
                            _query.isNotEmpty
                                ? 'No notes match your search.'
                                : _showFavoritesOnly
                                    ? 'No favorites yet.\nTap the heart on a note to add one.'
                                    : 'No notes yet.\nTap "New Note" to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.forest.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteTile(
                        note: note,
                        onTap: () => _openEditor(note),
                        onPinToggle: () {
                          note.isPinned = !note.isPinned;
                          notesRepository.saveNote(note);
                        },
                        onFavoriteToggle: () {
                          note.isFavorite = !note.isFavorite;
                          notesRepository.saveNote(note);
                        },
                        onDelete: () => notesRepository.moveToTrash(note.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(Note? existing) {
    final note = existing ??
        Note(
          id: const Uuid().v4(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
  }
}
