import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/notes_repository.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/backup_service.dart';
import 'screens/home_shell.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';

const supabaseUrl = 'https://rqphaseurejuntgsdhnp.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxcGhhc2V1cmVqdW50Z3NkaG5wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0Mzg3NjMsImV4cCI6MjEwNjAxNDc2M30.nGYIaXM5ww0b8Eqg7bseB6e--QKf3Yx0c5xHJLFuPPg';

///Shared instances used by every screen in the app.
final notesRepository = NotesRepository();
final authService = AuthService();
final profileService = ProfileService();
final backupService = BackupService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await notesRepository.init();
  await notesRepository.purgeOldTrash();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const LeafNotesApp());
}

class LeafNotesApp extends StatelessWidget {
  const LeafNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaf Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Skip straight to the app if already logged in on this device.
      home: authService.isLoggedIn ? const HomeShell() : const AuthScreen(),
    );
  }
}
