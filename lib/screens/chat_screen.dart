import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/api_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String _name(Map<String, dynamic> item) {
    final name = '${item['name'] ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    final others = item['others'];
    if (others is List && others.isNotEmpty && others.first is Map) {
      final user = others.first as Map;
      final full =
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
      return full.isNotEmpty ? full : '${user['email'] ?? 'Chat'}';
    }
    return 'Chat';
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<AppState>().api.chatConversations();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _newChat() async {
    try {
      final users = await context.read<AppState>().api.chatUsers();
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Start a chat'),
          children: users.map((user) {
            final name =
                '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, '${user['id'] ?? ''}'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: RecordAvatar(
                    name.isEmpty ? '${user['email'] ?? '?'}' : name),
                title: Text(name.isEmpty ? '${user['email'] ?? 'User'}' : name),
                subtitle: Text('${user['email'] ?? ''}'),
              ),
            );
          }).toList(),
        ),
      );
      if (selected == null || selected.isEmpty || !mounted) return;
      final id =
          await context.read<AppState>().api.createChatConversation([selected]);
      await _fetch();
      if (!mounted || id.isEmpty) return;
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatConversationScreen(conversationId: id, title: 'Chat'),
          )).then((_) => _fetch());
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat failed: ${e.message}')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  title: 'Could not load chat',
                  body: _error!,
                  icon: Icons.cloud_off_outlined,
                  action:
                      TextButton(onPressed: _fetch, child: const Text('Retry')))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: _items.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          EmptyState(
                              title: 'No conversations yet',
                              body: 'Tap + to start a chat',
                              icon: Icons.chat_bubble_outline)
                        ])
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final title = _name(item);
                            final unread =
                                (item['unreadCount'] as num?)?.toInt() ?? 0;
                            final last = item['lastMessage'];
                            final preview =
                                last is Map ? '${last['body'] ?? ''}' : '';
                            return ListTile(
                              leading: RecordAvatar(title),
                              title: Text(title),
                              subtitle: Text(
                                  preview.isEmpty ? 'No messages yet' : preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              trailing: unread > 0
                                  ? Badge(label: Text('$unread'))
                                  : null,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatConversationScreen(
                                        conversationId: '${item['id']}',
                                        title: title),
                                  )).then((_) => _fetch()),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
          onPressed: _newChat, child: const Icon(Icons.add_comment_outlined)),
    );
  }
}

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  const ChatConversationScreen(
      {super.key, required this.conversationId, required this.title});
  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _message = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final api = context.read<AppState>().api;
      final items = await api.chatMessages(widget.conversationId);
      await api.markChatRead(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context
          .read<AppState>()
          .api
          .sendChatMessage(widget.conversationId, text);
      _message.clear();
      await _fetch();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AppState>().profile['id'];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[_items.length - index - 1];
                            final mine = '${item['senderId'] ?? ''}' == myId;
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                constraints:
                                    const BoxConstraints(maxWidth: 300),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: mine
                                      ? null
                                      : Border.all(
                                          color:
                                              Theme.of(context).dividerColor),
                                ),
                                child: Text('${item['body'] ?? ''}',
                                    style: TextStyle(
                                        color: mine
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : null)),
                              ),
                            );
                          },
                        ))),
        SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(children: [
            Expanded(
                child: TextField(
                    controller: _message,
                    onSubmitted: (_) => _send(),
                    decoration:
                        const InputDecoration(hintText: 'Type a message...'))),
            IconButton(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded)),
          ]),
        )),
      ]),
    );
  }
}
