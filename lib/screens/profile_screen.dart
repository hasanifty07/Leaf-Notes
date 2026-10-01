import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// Profile: view / edit name, bio & avatar color, cloud backup & restore,
/// change password, log out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  int _avatarIndex = 0;

  // Last saved values (used for view mode and for Cancel).
  String _savedName = '';
  String _savedBio = '';
  int _savedAvatarIndex = 0;

  bool _editing = false;
  bool _loading = true;
  bool _saving = false;
  bool _backingUp = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  String _err(Object e) => e is PostgrestException
      ? e.message
      : (e is AuthException ? e.message : e.toString());

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade400 : AppTheme.leafDark,
      ),
    );
  }

  Future<void> _load() async {
    try {
      final p = await profileService.load();
      _savedName = p.fullName;
      _savedBio = p.bio;
      _savedAvatarIndex = p.avatarIndex.clamp(0, avatarColors.length - 1);
    } catch (_) {
      _savedName = authService.currentUserName ?? '';
    }
    _name.text = _savedName;
    _bio.text = _savedBio;
    _avatarIndex = _savedAvatarIndex;
    if (!mounted) return;
    setState(() {
      _loading = false;
      // New users with no name go straight to edit mode.
      _editing = _savedName.trim().isEmpty;
    });
  }

  void _startEditing() {
    setState(() {
      _name.text = _savedName;
      _bio.text = _savedBio;
      _avatarIndex = _savedAvatarIndex;
      _editing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _name.text = _savedName;
      _bio.text = _savedBio;
      _avatarIndex = _savedAvatarIndex;
      _editing = false;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _snack('Please enter your name.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await profileService.save(
        fullName: _name.text.trim(),
        bio: _bio.text.trim(),
        avatarIndex: _avatarIndex,
      );
      _savedName = _name.text.trim();
      _savedBio = _bio.text.trim();
      _savedAvatarIndex = _avatarIndex;
      if (mounted) setState(() => _editing = false);
      _snack('Profile saved');
    } catch (e) {
      _snack(_err(e), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    try {
      final n = await backupService.backup();
      _snack('Backed up $n note${n == 1 ? '' : 's'} to the cloud');
    } catch (e) {
      _snack(_err(e), error: true);
    }
    if (mounted) setState(() => _backingUp = false);
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final n = await backupService.restore();
      _snack(n == 0
          ? 'Everything is already up to date'
          : 'Restored $n note${n == 1 ? '' : 's'}');
    } catch (e) {
      _snack(_err(e), error: true);
    }
    if (mounted) setState(() => _restoring = false);
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New password (min 6)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newPassword == null) return;
    if (newPassword.length < 6) {
      _snack('Password must be at least 6 characters.', error: true);
      return;
    }
    try {
      await profileService.changePassword(newPassword);
      _snack('Password updated');
    } catch (e) {
      _snack(_err(e), error: true);
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

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
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
      );

  BoxDecoration _card() => BoxDecoration(
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

  ButtonStyle _primaryButton() => ElevatedButton.styleFrom(
        backgroundColor: AppTheme.leafDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  ButtonStyle _outlineButton() => OutlinedButton.styleFrom(
        foregroundColor: AppTheme.leafDark,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppTheme.leafDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  /// Bio shown as plain text in view mode (same spot as the bio field).
  Widget _bioView() {
    final hasBio = _savedBio.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 20, color: AppTheme.forest.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasBio ? _savedBio : 'No bio yet',
              style: TextStyle(
                fontSize: 15,
                color: hasBio
                    ? AppTheme.forest
                    : AppTheme.forest.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = authService.currentUserEmail ?? '';
    final shownName = _editing ? _name.text.trim() : _savedName.trim();
    final initial = shownName.isNotEmpty ? shownName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.leafDark))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forest,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Avatar + name + email
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _card(),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: avatarColors[_avatarIndex],
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!_editing && _savedName.trim().isNotEmpty) ...[
                          Text(
                            _savedName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.forest,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          email,
                          style: TextStyle(
                            color: AppTheme.forest.withValues(alpha: 0.6),
                          ),
                        ),
                        if (_editing) ...[
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(avatarColors.length, (i) {
                              final selected = i == _avatarIndex;
                              return GestureDetector(
                                onTap: () => setState(() => _avatarIndex = i),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: avatarColors[i],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? AppTheme.forest
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_editing) ...[
                    // Edit mode
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Your name', Icons.person_outline),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bio,
                      maxLines: 3,
                      maxLength: 120,
                      decoration: _dec('A short bio', Icons.info_outline),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: _primaryButton(),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save profile',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    // Only show Cancel if there's a saved profile to go back to.
                    if (_savedName.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _saving ? null : _cancelEditing,
                        style: _outlineButton(),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    ],
                  ] else ...[
                    // View mode
                    _bioView(),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _startEditing,
                      style: _outlineButton(),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Edit profile',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Backup & restore
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_outlined,
                                color: AppTheme.leafDark),
                            SizedBox(width: 8),
                            Text(
                              'Cloud backup',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.forest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Back up your notes to your account, and restore them on any device.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.forest.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    (_backingUp || _restoring) ? null : _backup,
                                style: _primaryButton(),
                                icon: _backingUp
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(Icons.cloud_upload_outlined),
                                label: const Text('Back up'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: (_backingUp || _restoring)
                                    ? null
                                    : _restore,
                                style: _outlineButton(),
                                icon: _restoring
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.leafDark),
                                      )
                                    : const Icon(Icons.cloud_download_outlined),
                                label: const Text('Restore'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Account actions
                  Container(
                    decoration: _card(),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline,
                              color: AppTheme.forest),
                          title: const Text('Change password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _changePassword,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading:
                              Icon(Icons.logout, color: Colors.red.shade400),
                          title: Text('Log out',
                              style: TextStyle(color: Colors.red.shade400)),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
