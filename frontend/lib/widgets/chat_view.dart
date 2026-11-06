import 'package:flutter/material.dart';

import '../models/chat_message.dart';

String formatTime(DateTime t) {
  final now = DateTime.now();
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  if (sameDay) return '$hh:$mm';
  final d = t.day.toString().padLeft(2, '0');
  final m = t.month.toString().padLeft(2, '0');
  return '$d/$m $hh:$mm';
}

/// Message list + input box. Used by both the user and the admin screens.
/// [myRole] decides which side the bubbles go on ('user' or 'admin').
class ChatView extends StatefulWidget {
  final List<ChatMessage> messages;
  final String myRole;
  final Future<void> Function(String text) onSend;
  final String hint;
  final String emptyText;

  const ChatView({
    super.key,
    required this.messages,
    required this.myRole,
    required this.onSend,
    this.hint = 'Type a message...',
    this.emptyText = 'No messages yet.',
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(covariant ChatView old) {
    super.didUpdateWidget(old);
    if (old.messages.length != widget.messages.length) _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: Text(widget.emptyText,
                      style: TextStyle(color: scheme.outline)))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.messages.length,
                  itemBuilder: (_, i) {
                    final m = widget.messages[i];
                    final mine = m.senderRole == widget.myRole;
                    return _Bubble(
                      message: m,
                      mine: mine,
                      showLocationStatus: widget.myRole == 'admin',
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    counterText: '',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final bool showLocationStatus;
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showLocationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = mine ? const Color(0xFFFCECEF) : scheme.surfaceContainerHighest;
    final fg = mine ? const Color(0xFF8F1D32) : scheme.onSurface;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(message.text, style: TextStyle(color: fg)),
            ),
            if (showLocationStatus && message.senderRole == 'user')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.outOfOffice
                          ? Icons.location_off
                          : Icons.location_on,
                      size: 13,
                      color: message.outOfOffice
                          ? scheme.error
                          : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.outOfOffice
                          ? 'out of office'
                          : 'in office',
                      style: TextStyle(
                        color: message.outOfOffice
                            ? scheme.error
                            : Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 2),
            Text(
              formatTime(message.createdAt),
              style: TextStyle(color: fg.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
