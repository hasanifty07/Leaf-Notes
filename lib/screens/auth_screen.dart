import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

/// Login / Sign up screen. Sign up ends with an email OTP verification step.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const int _resendSeconds = 60;

  bool _isLogin = true;
  bool _loading = false;

  // Non-null while waiting for the user to enter the emailed code.
  String? _pendingEmail;
  int _cooldown = 0;
  Timer? _timer;

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();

  final _otp = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.leafDark),
    );
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _handleLogin() async {
    if (_loginEmail.text.trim().isEmpty || _loginPassword.text.isEmpty) {
      _showError('Please fill in both fields.');
      return;
    }
    setState(() => _loading = true);
    final error =
        await authService.login(_loginEmail.text, _loginPassword.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == null) {
      _goToNotes();
    } else {
      _showError(error);
    }
  }

  Future<void> _handleRegister() async {
    if (_regName.text.trim().isEmpty ||
        _regEmail.text.trim().isEmpty ||
        _regPassword.text.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (_regPassword.text.length < 6) {
      _showError('Password should be at least 6 characters.');
      return;
    }
    setState(() => _loading = true);
    final email = _regEmail.text.trim();
    final error = await authService.register(
        _regName.text.trim(), email, _regPassword.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showError(error);
      return;
    }
    // If email confirmation is off in Supabase, we're already logged in.
    if (authService.isLoggedIn) {
      _goToNotes();
      return;
    }
    _otp.clear();
    setState(() => _pendingEmail = email);
    _startCooldown();
    _showInfo('We sent a verification code to $email');
  }

  Future<void> _handleVerify() async {
    final code = _otp.text.trim();
    if (code.length < 6) {
      _showError('Please enter the full code from your email.');
      return;
    }
    setState(() => _loading = true);
    final error = await authService.verifyOtp(_pendingEmail!, code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == null) {
      _goToNotes();
    } else {
      _showError(error);
    }
  }

  Future<void> _handleResend() async {
    if (_cooldown > 0 || _pendingEmail == null) return;
    setState(() => _loading = true);
    final error = await authService.resendOtp(_pendingEmail!);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == null) {
      _startCooldown();
      _showInfo('A new code was sent.');
    } else {
      _showError(error);
    }
  }

  void _cancelVerification() {
    _timer?.cancel();
    setState(() {
      _pendingEmail = null;
      _cooldown = 0;
      _otp.clear();
    });
  }

  void _goToNotes() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verifying = _pendingEmail != null;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.leafDark.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(8),
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
                  const SizedBox(height: 12),
                  const Text(
                    'Leaf Notes',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forest),
                  ),
                  Text(
                    'Capture your thoughts, beautifully.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.forest.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pill-shaped Login / Sign Up tabs (hidden while verifying)
                  if (!verifying) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.mint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _tabButton('Log In', _isLogin,
                                () => setState(() => _isLogin = true)),
                          ),
                          Expanded(
                            child: _tabButton('Sign Up', !_isLogin,
                                () => setState(() => _isLogin = false)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: verifying
                        ? _buildVerifyForm()
                        : (_isLogin ? _buildLoginForm() : _buildRegisterForm()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6)
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: active
                ? AppTheme.forest
                : AppTheme.forest.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.forest.withValues(alpha: 0.3)),
      filled: true,
      fillColor: AppTheme.offWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.mintDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.mintDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.leafLight, width: 2),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.forest.withValues(alpha: 0.7)),
        ),
      );

  Widget _gradientButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.leafDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Email Address'),
        TextField(
          controller: _loginEmail,
          style: const TextStyle(color: AppTheme.forest),
          decoration: _fieldDecoration('you@example.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _label('Password'),
        TextField(
          controller: _loginPassword,
          style: const TextStyle(color: AppTheme.forest),
          decoration: _fieldDecoration('••••••••'),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        _gradientButton('Log In', _handleLogin),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Full Name'),
        TextField(
            controller: _regName,
            style: const TextStyle(color: AppTheme.forest),
            decoration: _fieldDecoration('John Doe')),
        const SizedBox(height: 16),
        _label('Email Address'),
        TextField(
          controller: _regEmail,
          style: const TextStyle(color: AppTheme.forest),
          decoration: _fieldDecoration('you@example.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _label('Password'),
        TextField(
          controller: _regPassword,
          style: const TextStyle(color: AppTheme.forest),
          decoration: _fieldDecoration('Create a password (min 6)'),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        _gradientButton('Create Account', _handleRegister),
      ],
    );
  }

  Widget _buildVerifyForm() {
    return Column(
      key: const ValueKey('verify'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 40, color: AppTheme.leafDark),
        const SizedBox(height: 12),
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.forest),
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a verification code to\n$_pendingEmail',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.forest.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otp,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 8,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
            color: AppTheme.forest,
          ),
          decoration: _fieldDecoration('------').copyWith(counterText: ''),
        ),
        const SizedBox(height: 20),
        _gradientButton('Verify', _handleVerify),
        const SizedBox(height: 8),
        TextButton(
          onPressed: (_cooldown > 0 || _loading) ? null : _handleResend,
          child: Text(
            _cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code',
            style: TextStyle(
              color: _cooldown > 0
                  ? AppTheme.forest.withValues(alpha: 0.4)
                  : AppTheme.leafDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: _loading ? null : _cancelVerification,
          child: Text(
            'Use a different email',
            style: TextStyle(color: AppTheme.forest.withValues(alpha: 0.6)),
          ),
        ),
      ],
    );
  }
}
