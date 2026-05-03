// lib/models/user_model.dart

class UserModel {
  final String id;
  final String username;
  final String email;
  final bool   alertShown;
  final bool   isBlocked;
  final int    warningCount;

  const UserModel({
    required this.id,
    required this.username,
    this.email        = '',
    this.alertShown   = false,
    this.isBlocked    = false,
    this.warningCount = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id           : m['id']            ?? '',
    username     : m['username']      ?? '',
    email        : m['email']         ?? '',
    alertShown   : m['alert_shown']   ?? false,
    isBlocked    : m['is_blocked']    ?? false,
    warningCount : m['warning_count'] ?? 0,
  );
}