import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import 'note_editor_screen.dart';

/// Overview of your notes: counts, words, streak, last-7-days activity
/// and recently edited notes. All computed from local data.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _words(String s) {
    final t = s.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: notesRepository.listenable(),
          builder: (context, Box box, _) {
            final active = notesRepository.getActiveNotes();
            final trashed = notesRepository.getTrashedNotes();
            final pinned = active.where((n) => n.isPinned).length;
            final favorites = active.where((n) => n.isFavorite).length;
            final totalWords =
                active.fold<int>(0, (sum, n) => sum + _words(n.body));
            final avgWords =
                active.isEmpty ? 0 : (totalWords / active.length).round();

            // Days with activity (a note created or edited).
            final today = _day(DateTime.now());
            final activeDays = <DateTime>{};
            for (final n in active) {
              activeDays.add(_day(n.createdAt));
              activeDays.add(_day(n.updatedAt));
            }

            // Writing streak: consecutive days ending today (or yesterday).
            var streak = 0;
            var cursor = today;
            if (!activeDays.contains(cursor)) {
              cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
            }
            while (activeDays.contains(cursor)) {
              streak++;
              cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
            }

            // Last 7 days, oldest first.
            final week = List.generate(
              7,
              (i) => DateTime(today.year, today.month, today.day - (6 - i)),
            );
            final counts = week
                .map((d) => active.where((n) => _day(n.updatedAt) == d).length)
                .toList();
            final maxCount = counts.reduce((a, b) => a > b ? a : b);

            final recent = [...active]
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final recent3 = recent.take(3).toList();

            final name = authService.currentUserName;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name == null || name.isEmpty
                      ? 'Here is your writing at a glance.'
                      : 'Hi $name, here is your writing at a glance.',
                  style:
                      TextStyle(color: AppTheme.forest.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),

                // Streak banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.leafDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.white, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              streak == 1
                                  ? '1 day streak'
                                  : '$streak day streak',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              streak == 0
                                  ? 'Write or edit a note today to start one!'
                                  : 'Keep writing every day to grow it.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stat cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.description_outlined,
                        label: 'Notes',
                        value: '${active.length}',
                        color: AppTheme.leafDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.push_pin_outlined,
                        label: 'Pinned',
                        value: '$pinned',
                        color: AppTheme.leafDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.favorite_border,
                        label: 'Favorites',
                        value: '$favorites',
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.delete_outline,
                        label: 'In trash',
                        value: '${trashed.length}',
                        color: AppTheme.forest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.edit_note,
                        label: 'Total words',
                        value: '$totalWords',
                        color: AppTheme.leafDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bar_chart,
                        label: 'Avg words/note',
                        value: '$avgWords',
                        color: AppTheme.leafDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Last 7 days chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last 7 days',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.forest,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notes edited per day',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.forest.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (i) {
                            final c = counts[i];
                            final isToday = i == 6;
                            final barHeight =
                                maxCount == 0 ? 6.0 : 6.0 + 74.0 * c / maxCount;
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (c > 0)
                                    Text(
                                      '$c',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.forest,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: barHeight,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: c == 0
                                          ? AppTheme.mintDark
                                          : (isToday
                                              ? AppTheme.leafDark
                                              : AppTheme.leafLight),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _weekdayLetters[week[i].weekday - 1],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isToday
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: AppTheme.forest
                                          .withValues(alpha: isToday ? 1 : 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Recently edited
                const Text(
                  'Recently edited',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.forest,
                  ),
                ),
                const SizedBox(height: 8),
                if (recent3.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No notes yet.',
                      style: TextStyle(
                          color: AppTheme.forest.withValues(alpha: 0.5)),
                    ),
                  )
                else
                  ...recent3.map((n) => _RecentTile(note: n)),
              ],
            );
          },
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppTheme.forest.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.mint,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forest,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.forest.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final Note note;
  const _RecentTile({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          note.title.isEmpty ? 'Untitled Note' : note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.forest,
          ),
        ),
        subtitle: Text(
          note.preview.isEmpty ? 'No additional text' : note.preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.forest.withValues(alpha: 0.6)),
        ),
        trailing: Text(
          formatShortDate(note.updatedAt),
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.forest.withValues(alpha: 0.4),
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
        ),
      ),
    );
  }
}
