// lib/services/supabase_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final _db = Supabase.instance.client;

  // ── AUTH ───────────────────────────────────────────────────────────────────

  static Future<UserModel?> register(
      String username, String password, String email) async {
    try {
      final exists = await _db
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (exists != null) return null;

      final row = await _db.from('users').insert({
        'username'     : username,
        'password'     : password,
        'email'        : email,
        'alert_shown'  : false,
        'is_blocked'   : false,
        'warning_count': 0,
      }).select().single();
      return UserModel.fromMap(row);
    } catch (e) {
      print('❌ register error: $e');
      return null;
    }
  }

static Future<UserModel?> login(
    String username, String password) async {
  try {
    // Admin must never be treated as regular user
    if (username == 'admin') return null;  // ← ADD THIS

    final row = await _db
        .from('users')
        .select()
        .eq('username', username)
        .eq('password', password)
        .eq('is_blocked', false)
        .maybeSingle();
    return row != null ? UserModel.fromMap(row) : null;
  } catch (e) {
    print('❌ login error: $e');
    return null;
  }
}
  // ── USERS ──────────────────────────────────────────────────────────────────

  static Future<List<UserModel>> getOtherUsers(String currentId) async {
    try {
      final rows = await _db
          .from('users')
          .select('id, username, email, alert_shown, is_blocked, warning_count')
          .neq('id', currentId)
          .order('username');
      return (rows as List).map((r) => UserModel.fromMap(r)).toList();
    } catch (e) {
      print('❌ getOtherUsers error: $e');
      return [];
    }
  }

  // Get ALL users (for admin)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final rows = await _db
          .from('users')
          .select('id, username, email, alert_shown, is_blocked, warning_count, created_at')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('❌ getAllUsers error: $e');
      return [];
    }
  }

  // ── ALERT TRACKING ─────────────────────────────────────────────────────────

  static Future<bool> wasAlertShown(String userId) async {
    try {
      final row = await _db
          .from('users')
          .select('alert_shown')
          .eq('id', userId)
          .single();
      return row['alert_shown'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> markAlertShown(String userId) async {
    try {
      await _db
          .from('users')
          .update({'alert_shown': true})
          .eq('id', userId);
      print('✅ Alert marked shown for: $userId');
    } catch (e) {
      print('❌ markAlertShown error: $e');
    }
  }

  // ── BLOCK / UNBLOCK USER ───────────────────────────────────────────────────

  static Future<void> blockUser(String userId) async {
    try {
      await _db
          .from('users')
          .update({'is_blocked': true})
          .eq('id', userId);
      print('🚫 User blocked: $userId');
    } catch (e) {
      print('❌ blockUser error: $e');
    }
  }

  static Future<void> unblockUser(String userId) async {
    try {
      await _db
          .from('users')
          .update({'is_blocked': false})
          .eq('id', userId);
      print('✅ User unblocked: $userId');
    } catch (e) {
      print('❌ unblockUser error: $e');
    }
  }

  // ── IMAGE UPLOAD ───────────────────────────────────────────────────────────

  static Future<String?> uploadImage(
      File imageFile, String userId) async {
    try {
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _db.storage.from('chat-images').upload(fileName, imageFile);
      return _db.storage.from('chat-images').getPublicUrl(fileName);
    } catch (e) {
      print('❌ Image upload error: $e');
      return null;
    }
  }

  // ── MESSAGES ───────────────────────────────────────────────────────────────

  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    required bool   flagged,
    required double bullyScore,
    required String sarcasmType,
    required String prediction,
    String?         imageUrl,
  }) async {
    try {
      await _db.from('messages').insert({
        'sender_id'   : senderId,
        'receiver_id' : receiverId,
        'text'        : text,
        'flagged'     : flagged,
        'bully_score' : bullyScore,
        'sarcasm_type': sarcasmType,
        'prediction'  : prediction,
        'image_url'   : imageUrl,
      });
    } catch (e) {
      print('❌ sendMessage error: $e');
      rethrow;
    }
  }

  static Stream<List<MessageModel>> messageStream(
      String myId, String otherId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((rows) => rows
            .where((r) =>
                (r['sender_id'] == myId   && r['receiver_id'] == otherId) ||
                (r['sender_id'] == otherId && r['receiver_id'] == myId))
            .map(MessageModel.fromMap)
            .toList());
  }

  // ── FLAGS ──────────────────────────────────────────────────────────────────

  static Future<int> getUserWarningCount(String userId) async {
    try {
      final result = await _db
          .from('flags')
          .select('id')
          .eq('user_id', userId);
      return (result as List).length;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> saveFlag({
  required String userId,
  required String username,
  required String messageId,
  required String messageText,
  required double bullyScore,
  required String sarcasmType,
  required String prediction,
  // ── Optional agentic fields ────────────────────────────────────
  String  severity        = 'medium',
  String  action          = 'warn',
  String  adminReport     = '',
  String? patternAnalysis,
}) async {
  try {
    print('📝 saveFlag — user: $username  score: $bullyScore');

    final prev = await _db
        .from('flags')
        .select('id')
        .eq('user_id', userId);
    final warningCount = (prev as List).length + 1;

    await _db.from('flags').insert({
      'user_id'        : userId,
      'username'       : username,
      'message_id'     : messageId,
      'message_text'   : messageText,
      'bully_score'    : bullyScore,
      'sarcasm_type'   : sarcasmType,
      'prediction'     : prediction,
      'warning_count'  : warningCount,
      'severity'       : severity,
      'action'         : action,
      'admin_report'   : adminReport,
      'mail_sent'      : false,
      'notified'       : false,
    });

    // Update warning_count in users table
    await _db
        .from('users')
        .update({'warning_count': warningCount})
        .eq('id', userId);

    print('✅ Flag saved — warning #$warningCount');
  } catch (e, s) {
    print('❌ saveFlag FAILED: $e\n$s');
  }
}

  // Mark mail sent for a flag
  static Future<void> markMailSent(String flagId) async {
    try {
      await _db
          .from('flags')
          .update({'mail_sent': true})
          .eq('id', flagId);
    } catch (e) {
      print('❌ markMailSent error: $e');
    }
  }

  // Admin acknowledges notification
  static Future<void> markNotified(String flagId) async {
    try {
      await _db
          .from('flags')
          .update({'notified': true})
          .eq('id', flagId);
    } catch (e) {
      print('❌ markNotified error: $e');
    }
  }

  // Get flags for a specific user
  static Future<List<Map<String, dynamic>>> getUserFlags(
      String userId) async {
    try {
      final rows = await _db
          .from('flags')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      return [];
    }
  }

  // Live flag stream for admin
  static Stream<List<Map<String, dynamic>>> flagStream() {
    return _db
        .from('flags')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Unread notifications stream (warning_count >= 4 and not notified)
  static Stream<List<Map<String, dynamic>>> notificationStream() {
    return _db
        .from('flags')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) =>
                (r['warning_count'] ?? 0) >= 4 &&
                (r['notified'] ?? false) == false)
            .toList());
  }
}