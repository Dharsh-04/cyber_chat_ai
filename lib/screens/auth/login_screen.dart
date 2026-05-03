// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../admin/admin_dashboard.dart';
import '../chat/users_list_screen.dart';

// Admin credentials — hardcoded
const String _adminUser = 'admin';
const String _adminPass = 'admin@safechat123';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Login fields
  final _lUser = TextEditingController();
  final _lPass = TextEditingController();

  // Register fields
  final _rUser  = TextEditingController();
  final _rEmail = TextEditingController();
  final _rPass  = TextEditingController();
  final _rPass2 = TextEditingController();

  bool    _busy = false;
  String? _err;

  static const bg      = Color(0xFF0A0E21);
  static const surface = Color(0xFF1A1F38);
  static const accent  = Color(0xFF4F8EF7);
  static const danger  = Color(0xFFFF5C5C);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _err = null));
  }

  @override
  void dispose() {
    _tab.dispose();
    _lUser.dispose(); _lPass.dispose();
    _rUser.dispose(); _rEmail.dispose();
    _rPass.dispose(); _rPass2.dispose();
    super.dispose();
  }

  void _go(UserModel user) {
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => UsersListScreen(me: user)));
  }

Future<void> _login() async {
  setState(() { _busy = true; _err = null; });

  final username = _lUser.text.trim();
  final password = _lPass.text.trim();

  // ── Admin check FIRST ────────────────────────────────────────
  if (username == 'admin' && password == 'admin@safechat123') {
    setState(() => _busy = false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboard()),
    );
    return;  // ← stops here, never goes to users list
  }

  // ── Regular user ─────────────────────────────────────────────
  final user = await SupabaseService.login(username, password);
  setState(() => _busy = false);

  if (user != null) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => UsersListScreen(me: user)),
    );
  } else {
    setState(() => _err = 'Invalid credentials or account is blocked');
  }
}

  Future<void> _register() async {
    if (_rUser.text.trim().length < 3) {
      setState(() => _err = 'Username must be at least 3 characters');
      return;
    }
    if (!_rEmail.text.contains('@')) {
      setState(() => _err = 'Enter a valid email address');
      return;
    }
    if (_rPass.text != _rPass2.text) {
      setState(() => _err = 'Passwords do not match');
      return;
    }
    setState(() { _busy = true; _err = null; });

    final user = await SupabaseService.register(
        _rUser.text.trim(), _rPass.text.trim(), _rEmail.text.trim());
    setState(() => _busy = false);

    if (user != null) {
      _go(user);
    } else {
      setState(() => _err = 'Username already taken');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const SizedBox(height: 60),

            // Logo
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(
                  color: accent.withOpacity(0.35),
                  blurRadius: 28, spreadRadius: 2,
                )],
              ),
              child: const Icon(Icons.shield_rounded,
                  color: accent, size: 42),
            ),
            const SizedBox(height: 18),

            Text('SafeChat',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 30,
                fontWeight: FontWeight.w700, letterSpacing: -0.5,
              )),
            const SizedBox(height: 4),
            Text('AI-powered safe messaging',
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 40),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Login'),
                  Tab(text: 'Register'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tab,
                children: [_loginForm(), _registerForm()],
              ),
            ),

            if (_err != null) ...[
              const SizedBox(height: 4),
              Text(_err!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: danger, fontSize: 13)),
            ],
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _loginForm() => Column(children: [
    _field(_lUser, 'Username', Icons.person_outline),
    const SizedBox(height: 14),
    _field(_lPass, 'Password', Icons.lock_outline, obscure: true),
    const SizedBox(height: 24),
    _btn('Login', _login),
  ]);

  Widget _registerForm() => Column(children: [
    _field(_rUser, 'Username', Icons.person_outline),
    const SizedBox(height: 14),
    _field(_rEmail, 'Email address', Icons.email_outlined),
    const SizedBox(height: 14),
    _field(_rPass, 'Password', Icons.lock_outline, obscure: true),
    const SizedBox(height: 14),
    _field(_rPass2, 'Confirm Password', Icons.lock_outline, obscure: true),
    const SizedBox(height: 24),
    _btn('Create Account', _register),
  ]);

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool obscure = false}) =>
    TextField(
      controller : c,
      obscureText: obscure,
      keyboardType: hint.contains('Email')
          ? TextInputType.emailAddress
          : TextInputType.text,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText  : hint,
        hintStyle : GoogleFonts.inter(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        filled    : true,
        fillColor : surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 18, horizontal: 16),
      ),
    );

  Widget _btn(String label, VoidCallback fn) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton(
      onPressed: _busy ? null : fn,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        disabledBackgroundColor: accent.withOpacity(0.4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: _busy
        ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
        : Text(label,
            style: GoogleFonts.inter(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w600)),
    ),
  );
}