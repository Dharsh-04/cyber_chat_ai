// lib/models/message_model.dart

class MessageModel {
  final String   id;
  final String   senderId;
  final String   receiverId;
  final String   text;
  final String?  imageUrl;
  final bool     flagged;
  final double   bullyScore;
  final String   sarcasmType;
  final String   prediction;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.imageUrl,
    this.flagged     = false,
    this.bullyScore  = 0.0,
    this.sarcasmType = 'None',
    this.prediction  = 'Not Cyberbullying',
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> m) => MessageModel(
    id          : m['id']           ?? '',
    senderId    : m['sender_id']    ?? '',
    receiverId  : m['receiver_id']  ?? '',
    text        : m['text']         ?? '',
    imageUrl    : m['image_url'],
    flagged     : m['flagged']      ?? false,
    bullyScore  : (m['bully_score'] ?? 0.0).toDouble(),
    sarcasmType : m['sarcasm_type'] ?? 'None',
    prediction  : m['prediction']   ?? 'Not Cyberbullying',
    createdAt   : DateTime.parse(
        (m['created_at'] as String).contains('Z')
            ? m['created_at']
            : '${m['created_at']}Z'),
  );
}