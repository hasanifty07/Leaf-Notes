import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth so login works from ANY device. Registration uses
/// an emailed one-time code (OTP) to verify the email address.
class AuthService {
  final _client = Supabase.instance.client;

  bool get isLoggedIn => _client.auth.currentSession != null;

  String? get currentUserEmail => _client.auth.currentUser?.email;

  String? get currentUserName =>
      _client.auth.currentUser?.userMetadata?['name'] as String?;

  /// Creates the account and emails a verification code.
  /// Returns null on success, or an error message to show the user.
  Future<String?> register(String name, String email, String password) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
      // Supabase hides "already registered" by returning a user with no
      // identities, so detect that case here.
      final identities = res.user?.identities;
      if (identities != null && identities.isEmpty) {
        return 'This email is already registered. Please log in.';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Checks the 6-digit code from the email. On success the user is
  /// logged in automatically. Returns null on success, or an error.
  Future<String?> verifyOtp(String email, String code) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.signup,
        email: email.trim(),
        token: code.trim(),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Sends a fresh code. Returns null on success, or an error.
  Future<String?> resendOtp(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email.trim());
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Returns null on success, or an error message to show the user.
  Future<String?> login(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
