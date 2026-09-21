import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/api_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<AppState>().api.notifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  Future<void> _read(Map<String, dynamic> item) async {
    if (item['isRead'] == true) return;
    await context.read<AppState>().api.markNotificationRead('${item['id']}');
    await _fetch();
  }

  Future<void> _readAll() async {
    await context.read<AppState>().api.markAllNotificationsRead();
    await _fetch();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications'), actions: [
          TextButton(
              onPressed:
                  _items.any((e) => e['isRead'] != true) ? _readAll : null,
              child: const Text('Read all')),
        ]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? EmptyState(
                    title: 'Could not load notifications',
                    body: _error!,
                    icon: Icons.cloud_off_outlined,
                    action: TextButton(
                        onPressed: _fetch, child: const Text('Retry')))
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: _items.isEmpty
                        ? ListView(children: const [
                            SizedBox(height: 120),
                            EmptyState(
                                title: 'No notifications',
                                body: 'New notifications will appear here',
                                icon: Icons.notifications_none)
                          ])
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final unread = item['isRead'] != true;
                              return ListTile(
                                leading: Icon(unread
                                    ? Icons.notifications_active_outlined
                                    : Icons.notifications_none),
                                title: Text(
                                    '${item['title'] ?? 'Notification'}',
                                    style: TextStyle(
                                        fontWeight: unread
                                            ? FontWeight.w700
                                            : FontWeight.w400)),
                                subtitle: Text('${item['message'] ?? ''}'),
                                trailing: unread ? const Badge() : null,
                                onTap: () => _read(item),
                              );
                            },
                          )),
      );
}
