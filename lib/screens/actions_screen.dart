import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/common.dart';

/// Actions hub: My Actions / @Mentions / Updates / Engagements tabs, plus
/// Today's Events / Alerts / Tasks.
class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  int _tab = 0;
  static const _tabs = ['My Actions', '@Mentions', 'Updates', 'Engagements'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actions')),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                for (final t in _tabs)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = _tabs.indexOf(t)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  width: 2.5,
                                  color: _tab == _tabs.indexOf(t)
                                      ? AppColors.primary
                                      : Colors.transparent)),
                        ),
                        child: Text(t,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _tab == _tabs.indexOf(t)
                                    ? AppColors.primary
                                    : AppColors.textSecondary)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _myActions(),
                const _EmptyTab(label: 'No mentions'),
                const _EmptyTab(label: 'No updates'),
                const _EmptyTab(label: 'No engagements'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _myActions() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text("Today's Events",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('No activities found',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Padding(
          padding: EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 8),
          child: Text("Today's Alerts",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('No activities found',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Padding(
          padding: EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 8),
          child: Text("Today's Tasks",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('No activities found',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String label;
  const _EmptyTab({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: EmptyState(
          title: label,
          body: 'Nothing here yet',
          icon: Icons.notifications_none),
    );
  }
}
