// lib/screens/chat/chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/ai_service.dart';
import '../../services/supabase_service.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final UserModel me;
  final UserModel other;
  const ChatScreen({super.key, required this.me, required this.other});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const bg      = Color(0xFF0A0E21);
  static const surface = Color(0xFF1A1F38);
  static const accent  = Color(0xFF4F8EF7);

  final _scroll = ScrollController();
  final _uuid   = const Uuid();
  bool  _sending = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkSurveillanceAlert();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ── Scroll to bottom ──────────────────────────────────────────
  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve   : Curves.easeOut,
        );
      }
    });
  }

  // ── Check surveillance alert (permanent — from Supabase) ──────
  Future<void> _checkSurveillanceAlert() async {
    try {
      final alreadyShown = await SupabaseService.wasAlertShown(
          widget.me.id);
      if (alreadyShown) return;

      final count = await SupabaseService.getUserWarningCount(
          widget.me.id);
      if (count >= 3 && mounted) {
        await SupabaseService.markAlertShown(widget.me.id);
        _showSurveillanceAlert();
      }
    } catch (e) {
      print('❌ Alert check error: $e');
    }
  }

  // ── Surveillance alert dialog ─────────────────────────────────
  void _showSurveillanceAlert() {
    showDialog(
      context          : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.shield_rounded,
              color: Color(0xFFFFB547), size: 28),
          const SizedBox(width: 10),
          Text('AI Surveillance',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize     : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are under AI surveillance.',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFB547), fontSize: 14,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              'Our AI has detected multiple harmful messages from '
              'your account. Please be respectful. Continued '
              'violations may result in further action.',
              style: GoogleFonts.inter(
                color: Colors.white70, fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB547).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFB547).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFFFB547), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All your messages are monitored by our admin team.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFB547), fontSize: 11)),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB547),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('I Understand',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Send message pipeline ─────────────────────────────────────
Future<void> _send(String text, {File? image}) async {
  if (text.trim().isEmpty && image == null) return;
  if (_sending) return;
  setState(() => _sending = true);

  try {
    final msgId = _uuid.v4();
    String? imageUrl;

    // ── Step 1: Upload image if any ───────────────────────────
    if (image != null) {
      imageUrl = await SupabaseService.uploadImage(
          image, widget.me.id);
    }

    // ── Step 2: Save message IMMEDIATELY (no AI wait) ─────────
    // Send with flagged=false first so message appears instantly
    await SupabaseService.sendMessage(
      senderId   : widget.me.id,
      receiverId : widget.other.id,
      text       : text.trim(),
      flagged    : false,        // ← send immediately as safe
      bullyScore : 0.0,
      sarcasmType: 'None',
      prediction : 'Pending',
      imageUrl   : imageUrl,
    );

    setState(() => _sending = false);  // ← unblock UI immediately
    _scrollDown();

    // ── Step 3: AI check runs in BACKGROUND ───────────────────
    // User sees message instantly, AI checks silently
    _checkInBackground(
      text   : text.trim(),
      msgId  : msgId,
      image  : image,
      imageUrl: imageUrl,
    );

  } catch (e) {
    print('❌ _send error: $e');
    setState(() => _sending = false);
  }
}

// ── Background AI check — doesn't block UI ──────────────────────
Future<void> _checkInBackground({
  required String  text,
  required String  msgId,
  File?            image,
  String?          imageUrl,
}) async {
  try {
    AiResult ai;

    if (image != null) {
      ai = await AiService.analyseWithImage(
        imageFile : image,
        caption   : text,
        senderId  : widget.me.id,
        messageId : msgId,
      );
    } else {
      ai = await AiService.analyse(
        text     : text,
        senderId : widget.me.id,
        messageId: msgId,
      );
    }

    print('🤖 BG check: flagged=${ai.flagged} score=${ai.bullyScore}');

    // If flagged → save to flags table
    if (ai.flagged) {
      await SupabaseService.saveFlag(
        userId     : widget.me.id,
        username   : widget.me.username,
        messageId  : msgId,
        messageText: text.isEmpty ? '[Image]' : text,
        bullyScore : ai.bullyScore,
        sarcasmType: ai.sarcasmType,
        prediction : ai.prediction,
      );

      // Show surveillance alert if needed
      final alreadyShown = await SupabaseService.wasAlertShown(
          widget.me.id);
      if (!alreadyShown) {
        final count = await SupabaseService.getUserWarningCount(
            widget.me.id);
        if (count >= 3 && mounted) {
          await SupabaseService.markAlertShown(widget.me.id);
          _showSurveillanceAlert();
        }
      }
    }
  } catch (e) {
    print('❌ Background AI check error: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          CircleAvatar(
            radius         : 18,
            backgroundColor: accent.withOpacity(0.15),
            child: Text(widget.other.username[0].toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                color: accent, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.other.username,
                style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w600)),
              Row(children: [
                Container(width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Online',
                  style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 11)),
              ]),
            ]),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color        : accent.withOpacity(0.12),
                borderRadius : BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.shield_rounded,
                    color: accent, size: 14),
                const SizedBox(width: 4),
                Text('AI Active',
                  style: GoogleFonts.inter(
                    color: accent, fontSize: 11,
                    fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),

      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: SupabaseService.messageStream(
                widget.me.id, widget.other.id),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: accent));
              }
              final msgs = snap.data ?? [];
              if (msgs.isEmpty) {
                return Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: Colors.white12, size: 48),
                    const SizedBox(height: 12),
                    Text('Say hi to ${widget.other.username}!',
                      style: GoogleFonts.inter(
                        color: Colors.white24, fontSize: 14)),
                  ],
                ));
              }
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollDown());
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 16),
                itemCount: msgs.length,
                itemBuilder: (_, i) => MessageBubble(
                  msg : msgs[i],
                  isMe: msgs[i].senderId == widget.me.id,
                ),
              );
            },
          ),
        ),
        MessageInput(onSend: _send, sending: _sending),
      ]),
    );
  }
}