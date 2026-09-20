import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/common.dart';

class _Conversation {
  final String name;
  final String lastMessage;
  final String time;
  final bool unread;
  final int unreadCount;
  const _Conversation(
      this.name, this.lastMessage, this.time, this.unread, this.unreadCount);
}

/// Chat / conversations hub accessible from the chat icon in the app header.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _conversations = <_Conversation>[
    _Conversation('Amelia Foster', 'Hi, did you get the proposal I sent?',
        '10:24', true, 2),
    _Conversation('Liam Carter', 'Sounds good, let’s schedule the demo.',
        '09:47', true, 1),
    _Conversation(
        'Maya Patel', 'Thanks for the quick follow-up!', 'Yesterday', false, 0),
    _Conversation('Noah Williams', 'The contract has been signed ✔',
        'Yesterday', false, 0),
    _Conversation(
        'Sales Team', 'New leads assigned for this week', 'Mon', false, 0),
    _Conversation(
        'Olivia Brown', 'Can we move the meeting to 3pm?', 'Mon', false, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Chat', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.group_add_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (context, i) => Divider(
            height: 1, indent: 72, color: Theme.of(context).dividerColor),
        itemBuilder: (context, i) {
          final c = _conversations[i];
          return ListTile(
            leading: RecordAvatar(c.name, size: 46),
            title: Row(
              children: [
                Expanded(
                  child: Text(c.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Text(c.time,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            c.unread ? AppColors.primary : AppColors.textHint)),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    c.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: c.unread ? FontWeight.w600 : FontWeight.w400,
                      color:
                          c.unread ? Colors.black87 : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (c.unread)
                  Container(
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${c.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _ConversationView(title: 'Chat'))),
          );
        },
      ),
    );
  }
}

class _ConversationView extends StatefulWidget {
  final String title;
  const _ConversationView({required this.title});

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _controller = TextEditingController();
  final List<_Message> _messages = [
    const _Message('Hi there, just checking in.', false),
    const _Message('Hi! Yes, everything looks good on our side.', true),
    const _Message('Great. I will share the updated document shortly.', false),
    const _Message('Perfect, thanks!', true),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text, false));
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat'), actions: [
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ]),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment:
                      m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.72),
                    decoration: BoxDecoration(
                      color: m.mine
                          ? AppColors.primary
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: m.mine
                          ? null
                          : Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: m.mine
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            color: Theme.of(context).cardColor,
            child: SafeArea(
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                      onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool mine;
  const _Message(this.text, this.mine);
}
