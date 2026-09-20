import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

import 'dashboard_screen.dart';

import 'module_list_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'inbox_screen.dart';
import 'maps_screen.dart';
import 'actions_screen.dart';
import 'events_screen.dart';
import 'tasks_screen.dart';
import 'documents_screen.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'scan_business_card.dart';

/// Root shell: bottom navigation (Dashboard / Leads / Tasks / Calendar /
/// More) and the hamburger drawer that reveals every CRM module in
/// collapsible groups (SALES, MARKETING, Projects, INVENTORY, HELP DESK, …).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Set<String> _expandedGroups = {'Favourites'};
  String _menuQuery = '';

  static const _navItems = <(String, IconData)>[
    ('Dashboard', Icons.dashboard_outlined),
    ('Leads', Icons.person_add_alt_1_outlined),
    ('Tasks', Icons.checklist_rtl),
    ('Calendar', Icons.calendar_month_outlined),
    ('More', Icons.more_horiz),
  ];

  void _openModule(BuildContext context, String module) {
    final moduleKey = module.toLowerCase().replaceAll(' ', '');
    switch (moduleKey) {
      case 'dashboard':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const HomeShell()));
      case 'inbox':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const InboxScreen()));
      case 'actions':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ActionsScreen()));
      case 'maps':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MapsScreen()));
      case 'events':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EventsScreen()));
      case 'tasks':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const TasksScreen()));
      case 'documents':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DocumentsScreen()));
      case 'settings':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      case 'help':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const HelpScreen()));
      case 'chat':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ChatScreen()));
      case 'businesscardscanner':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ScanBusinessCardScreen()));
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModuleListScreen(
              title: module,
              module: module,
              showScanBusinessCard: module == 'Leads' || module == 'Contacts',
            ),
          ),
        );
    }
  }

  void _openChat() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const ChatScreen()));

  void _openSearch() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const SearchScreen()));

  Future<void> _logOut() async {
    await context.read<AppState>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardScreen(),
      _modulePage('Leads', showScan: true),
      const TasksScreen(),
      const EventsScreen(),
      const _MorePage(),
    ];
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            _navItems[_index].$1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
          IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: _openChat),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'chat':
                  _openChat();
                case 'search':
                  _openSearch();
                case 'settings':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()));
                case 'help':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'search',
                  child: ListTile(
                      leading: Icon(Icons.search),
                      title: Text('Search'),
                      contentPadding: EdgeInsets.zero)),
              PopupMenuItem(
                  value: 'chat',
                  child: ListTile(
                      leading: Icon(Icons.chat_bubble_outline),
                      title: Text('Chat'),
                      contentPadding: EdgeInsets.zero)),
              PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero)),
              PopupMenuItem(
                  value: 'help',
                  child: ListTile(
                      leading: Icon(Icons.help_outline),
                      title: Text('Help'),
                      contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _modulePage(String title, {bool showScan = false}) {
    return ModuleListScreen(
      title: title,
      module: title,
      showScanBusinessCard: showScan,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            for (int i = 0; i < _navItems.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: _index == i
                                ? AppColors.primary.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _navItems[i].$2,
                            color: _index == i
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _navItems[i].$1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                _index == i ? FontWeight.w700 : FontWeight.w500,
                            color: _index == i
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    const sections = MockMenu.sections;
    final searching = _menuQuery.trim().isNotEmpty;
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.86,
      child: SafeArea(
        child: Column(
          children: [
            _drawerHeader(context),
            _drawerSearchField(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (searching)
                    for (final item in _menuResults(sections))
                      ListTile(
                        dense: true,
                        leading: _iconFor(item.icon, item.colorHex),
                        title: Text(item.label,
                            style: const TextStyle(fontSize: 14.5)),
                        onTap: () {
                          Navigator.pop(context);
                          _openModule(context, item.module);
                        },
                      )
                  else
                    for (final section in sections)
                      _buildGroup(context, section),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            _drawerFooter(context),
          ],
        ),
      ),
    );
  }

  List<MenuItem> _menuResults(List<MenuSection> sections, {int limit = 40}) {
    final q = _menuQuery.trim().toLowerCase();
    final results = <MenuItem>[];
    for (final section in sections) {
      for (final item in section.items) {
        final hay =
            '${item.label} ${item.module} ${section.title}'.toLowerCase();
        if (hay.contains(q)) results.add(item);
      }
    }
    return results.take(limit).toList();
  }

  Widget _buildGroup(BuildContext context, MenuSection section) {
    final initiallyExpanded = _expandedGroups.contains(section.title);
    return ExpansionTile(
      key: ValueKey('${section.title}-open'),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: (open) {
        setState(() {
          if (open) {
            _expandedGroups.add(section.title);
          } else {
            _expandedGroups.remove(section.title);
          }
        });
      },
      shape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.only(bottom: 4),
      leading: _iconFor(section.items.first.icon, null),
      title: Text(
        section.title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      children: [
        for (final item in section.items)
          ListTile(
            dense: true,
            leading: _iconFor(item.icon, item.colorHex),
            title: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(item.label, style: const TextStyle(fontSize: 14.5)),
            ),
            onTap: () {
              Navigator.pop(context);
              _openModule(context, item.module);
            },
          ),
      ],
    );
  }

  Widget _drawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'BizForce CRM',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _openChat();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _drawerSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: SearchField(
        hint: 'Search menu items',
        onChanged: (v) => setState(() => _menuQuery = v),
      ),
    );
  }

  Widget _drawerFooter(BuildContext context) {
    final appState = context.watch<AppState>();
    final displayName = appState.displayName;
    final email = appState.email.isNotEmpty
        ? appState.email
        : appState.profile['email'] ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings_outlined,
                              size: 20, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Settings', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HelpScreen()));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.help_outline,
                              size: 20, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Help', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  RecordAvatar(displayName, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (email.isNotEmpty)
                          Text(email,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _logOut();
                    },
                    child: const Text('Log Out',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.danger)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconFor(IconData icon, String? colorHex) {
    return Icon(icon, size: 20, color: AppColors.textSecondary);
  }
}

/// "More" tab: quick links to profile, chat, help, settings and account.
class _MorePage extends StatelessWidget {
  const _MorePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('More',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _tile(context, Icons.person_outline, 'My Profile', () {}),
        _tile(context, Icons.notifications_none, 'Notifications', () {}),
        _tile(context, Icons.chat_bubble_outline, 'Chat', () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ChatScreen()));
        }),
        _tile(context, Icons.map_outlined, 'My Map', () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const MapsScreen()));
        }),
        const Divider(height: 24),
        _tile(context, Icons.settings_outlined, 'Settings', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }),
        _tile(context, Icons.help_outline, 'Help', () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HelpScreen()));
        }),
        _tile(context, Icons.import_export, 'Export Data', () {}),
        const Divider(height: 24),
        _tile(context, Icons.logout, 'Log Out', () async {
          await context.read<AppState>().signOut();
        }, danger: true),
      ],
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon,
          color: danger ? AppColors.danger : AppColors.textSecondary),
      title: Text(label,
          style:
              TextStyle(fontSize: 15, color: danger ? AppColors.danger : null)),
      trailing:
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}

/// Menu items grouped by section, mirroring the reference app's drawer.
class MockMenu {
  MockMenu._();
  static const sections = <MenuSection>[
    MenuSection('Favourites', [
      MenuItem('Leads', Icons.person_add_alt_1_outlined, 'Leads'),
      MenuItem('Contacts', Icons.people_outline, 'Contacts'),
      MenuItem('Tasks', Icons.checklist_rtl, 'Tasks'),
      MenuItem('Documents', Icons.description_outlined, 'Documents'),
      MenuItem('Dashboard', Icons.dashboard_outlined, 'Dashboard'),
      MenuItem('Inbox', Icons.email_outlined, 'Inbox'),
      MenuItem('Actions', Icons.bolt_outlined, 'Actions'),
      MenuItem('Maps', Icons.map_outlined, 'Maps'),
      MenuItem('Events', Icons.event_outlined, 'Events'),
    ]),
    MenuSection('SALES', [
      MenuItem('Deals', Icons.trending_up, 'Deals'),
      MenuItem('Inbox', Icons.email_outlined, 'Inbox'),
      MenuItem('Quotes', Icons.request_quote_outlined, 'Quotes'),
      MenuItem('Sales Orders', Icons.receipt_long_outlined, 'Sales Orders'),
      MenuItem('Documents', Icons.description_outlined, 'Documents'),
    ]),
    MenuSection('MARKETING', [
      MenuItem('Campaigns', Icons.campaign_outlined, 'Campaigns'),
      MenuItem('Leads', Icons.person_add_alt_1_outlined, 'Leads'),
      MenuItem('Contacts', Icons.people_outline, 'Contacts'),
      MenuItem('Organizations', Icons.business_outlined, 'Organizations'),
      MenuItem('Tasks', Icons.checklist_rtl, 'Tasks'),
      MenuItem('Documents', Icons.description_outlined, 'Documents'),
    ]),
    MenuSection('Projects', [
      MenuItem('Tasks', Icons.task_alt, 'Tasks'),
      MenuItem('Project Milestones', Icons.flag_outlined, 'Project Milestones'),
      MenuItem('Projects', Icons.layers_outlined, 'Projects'),
      MenuItem('Timelogs', Icons.timer_outlined, 'Timelogs'),
    ]),
    MenuSection('INVENTORY', [
      MenuItem('Products', Icons.inventory_2_outlined, 'Products'),
      MenuItem('Services', Icons.build_outlined, 'Services'),
      MenuItem('Price Books', Icons.price_change_outlined, 'Price Books'),
      MenuItem('Invoices', Icons.receipt_outlined, 'Invoices'),
      MenuItem('Sales Orders', Icons.receipt_long_outlined, 'Sales Orders'),
      MenuItem(
          'Purchase Orders', Icons.shopping_cart_outlined, 'Purchase Orders'),
      MenuItem('Vendors', Icons.local_shipping_outlined, 'Vendors'),
      MenuItem('Payments', Icons.payments_outlined, 'Payments'),
      MenuItem('Work Orders', Icons.handyman_outlined, 'Work Orders'),
      MenuItem('Assets', Icons.devices_other, 'Assets'),
    ]),
    MenuSection('HELP DESK', [
      MenuItem('Cases', Icons.support_agent, 'Cases'),
      MenuItem('FAQ', Icons.help_outline, 'FAQ'),
      MenuItem('Service Contracts', Icons.verified_user_outlined,
          'Service Contracts'),
      MenuItem('Internal Tickets', Icons.confirmation_number_outlined,
          'Internal Tickets'),
      MenuItem('Employees', Icons.badge_outlined, 'Employees'),
    ]),
    MenuSection('Others', [
      MenuItem('Approvals', Icons.approval_outlined, 'Approvals'),
      MenuItem('Maps', Icons.map_outlined, 'Maps'),
      MenuItem('Phone Calls', Icons.phone_outlined, 'Phone Calls'),
      MenuItem('SMS Messages', Icons.sms_outlined, 'SMS Messages'),
      MenuItem('My Apps', Icons.apps, 'My Apps'),
    ]),
  ];
}
