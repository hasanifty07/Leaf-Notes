import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

/// One row in the note list — a rounded card with a green accent border
/// when pinned, a title, a preview line, and the last-edited date.
/// Swipe left to send the note to trash.
class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;

  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onPinToggle,
    required this.onFavoriteToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: note.isPinned ? AppTheme.mint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: note.isPinned ? AppTheme.leafLight : Colors.transparent,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.forest.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            note.title.isEmpty ? 'Untitled Note' : note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.forest,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    note.preview.isEmpty ? 'No additional text' : note.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppTheme.forest.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatShortDate(note.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.forest.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  note.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: note.isFavorite
                      ? Colors.redAccent
                      : AppTheme.forest.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: onFavoriteToggle,
              ),
              IconButton(
                icon: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: note.isPinned
                      ? AppTheme.leafDark
                      : AppTheme.forest.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: onPinToggle,
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
