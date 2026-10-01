import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

/// Screen for creating or editing a note. Saves automatically while you
/// type — there's no save button. Shows when it was last edited, and a
/// delete icon that sends the note to trash.
class NoteEditorScreen extends StatefulWidget {
  final Note note;
  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  Timer? _debounce;
  late DateTime _lastEdited;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _bodyController = TextEditingController(text: widget.note.body);
    _lastEdited = widget.note.updatedAt;
  }

  /// Waits half a second after typing stops before saving, so we're not
  /// writing to disk on every keystroke.
  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  void _save() {
    widget.note.title = _titleController.text;
    widget.note.body = _bodyController.text;
    widget.note.updatedAt = DateTime.now();
    notesRepository.saveNote(widget.note);
    if (mounted) setState(() => _lastEdited = widget.note.updatedAt);
  }

  void _delete() {
    notesRepository.moveToTrash(widget.note.id);
    Navigator.pop(context);
  }

  void _toggleFavorite() {
    widget.note.isFavorite = !widget.note.isFavorite;
    notesRepository.saveNote(widget.note);
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _save(); // make sure the last edit is saved when leaving the screen
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.offWhite,
        elevation: 0,
        title: Text(
          'Last edited ${formatFullDate(_lastEdited)}',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.forest.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.note.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.note.isFavorite ? Colors.redAccent : AppTheme.forest.withValues(alpha: 0.6),
            ),
            tooltip: 'Favorite',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.forest.withValues(alpha: 0.6)),
            tooltip: 'Move to trash',
            onPressed: _delete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              onChanged: (_) => _onChanged(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.forest,
              ),
              decoration: InputDecoration(
                hintText: 'Note Title',
                hintStyle: TextStyle(color: AppTheme.forest.withValues(alpha: 0.3)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _bodyController,
                onChanged: (_) => _onChanged(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 16, height: 1.5, color: AppTheme.forest),
                decoration: InputDecoration(
                  hintText: 'Start typing your thoughts here...',
                  hintStyle: TextStyle(color: AppTheme.forest.withValues(alpha: 0.3)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
