// lib/screens/chat/users_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatefulWidget {
  final UserModel me;
  const UsersListScreen({super.key, required this.me});
  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  static const bg      = Color(0xFF0A0E21);
  static const surface = Color(0xFF1A1F38);
  static const accent  = Color(0xFF4F8EF7);
  static const danger  = Color(0xFFFF5C5C);

  List<UserModel> _users   = [];
  bool            _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await SupabaseService.getOtherUsers(widget.me.id);
    setState(() { _users = users; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor       : bg,
        elevation             : 0,
        automaticallyImplyLeading: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SafeChat',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w700)),
            Text('Hi, ${widget.me.username} 👋',
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 12)),
          ]),
        actions: [
          // Logout only — no admin button for regular users
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white38),
            tooltip : 'Logout',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),

      body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: accent))
        : _users.isEmpty
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline,
                    color: Colors.white12, size: 52),
                const SizedBox(height: 14),
                Text('No other users yet',
                  style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Register another account to chat',
                  style: GoogleFonts.inter(
                    color: Colors.white24, fontSize: 12)),
              ],
            ))
          : RefreshIndicator(
              onRefresh: _load,
              color: accent,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final u = _users[i];
                  return Material(
                    color        : surface,
                    borderRadius : BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) =>
                            ChatScreen(me: widget.me, other: u)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(children: [
                          CircleAvatar(
                            radius         : 24,
                            backgroundColor: accent.withOpacity(0.15),
                            child: Text(u.username[0].toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                color     : accent,
                                fontWeight: FontWeight.w700,
                                fontSize  : 18)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.username,
                                style: GoogleFonts.inter(
                                  color     : Colors.white,
                                  fontSize  : 15,
                                  fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Row(children: [
                                Container(
                                  width : 7, height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2ECC71),
                                    shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                                Text('Tap to chat',
                                  style: GoogleFonts.inter(
                                    color  : Colors.white38,
                                    fontSize: 11)),
                              ]),
                            ],
                          )),
                          const Icon(Icons.chevron_right,
                              color: Colors.white24),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}