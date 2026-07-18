import 'package:digiQ/core/api/chat_api.dart';
import 'package:digiQ/core/services/chat_service.dart';
import 'package:digiQ/models/chat_message_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String otherPersonName;

  const ChatScreen({
    super.key,
    required this.bookingId,
    this.otherPersonName = 'Chat',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatService _chat = ChatService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _loading = true;
  String? _currentUserId;

  static const _baseUrl = 'https://api.digiqueue.co.za';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUserId = ref.read(authProvider).user?.id;

    await _chat.connect(_baseUrl);
    _chat.joinChat(widget.bookingId);

    // Real-time messages arrive via socket — the server echoes back to sender too
    _chat.onMessage((data) {
      final msg = ChatMessage.fromJson(data);
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });

    // Load history from REST
    try {
      final history = await ref.read(chatApiProvider).getHistory(widget.bookingId);
      if (mounted) {
        setState(() {
          _messages.addAll(history);
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    _chat.sendMessage(widget.bookingId, text);
    // Message will appear via the socket echo — no local optimistic insert needed
  }

  @override
  void dispose() {
    _chat.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherPersonName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Booking chat',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── MESSAGE LIST ──────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 52, color: cs.onSurface.withValues(alpha: 0.25)),
                            const SizedBox(height: 12),
                            Text('No messages yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.4))),
                            const SizedBox(height: 4),
                            Text('Send the first message below',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.3))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMine = msg.senderId == _currentUserId;
                          final showTimestamp = i == 0 ||
                              msg.createdAt
                                      .difference(_messages[i - 1].createdAt)
                                      .inMinutes
                                      .abs() >
                                  5;
                          return _MessageBubble(
                            message: msg,
                            isMine: isMine,
                            showTimestamp: showTimestamp,
                          );
                        },
                      ),
          ),

          // ── INPUT BAR ─────────────────────────────────────────────────────
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(onTap: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Message bubble
 * -------------------------------------------------------------------------- */

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showTimestamp;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myBg = cs.primary;
    final theirBg = isDark ? cs.surfaceContainerHigh : const Color(0xFFEEEEEE);
    final myText = cs.onPrimary;
    final theirText = cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  _formatTimestamp(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Text(
                    message.senderRole == 'driver' ? 'D' : 'P',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.primary),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  margin: isMine
                      ? const EdgeInsets.only(left: 48)
                      : const EdgeInsets.only(right: 48),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? myBg : theirBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMine ? myText : theirText,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (now.difference(local).inDays < 1 &&
        now.day == local.day) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('d MMM, HH:mm').format(local);
  }
}

/* --------------------------------------------------------------------------
 * Send button
 * -------------------------------------------------------------------------- */

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.send_rounded, color: cs.onPrimary, size: 20),
      ),
    );
  }
}
