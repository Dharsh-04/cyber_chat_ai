// lib/screens/chat/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool         isMe;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
  });

  static const accent  = Color(0xFF4F8EF7);
  static const surface = Color(0xFF1A1F38);

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? accent.withOpacity(0.85)
        : surface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft    : const Radius.circular(18),
                  topRight   : const Radius.circular(18),
                  bottomLeft : Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4  : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image if present
                  if (msg.imageUrl != null &&
                      msg.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft    : const Radius.circular(18),
                        topRight   : const Radius.circular(18),
                        bottomLeft : Radius.circular(
                            msg.text.isEmpty
                                ? (isMe ? 18 : 4) : 0),
                        bottomRight: Radius.circular(
                            msg.text.isEmpty
                                ? (isMe ? 4 : 18) : 0),
                      ),
                      child: Image.network(
                        msg.imageUrl!,
                        fit  : BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    height: 150,
                                    color: Colors.white10,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: accent, strokeWidth: 2),
                                    )),
                      ),
                    ),

                  // Text
                  if (msg.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Text(msg.text,
                        style: GoogleFonts.inter(
                          color  : Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          height : 1.4)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Timestamp only — no flag shown to user
            Text(
              timeago.format(msg.createdAt.toLocal(),
                  allowFromNow: true),
              style: GoogleFonts.inter(
                  color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}