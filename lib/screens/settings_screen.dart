import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../data/api_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Settings matching the reference: Notification, Sync, Offline Storage,
/// Dark Mode, Call Logging, App Info and Legal. Sync + toggles talk to the
/// backend `/settings` API.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _offlineStorage = true;
  bool _autoSync = true;
  bool _wifiOnly = true;
  bool _syncCallLogs = false;
  String _callLogging = 'Never';
  String _syncInterval = '1 hour';
  String? _lastSynced;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await context.read<AppState>().api.settings();
      if (!mounted) return;
      setState(() {
        _pushEnabled = data['pushNotifications'] == true;
        _offlineStorage = data['offlineStorage'] == true;
        _autoSync = data['autoSync'] == true;
        _wifiOnly = data['wifiOnly'] == true;
        _syncCallLogs = data['syncCallLogs'] == true;
        _callLogging = data['callLogging']?.toString() ?? 'Never';
        _syncInterval = data['autoSyncInterval']?.toString() ?? '1 hour';
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not load settings from the server.')));
      }
    }
  }

  void _pick<T>(String title, List<T> options, ValueChanged<T> onSelect,
      {String Function(T)? labelOf}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          for (final o in options)
            ListTile(
              title: Text(labelOf?.call(o) ?? '$o'),
              onTap: () {
                onSelect(o);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _saveSetting(Map<String, dynamic> diff,
      {String? success}) async {
    final api = context.read<AppState>().api;
    try {
      await api.updateSettings(diff);
      if (success != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save setting: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to reach the server.')));
    }
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final api = context.read<AppState>().api;
    try {
      await api.settings();
      final now = DateTime.now();
      final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final label =
          '${now.day}/${now.month}/${now.year} $h:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      if (!mounted) return;
      setState(() {
        _lastSynced = label;
        _syncing = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings synced')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to reach the server.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _GroupLabel('Notification Settings'),
          ContentCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              value: _pushEnabled,
              onChanged: (v) {
                setState(() => _pushEnabled = v);
                _saveSetting({'pushNotifications': v});
              },
              title: const Text('Push Notifications',
                  style: TextStyle(fontSize: 15)),
            ),
          ),
          const _GroupLabel('Sync'),
          ContentCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                _row(
                  title: 'Refresh Settings & Offline data',
                  trailing: _syncing
                      ? const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : TextButton(
                          onPressed: _syncNow, child: const Text('Sync Now')),
                  onTap: _syncing ? null : _syncNow,
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor),
                _row(
                    title: _lastSynced ?? 'Last synced a few seconds ago',
                    caption: 'Last sync',
                    onTap: () {}),
              ],
            ),
          ),
          const _GroupLabel('Offline Storage'),
          ContentCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: _offlineStorage,
                  onChanged: (v) {
                    setState(() => _offlineStorage = v);
                    _saveSetting({'offlineStorage': v});
                  },
                  title: const Text('Offline Storage',
                      style: TextStyle(fontSize: 15)),
                  subtitle: const Text('Save records to be accessed offline',
                      style: TextStyle(fontSize: 13)),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor),
                SwitchListTile(
                  value: _autoSync,
                  onChanged: (v) {
                    setState(() => _autoSync = v);
                    _saveSetting({'autoSync': v});
                  },
                  title:
                      const Text('Auto-sync', style: TextStyle(fontSize: 15)),
                  subtitle: const Text(
                      'Sync offline data automatically when your device connects to a network',
                      style: TextStyle(fontSize: 13)),
                ),
                SwitchListTile(
                  value: _wifiOnly,
                  onChanged: (v) {
                    setState(() => _wifiOnly = v);
                    _saveSetting({'wifiOnly': v});
                  },
                  title:
                      const Text('Wifi only', style: TextStyle(fontSize: 15)),
                  subtitle: const Text('Only sync when on WiFi',
                      style: TextStyle(fontSize: 13)),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor),
                _row(
                  title: 'Auto-sync interval',
                  value: _syncInterval,
                  onTap: () => _pick('Auto-sync interval', const [
                    '30 minutes',
                    '1 hour',
                    '3 hours',
                    '6 hours'
                  ], (v) {
                    setState(() => _syncInterval = v);
                    _saveSetting({'autoSyncInterval': v});
                  }),
                ),
              ],
            ),
          ),
          const _GroupLabel('Appearance'),
          ContentCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              value: appState.darkMode,
              onChanged: (v) => appState.toggleDarkMode(v),
              title: const Text('Dark Mode', style: TextStyle(fontSize: 15)),
              subtitle: const Text('Switch to dark mode',
                  style: TextStyle(fontSize: 13)),
            ),
          ),
          const _GroupLabel('Call Logging'),
          ContentCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _row(
                  title: 'Create an event for calls from the app',
                  value: _callLogging,
                  onTap: () => _pick('Call Logging',
                      const ['Never', 'Always', 'Ask every time'], (v) {
                    setState(() => _callLogging = v);
                    _saveSetting({'callLogging': v});
                  }),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor),
                SwitchListTile(
                  value: _syncCallLogs,
                  onChanged: (v) {
                    setState(() => _syncCallLogs = v);
                    _saveSetting({'syncCallLogs': v});
                  },
                  title: const Text('Sync call logs',
                      style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
          const _GroupLabel('App Info'),
          ContentCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title:
                      Text(AppConfig.appName, style: TextStyle(fontSize: 15)),
                  subtitle: Text('Version ${AppConfig.appVersion}',
                      style: TextStyle(fontSize: 12)),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined, size: 20),
                  title: const Text('Policy & Legal Center',
                      style: TextStyle(fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
      {required String title,
      String? value,
      String? caption,
      Widget? trailing,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15)),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(caption,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (value != null)
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.textSecondary)),
    );
  }
}
