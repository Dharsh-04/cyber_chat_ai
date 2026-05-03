// lib/models/flag_model.dart

class FlagModel {
  final String id;
  final String userId;
  final String username;
  final String messageId;
  final String messageText;
  final double bullyScore;
  final String sarcasmType;
  final String prediction;
  final int    warningCount;
  final DateTime createdAt;

  // ── Agentic fields (new) ───────────────────────────────────────
  final String severity;       // low / medium / high / critical
  final String pattern;        // isolated / repeated / escalating
  final String action;         // warn / alert / escalate
  final String actionReason;   // why agent took this action
  final String agentReasoning; // Gemini's analysis
  final String adminReport;    // human-readable report for admin

  FlagModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.messageId,
    required this.messageText,
    required this.bullyScore,
    required this.sarcasmType,
    required this.prediction,
    required this.warningCount,
    required this.createdAt,
    this.severity       = 'medium',
    this.pattern        = 'isolated',
    this.action         = 'warn',
    this.actionReason   = '',
    this.agentReasoning = '',
    this.adminReport    = '',
  });

  factory FlagModel.fromMap(Map<String, dynamic> m) => FlagModel(
    id             : m['id']            ?? '',
    userId         : m['user_id']       ?? '',
    username       : m['username']      ?? 'Unknown',
    messageId      : m['message_id']    ?? '',
    messageText    : m['message_text']  ?? '',
    bullyScore     : (m['bully_score']  ?? 0.0).toDouble(),
    sarcasmType    : m['sarcasm_type']  ?? 'None',
    prediction     : m['prediction']    ?? '',
    warningCount   : m['warning_count'] ?? 0,
    createdAt      : DateTime.parse(m['created_at']),
    severity       : m['severity']        ?? 'medium',
    pattern        : m['pattern']         ?? 'isolated',
    action         : m['action']          ?? 'warn',
    actionReason   : m['action_reason']   ?? '',
    agentReasoning : m['agent_reasoning'] ?? '',
    adminReport    : m['admin_report']    ?? '',
  );

  // Risk color based on severity
  String get riskLevel {
    switch (severity) {
      case 'critical': return 'CRITICAL';
      case 'high'    : return 'HIGH';
      case 'medium'  : return 'MEDIUM';
      default        : return 'LOW';
    }
  }
}