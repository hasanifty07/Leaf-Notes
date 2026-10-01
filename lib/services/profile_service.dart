import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

/// Colors the user can pick for their avatar circle.
const List<Color> avatarColors = [
  AppTheme.leafDark,
  Color(0xFF00897B),
  Color(0xFF5C6BC0),
  Color(0xFFF9A825),
  Color(0xFFEF6C00),
  Color(0xFFD81B60),
];

class UserProfile {
  final String fullName;
  final String bio;
  final int avatarIndex;

  const UserProfile({
    required this.fullName,
    required this.bio,
    required this.avatarIndex,
  });
}

/// Reads / writes the `profiles` table in Supabase.
class ProfileService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<UserProfile> load() async {
    final user = _client.auth.currentUser!;
    final row =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();

    final metaName = user.userMetadata?['name'] as String? ?? '';
    if (row == null) {
      return UserProfile(fullName: metaName, bio: '', avatarIndex: 0);
    }
    final name = (row['full_name'] as String?) ?? '';
    return UserProfile(
      fullName: name.isEmpty ? metaName : name,
      bio: (row['bio'] as String?) ?? '',
      avatarIndex: (row['avatar_index'] as int?) ?? 0,
    );
  }

  Future<void> save({
    required String fullName,
    required String bio,
    required int avatarIndex,
  }) async {
    final user = _client.auth.currentUser!;
    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'bio': bio,
      'avatar_index': avatarIndex,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    // Keep the name stored in auth metadata in sync too.
    await _client.auth.updateUser(UserAttributes(data: {'name': fullName}));
  }

  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
