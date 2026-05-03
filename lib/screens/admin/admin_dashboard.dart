// lib/screens/admin/admin_dashboard.dart
import '../../services/email_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service.dart';
import '../../services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {

  late TabController _tab;

  static const bg      = Color(0xFF0A0E21);
  static const surface = Color(0xFF1A1F38);
  static const accent  = Color(0xFF4F8EF7);
  static const danger  = Color(0xFFFF5C5C);
  static const warn    = Color(0xFFFFB547);
  static const safe    = Color(0xFF2ECC71);
  static const purple  = Color(0xFF9B59B6);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
      _tab.addListener(() async {
    if (_tab.index == 3) {
      // Admin opened Alerts tab — mark all as notified
      final flags = await Supabase.instance.client
          .from('flags')
          .select('id')
          .eq('notified', false)
          .gte('warning_count', 4);
      for (final f in (flags as List)) {
        await SupabaseService.markNotified(f['id'] ?? '');
      }
    }
  });
}

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Color _riskColor(int count, double score) {
    if (count >= 5 || score >= 0.85) return danger;
    if (count >= 3 || score >= 0.70) return warn;
    return safe;
  }

  String _riskLabel(int count, double score) {
    if (count >= 5 || score >= 0.85) return 'HIGH';
    if (count >= 3 || score >= 0.70) return 'MEDIUM';
    return 'LOW';
  }

  // ── Send mail via url_launcher ─────────────────────────────────
Future<void> _sendMail(String email, String username,
    String flagId) async {

  // Show loading snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2)),
        const SizedBox(width: 12),
        Text('Sending email to $username...'),
      ]),
      backgroundColor: surface,
      duration: const Duration(seconds: 15),
    ),
  );

  // Send via SMTP
  final success = await EmailService.sendWarningEmail(
    toEmail: email,
    toName : username,
  );

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  if (success) {
    await SupabaseService.markMailSent(flagId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Email sent to $username ✅'),
        ]),
        backgroundColor: safe,
        duration: const Duration(seconds: 3),
      ));
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.error_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Failed to send email'),
        ]),
        backgroundColor: danger,
        duration: const Duration(seconds: 3),
      ));
    }
  }
}
  // ── Block user confirmation ────────────────────────────────────
  Future<void> _confirmBlock(String userId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Block $username?',
          style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'This will prevent $username from logging in. '
          'You can unblock them later.',
          style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: danger, elevation: 0),
            child: Text('Block',
                style: GoogleFonts.inter(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.blockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$username has been blocked'),
          backgroundColor: danger,
        ));
      }
    }
  }

  // ── Unblock user ───────────────────────────────────────────────
  Future<void> _confirmUnblock(String userId, String username) async {
    await SupabaseService.unblockUser(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$username has been unblocked'),
        backgroundColor: safe,
      ));
    }
  }
  // ── Alert action card ──────────────────────────────────────────
Widget _alertActionCard({
  required IconData    icon,
  required Color       color,
  required String      title,
  required String      message,
  required String      btnLabel,
  required VoidCallback onTap,
}) =>
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(title,
            style: GoogleFonts.inter(
              color: color, fontSize: 12,
              fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text(message,
          style: GoogleFonts.inter(
            color: Colors.white54, fontSize: 11, height: 1.4)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(icon, size: 14, color: color),
            label: Text(btnLabel,
              style: GoogleFonts.inter(
                color: color, fontSize: 12,
                fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );

// ── Email popup ────────────────────────────────────────────────
void _showEmailPopup(String userId, String username,
    String email, String flagId,
    List<Map<String, dynamic>> users) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.email_outlined, color: accent, size: 22),
        const SizedBox(width: 8),
        Text('Send Warning Email',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontWeight: FontWeight.w700,
            fontSize: 16)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$username has already received an AI surveillance '
            'warning but continued bullying.',
            style: GoogleFonts.inter(
                color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: accent.withOpacity(0.2), width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.alternate_email,
                  color: accent, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  email.isEmpty ? 'No email on file' : email,
                  style: GoogleFonts.inter(
                    color: accent, fontSize: 12)),
              ),
            ]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
            style: GoogleFonts.inter(color: Colors.white38))),
        ElevatedButton.icon(
          onPressed: email.isEmpty ? null : () {
            Navigator.pop(context);
            _sendMail(email, username, flagId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.send, size: 14,
              color: Colors.white),
          label: Text('Send Email',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

// ── Block popup ────────────────────────────────────────────────
void _showBlockPopup(String userId, String username) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.block_outlined, color: danger, size: 22),
        const SizedBox(width: 8),
        Text('Block User',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontWeight: FontWeight.w700,
            fontSize: 16)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$username has continued bullying even after receiving '
            'an email warning. Blocking will remove them from the '
            'platform and prevent login.',
            style: GoogleFonts.inter(
                color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: danger.withOpacity(0.2), width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: danger, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This will delete the user permanently.',
                  style: GoogleFonts.inter(
                    color: danger, fontSize: 11)),
              ),
            ]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
            style: GoogleFonts.inter(color: Colors.white38))),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await _deleteUser(userId, username);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: danger,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.delete_outline,
              size: 14, color: Colors.white),
          label: Text('Block & Delete',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
Future<void> _deleteUser(String userId, String username) async {
  try {
    // Get user email before deleting
    final userRow = await Supabase.instance.client
        .from('users')
        .select('email')
        .eq('id', userId)
        .single();
    final email = userRow['email'] ?? '';

    // Send block notification email
    if (email.isNotEmpty) {
      await EmailService.sendBlockEmail(
          toEmail: email, toName: username);
    }

    // Delete flags
    await Supabase.instance.client
        .from('flags')
        .delete()
        .eq('user_id', userId);

    // Delete messages
    await Supabase.instance.client
        .from('messages')
        .delete()
        .eq('sender_id', userId);

    // Delete user
    await Supabase.instance.client
        .from('users')
        .delete()
        .eq('id', userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$username blocked, deleted and notified via email'),
        backgroundColor: danger,
      ));
    }
  } catch (e) {
    print('❌ deleteUser error: $e');
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w700)),
            Text('AI-powered moderation',
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 11)),
          ],
        ),
        actions: [
          // Live dot + notification bell
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.notificationStream(),
            builder: (_, snap) {
              final count = snap.data?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white70),
                    onPressed: () => _tab.animateTo(3),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                            color: danger, shape: BoxShape.circle),
                        child: Center(
                          child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ]),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(children: [
              Container(width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: safe, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Live',
                style: GoogleFonts.inter(
                    color: safe, fontSize: 11,
                    fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 11),
          dividerColor: Colors.white10,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline, size: 18),
                text: 'Users'),
            Tab(icon: Icon(Icons.warning_amber_rounded, size: 18),
                text: 'Warnings'),
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18),
                text: 'Risk'),
            Tab(icon: Icon(Icons.notifications_outlined, size: 18),
                text: 'Alerts'),
          ],
        ),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.flagStream(),
        builder: (ctx, flagSnap) {
          final flags = flagSnap.data ?? [];

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: SupabaseService.getAllUsers(),
            builder: (ctx2, userSnap) {
              final users = userSnap.data ?? [];

              return TabBarView(
                controller: _tab,
                children: [
                  _tabUsers(users, flags),
                  _tabWarnings(flags),
                  _tabRiskChart(flags, users),
                  _tabAlerts(flags, users),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 1 — TOTAL USERS
  // ══════════════════════════════════════════════════════════════
  Widget _tabUsers(List<Map<String, dynamic>> users,
      List<Map<String, dynamic>> flags) {

    if (users.isEmpty) {
      return _empty('No users registered yet');
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Stats row
        Row(children: [
          _statChip('${users.length}', 'Total Users', accent),
          const SizedBox(width: 10),
          _statChip(
            '${users.where((u) => u['is_blocked'] == true).length}',
            'Blocked', danger),
          const SizedBox(width: 10),
          _statChip(
            '${users.where((u) => (u['warning_count'] ?? 0) > 0).length}',
            'Flagged', warn),
        ]),
        const SizedBox(height: 16),

        ...users.map((u) {
          final wCount = (u['warning_count'] ?? 0) as int;
          final blocked = u['is_blocked'] ?? false;
          final email   = u['email'] ?? '';
          final uId     = u['id'] ?? '';
          final uName   = u['username'] ?? 'Unknown';

          // Latest score for this user
          final userFlags = flags
              .where((f) => f['user_id'] == uId)
              .toList();
          final maxScore = userFlags.isEmpty ? 0.0
              : userFlags
                  .map((f) => (f['bully_score'] ?? 0.0) as double)
                  .reduce((a, b) => a > b ? a : b);

          final rColor = _riskColor(wCount, maxScore);

          return GestureDetector(
            onTap: () => _showUserDetail(u, userFlags),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: rColor.withOpacity(0.3), width: 1),
              ),
              child: Row(children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: rColor.withOpacity(0.12),
                  child: Text(uName[0].toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: rColor, fontSize: 16,
                      fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(uName,
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w600)),
                      if (blocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('BLOCKED',
                            style: GoogleFonts.inter(
                              color: danger, fontSize: 9,
                              fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(email,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _chip('$wCount warnings', rColor),
                      const SizedBox(width: 6),
                      if (maxScore > 0)
                        _chip(
                          '${(maxScore * 100).toStringAsFixed(0)}% max',
                          danger),
                    ]),
                  ],
                )),

                // Arrow
                const Icon(Icons.chevron_right,
                    color: Colors.white24),
              ]),
            ),
          );
        }),
      ],
    );
  }

  // ── User detail bottom sheet with Gemini analysis ─────────────
  void _showUserDetail(Map<String, dynamic> user,
      List<Map<String, dynamic>> userFlags) {
    showModalBottomSheet(
      context      : context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UserDetailSheet(
        user      : user,
        userFlags : userFlags,
        onBlock   : (uid, uname) => _confirmBlock(uid, uname),
        onUnblock : (uid, uname) => _confirmUnblock(uid, uname),
        onMail    : (email, uname, flagId) =>
            _sendMail(email, uname, flagId),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 2 — TOTAL WARNINGS (all flagged messages)
  // ══════════════════════════════════════════════════════════════
  Widget _tabWarnings(List<Map<String, dynamic>> flags) {
    if (flags.isEmpty) return _empty('No warnings yet — all clear!');

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(children: [
          _statChip('${flags.length}', 'Total Warnings', danger),
          const SizedBox(width: 10),
          _statChip(
            '${flags.map((f) => f['user_id']).toSet().length}',
            'Unique Users', warn),
          const SizedBox(width: 10),
          _statChip(
            flags.isEmpty ? '0%'
              : '${(flags.map((f) =>
                    (f['bully_score'] ?? 0.0) as double)
                  .reduce((a, b) => a + b) / flags.length * 100)
                  .toStringAsFixed(0)}%',
            'Avg Score', accent),
        ]),
        const SizedBox(height: 16),

        ...flags.map((f) => _warningCard(f)),
      ],
    );
  }

  Widget _warningCard(Map<String, dynamic> f) {
    final score   = (f['bully_score']   ?? 0.0) as double;
    final count   = (f['warning_count'] ?? 0)   as int;
    final uname   = f['username']        ?? 'Unknown';
    final text    = f['message_text']   ?? '';
    final sarcasm = f['sarcasm_type']   ?? 'None';
    final time    = f['created_at'] != null
        ? timeago.format(DateTime.parse(f['created_at']))
        : '';
    final rColor = _riskColor(count, score);
    final rLabel = _riskLabel(count, score);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: rColor.withOpacity(0.12),
              child: Text(uname[0].toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  color: rColor, fontSize: 13,
                  fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(uname,
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w600)),
                Text(time,
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 10)),
              ],
            )),
            _chip(rLabel, rColor),
          ]),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          Text('"$text"',
            style: GoogleFonts.inter(
              color: Colors.white70, fontSize: 12,
              fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _chip('${(score * 100).toStringAsFixed(0)}%', danger),
            if (sarcasm != 'None') _chip(sarcasm, warn),
            _chip('Warning #$count', rColor),
          ]),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 3 — RISK DISTRIBUTION BAR CHART
  // ══════════════════════════════════════════════════════════════
  Widget _tabRiskChart(List<Map<String, dynamic>> flags,
      List<Map<String, dynamic>> users) {

    // Group users by risk
    int high = 0, medium = 0, low = 0, clean = 0;

    for (final u in users) {
      final wCount = (u['warning_count'] ?? 0) as int;
      // Find max score for this user
      final userFlags = flags
          .where((f) => f['user_id'] == u['id'])
          .toList();
      final maxScore = userFlags.isEmpty ? 0.0
          : userFlags
              .map((f) => (f['bully_score'] ?? 0.0) as double)
              .reduce((a, b) => a > b ? a : b);

      final label = _riskLabel(wCount, maxScore);
      if (label == 'HIGH')        high++;
      else if (label == 'MEDIUM') medium++;
      else if (wCount > 0)        low++;
      else                        clean++;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // Summary chips
        Row(children: [
          _statChip('$high',   'High Risk',  danger),
          const SizedBox(width: 10),
          _statChip('$medium', 'Medium Risk', warn),
          const SizedBox(width: 10),
          _statChip('$low',    'Low Risk',   safe),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statChip('$clean',        'Clean',       accent),
          const SizedBox(width: 10),
          _statChip('${users.length}','Total Users', Colors.white54),
          const SizedBox(width: 10),
          _statChip('${flags.length}','Total Flags', purple),
        ]),
        const SizedBox(height: 28),

        // Bar chart
        Text('Risk Distribution',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),

        Container(
          height: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (([high, medium, low, clean].reduce(
                      (a, b) => a > b ? a : b)) + 2).toDouble(),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 11)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final labels = ['High', 'Medium', 'Low', 'Clean'];
                      final i = v.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          i < labels.length ? labels[i] : '',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 11)),
                      );
                    },
                  ),
                ),
                topTitles  : const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _bar(0, high.toDouble(),   danger),
                _bar(1, medium.toDouble(), warn),
                _bar(2, low.toDouble(),    safe),
                _bar(3, clean.toDouble(),  accent),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Score histogram
        Text('Bully Score Breakdown',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _scoreBands(flags),
      ]),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) =>
    BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY          : y,
          color        : color,
          width        : 36,
          borderRadius : BorderRadius.circular(6),
        ),
      ],
    );

  Widget _scoreBands(List<Map<String, dynamic>> flags) {
    final bands = {
      '0–50%' : flags.where((f) =>
          (f['bully_score'] ?? 0.0) < 0.5).length,
      '50–70%': flags.where((f) {
          final s = (f['bully_score'] ?? 0.0) as double;
          return s >= 0.5 && s < 0.7;
        }).length,
      '70–85%': flags.where((f) {
          final s = (f['bully_score'] ?? 0.0) as double;
          return s >= 0.7 && s < 0.85;
        }).length,
      '85%+'  : flags.where((f) =>
          (f['bully_score'] ?? 0.0) >= 0.85).length,
    };
    final colors = [safe, warn, danger, const Color(0xFF8B0000)];
    int i = 0;

    return Column(
      children: bands.entries.map((e) {
        final total  = flags.isEmpty ? 1 : flags.length;
        final pct    = e.value / total;
        final color  = colors[i++ % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key,
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 12)),
                  Text('${e.value} messages',
                    style: GoogleFonts.inter(
                        color: color, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value           : pct,
                  backgroundColor : Colors.white10,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight       : 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 4 — ALERTS & NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════
Widget _tabAlerts(List<Map<String, dynamic>> flags,
    List<Map<String, dynamic>> users) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
    final unread = flags
        .where((f) =>
            (f['warning_count'] ?? 0) >= 4 &&
            (f['notified'] ?? false) == false)
        .toList();
    for (final f in unread) {
      await SupabaseService.markNotified(f['id'] ?? '');
    }
  });

  // Get latest flag per user (highest warning count)
  final Map<String, Map<String, dynamic>> latestPerUser = {};
  for (final f in flags) {
    final uid   = f['user_id'] ?? '';
    final count = (f['warning_count'] ?? 0) as int;
    if (!latestPerUser.containsKey(uid) ||
        count > (latestPerUser[uid]!['warning_count'] ?? 0)) {
      latestPerUser[uid] = f;
    }
  }

  // Only show users with 4+ warnings
  final alerts = latestPerUser.values
      .where((f) => (f['warning_count'] ?? 0) >= 4)
      .toList()
    ..sort((a, b) => (b['warning_count'] ?? 0)
        .compareTo(a['warning_count'] ?? 0));

  if (alerts.isEmpty) {
    return _empty('No critical alerts yet');
  }

  return ListView(
    padding: const EdgeInsets.all(14),
    children: alerts.map((f) {
      final uId    = f['user_id']      ?? '';
      final uName  = f['username']     ?? 'Unknown';
      final count  = (f['warning_count'] ?? 0) as int;
      final fId    = f['id']           ?? '';

      // Get user info
      final userRow = users.firstWhere(
        (u) => u['id'] == uId, orElse: () => {});
      final email   = userRow['email']      ?? '';
      final blocked = userRow['is_blocked'] ?? false;
      final mailSent = f['mail_sent']       ?? false;

      // Determine what action to show
      // 4-5 warnings → show email popup option
      // 6+ warnings  → show block popup option
      final showEmail = count >= 4 && count < 6 && !mailSent;
      final showBlock = count >= 6 && !blocked;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: danger.withOpacity(0.4), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: danger.withOpacity(0.12),
                child: Text(uName[0].toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: danger, fontSize: 14,
                    fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(uName,
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w600)),
                  Text('$count warnings total',
                    style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 11)),
                ],
              )),
              _chip('$count ⚠️', danger),
            ]),

            const SizedBox(height: 12),

            // Show email action (4-5 warnings)
            if (showEmail)
              _alertActionCard(
                icon   : Icons.email_outlined,
                color  : accent,
                title  : 'User already warned by AI',
                message: '$uName has been warned by AI surveillance '
                         'but continues to bully. Send them an email warning.',
                btnLabel: 'Send Email Warning',
                onTap  : () => _showEmailPopup(
                    uId, uName, email, fId, users),
              ),

            // Show block action (6+ warnings)
            if (showBlock)
              _alertActionCard(
                icon   : Icons.block_outlined,
                color  : danger,
                title  : 'Repeated violations after email warning',
                message: '$uName continued bullying after receiving '
                         'an email warning. Consider blocking this user.',
                btnLabel: 'Block User',
                onTap  : () => _showBlockPopup(uId, uName),
              ),

            // Already handled
            if (!showEmail && !showBlock)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(
                    blocked
                        ? Icons.block_outlined
                        : Icons.mark_email_read_outlined,
                    color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    blocked
                        ? 'User is blocked'
                        : 'Email already sent',
                    style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 12)),
                ]),
              ),
          ],
        ),
      );
    }).toList(),
  );
}

  // ── Shared widgets ─────────────────────────────────────────────
  Widget _empty(String msg) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.verified_user_outlined,
          color: safe, size: 52),
      const SizedBox(height: 14),
      Text(msg,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
            color: Colors.white38, fontSize: 14)),
    ]),
  );

  Widget _statChip(String value, String label, Color color) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
              style: GoogleFonts.spaceGrotesk(
                color: color, fontSize: 20,
                fontWeight: FontWeight.w700)),
            Text(label,
              style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: color.withOpacity(0.3), width: 1),
    ),
    child: Text(label,
      style: GoogleFonts.inter(
        color: color, fontSize: 10,
        fontWeight: FontWeight.w600)),
  );
}


// ══════════════════════════════════════════════════════════════════
// USER DETAIL BOTTOM SHEET — with Gemini AI reasoning
// ══════════════════════════════════════════════════════════════════
class _UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic>         user;
  final List<Map<String, dynamic>>   userFlags;
  final Function(String, String)     onBlock;
  final Function(String, String)     onUnblock;
  final Function(String, String, String) onMail;

  const _UserDetailSheet({
    required this.user,
    required this.userFlags,
    required this.onBlock,
    required this.onUnblock,
    required this.onMail,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  static const surface = Color(0xFF1A1F38);
  static const bg      = Color(0xFF0A0E21);
  static const accent  = Color(0xFF4F8EF7);
  static const danger  = Color(0xFFFF5C5C);
  static const warn    = Color(0xFFFFB547);
  static const safe    = Color(0xFF2ECC71);

  String? _geminiAnalysis;
  bool    _loadingGemini = false;

  String get _userId   => widget.user['id']       ?? '';
  String get _username => widget.user['username']  ?? 'Unknown';
  String get _email    => widget.user['email']     ?? '';
  bool   get _blocked  => widget.user['is_blocked'] ?? false;
  int    get _warnings => widget.user['warning_count'] ?? 0;

  @override
  void initState() {
    super.initState();
    _loadGeminiAnalysis();
  }

  Future<void> _loadGeminiAnalysis() async {
    if (widget.userFlags.isEmpty) return;
    setState(() => _loadingGemini = true);

    final analysis = await AiService.analyseUserWithGemini(
      username: _username,
      flags   : widget.userFlags,
    );

    setState(() {
      _geminiAnalysis = analysis;
      _loadingGemini  = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand         : false,
      initialChildSize: 0.85,
      maxChildSize   : 0.95,
      minChildSize   : 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [

            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User header
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: accent.withOpacity(0.15),
                child: Text(_username[0].toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: accent, fontSize: 22,
                    fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_username,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w700)),
                  Text(_email,
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _chip('$_warnings warnings', warn),
                    const SizedBox(width: 6),
                    if (_blocked)
                      _chip('BLOCKED', danger)
                    else
                      _chip('ACTIVE', safe),
                  ]),
                ],
              )),
            ]),

            const SizedBox(height: 20),


            // Gemini AI analysis
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: accent.withOpacity(0.2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome,
                        color: accent, size: 16),
                    const SizedBox(width: 6),
                    Text('Gemini AI Analysis',
                      style: GoogleFonts.inter(
                        color: accent, fontSize: 12,
                        fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 10),
                  if (_loadingGemini)
                    Row(children: [
                      const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: accent, strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text('Analysing behaviour pattern...',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 12)),
                    ])
                  else if (_geminiAnalysis != null)
                    Text(_geminiAnalysis!,
                      style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 13,
                        height: 1.5))
                  else
                    Text('No flags to analyse',
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Flagged messages history
            Text('FLAGGED MESSAGES HISTORY',
              style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
            const SizedBox(height: 10),

            if (widget.userFlags.isEmpty)
              Text('No flags for this user',
                style: GoogleFonts.inter(
                    color: Colors.white24, fontSize: 12))
            else
              ...widget.userFlags.map((f) {
                final score = (f['bully_score'] ?? 0.0) as double;
                final text  = f['message_text'] ?? '';
                final count = (f['warning_count'] ?? 0) as int;
                final time  = f['created_at'] != null
                    ? timeago.format(DateTime.parse(f['created_at']))
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: danger.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: danger.withOpacity(0.15), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('"$text"',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Text(time,
                            style: GoogleFonts.inter(
                                color: Colors.white24,
                                fontSize: 10)),
                        ],
                      )),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _chip(
                            '${(score * 100).toStringAsFixed(0)}%',
                            danger),
                          const SizedBox(height: 4),
                          Text('#$count',
                            style: GoogleFonts.inter(
                              color: warn, fontSize: 10,
                              fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
    ),
    child: Text(label,
      style: GoogleFonts.inter(
        color: color, fontSize: 10,
        fontWeight: FontWeight.w600)),
  );
}