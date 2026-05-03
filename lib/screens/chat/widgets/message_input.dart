// lib/screens/chat/widgets/message_input.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class MessageInput extends StatefulWidget {
  final Future<void> Function(String text, {File? image}) onSend;
  final bool sending;
  const MessageInput({
    super.key,
    required this.onSend,
    required this.sending,
  });
  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  final _picker = ImagePicker();
  bool  _hasText    = false;
  File? _pickedImage;

  static const surface = Color(0xFF1A1F38);
  static const accent  = Color(0xFF4F8EF7);
  static const danger  = Color(0xFFFF5C5C);

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Gallery with permission ────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gallery permission denied'),
          backgroundColor: danger,
        ));
        if (status.isPermanentlyDenied) openAppSettings();
      }
      return;
    }
    final img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _pickedImage = File(img.path));
  }

  // ── Camera with permission ─────────────────────────────────────
  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Camera permission denied'),
          backgroundColor: danger,
        ));
        if (status.isPermanentlyDenied) openAppSettings();
      }
      return;
    }
    final img = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 70);
    if (img != null) setState(() => _pickedImage = File(img.path));
  }

  // ── Image picker bottom sheet ──────────────────────────────────
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context        : context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Send Image',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _sourceBtn(
              icon : Icons.photo_library_rounded,
              label: 'Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _sourceBtn(
              icon : Icons.camera_alt_rounded,
              label: 'Camera',
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            )),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _send() async {
    final text  = _ctrl.text.trim();
    final image = _pickedImage;
    if (text.isEmpty && image == null) return;
    if (widget.sending) return;

    _ctrl.clear();
    setState(() { _hasText = false; _pickedImage = null; });
    await widget.onSend(text, image: image);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image preview
        if (_pickedImage != null)
          Container(
            color  : surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child  : Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_pickedImage!,
                    height: 120, width: 120, fit: BoxFit.cover),
              ),
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _pickedImage = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: danger, shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ]),
          ),

        // Input row
        Container(
          padding: EdgeInsets.only(
            left  : 12, right : 12, top: 10,
            bottom: MediaQuery.of(context).padding.bottom +
                    MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: surface,
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12)],
          ),
          child: Row(children: [
            // Image button
            GestureDetector(
              onTap: widget.sending ? null : _pickImage,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.image_rounded,
                  color: _pickedImage != null
                      ? accent : Colors.white38,
                  size: 20),
              ),
            ),
            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color       : const Color(0xFF0A0E21),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller     : _ctrl,
                  focusNode      : _focus,
                  enabled        : !widget.sending,
                  minLines       : 1,
                  maxLines       : 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted    : (_) => _send(),
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: widget.sending
                        ? 'AI checking...'
                        : _pickedImage != null
                            ? 'Add a caption...'
                            : 'Type a message...',
                    hintStyle: GoogleFonts.inter(
                        color: Colors.white30, fontSize: 14),
                    border        : InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: (_hasText || _pickedImage != null) &&
                        !widget.sending
                    ? accent
                    : accent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: widget.sending
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    onPressed:
                        (_hasText || _pickedImage != null)
                            ? _send : null,
                  ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _sourceBtn({
    required IconData    icon,
    required String      label,
    required VoidCallback onTap,
  }) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color       : const Color(0xFF0A0E21),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(height: 8),
          Text(label,
            style: GoogleFonts.inter(
                color: Colors.white70, fontSize: 13)),
        ]),
      ),
    );
}