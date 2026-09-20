import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

import 'module_create_screen.dart';
import 'tasks_screen.dart';
import 'maps_screen.dart';
import 'scan_business_card.dart';
import 'search_screen.dart';

/// Dashboard: greeting, Quick Create, Overview, Pipeline, Today's agenda.
/// All figures come from the `/dashboard` API (with events for the agenda);
/// nothing is fabricated.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _raw = const {};
  List<PipelineStage> _pipeline = const [];
  List<AgendaItem> _agenda = const [];

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
    final api = context.read<AppState>().api;
    try {
      final raw = await api.dashboard();
      List<AgendaItem> agenda = [];
      if (raw['agenda'] is List) {
        final items = _agendaFrom(raw['agenda'] as List);
        if (items.isNotEmpty) agenda = items;
      }
      if (agenda.isEmpty) {
        try {
          agenda = eventItemsFrom(await api.records('Events'));
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _raw = raw;
        _pipeline = _pipelineFrom(raw);
        _agenda = agenda;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Unable to load dashboard.';
        _loading = false;
      });
    }
  }

  List<PipelineStage> _pipelineFrom(Map<String, dynamic> raw) {
    final stages = <PipelineStage>[];
    dynamic list;
    if (raw['pipelineStages'] is List) {
      list = raw['pipelineStages'];
    } else if (raw['stages'] is List) {
      list = raw['stages'];
    } else if (raw['pipeline'] is List) {
      list = raw['pipeline'];
    }
    if (list is List) {
      for (final s in list) {
        if (s is Map) {
          final name = '${s['name'] ?? s['stage'] ?? 'Stage'}';
          final deals = s['deals'] is num
              ? (s['deals'] as num).toInt()
              : int.tryParse('${s['deals'] ?? '0'}') ?? 0;
          final amount = s['amount'] is num
              ? (s['amount'] as num).toDouble()
              : double.tryParse('${s['amount'] ?? '0'}') ?? 0;
          stages.add(PipelineStage(name, deals, amount));
        }
      }
    }
    return stages;
  }

  List<AgendaItem> _agendaFrom(List list) {
    final items = <AgendaItem>[];
    for (final s in list) {
      if (s is! Map) continue;
      final startRaw = '${s['start'] ?? s['startDate'] ?? s['date'] ?? ''}';
      final start = parseCrmDateTime(startRaw);
      if (start == null) continue;
      items.add(AgendaItem(
        start: start,
        end: parseCrmDateTime('${s['end'] ?? ''}') ??
            start.add(const Duration(hours: 1)),
        title: '${s['title'] ?? s['name'] ?? s['subject'] ?? 'Event'}',
        type: '${s['type'] ?? s['activityType'] ?? 'Event'}',
        priority: '${s['priority'] ?? 'Medium'}',
        status: '${s['status'] ?? 'Planned'}',
      ));
    }
    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }

  String _overview(String fallback, List<String> keys) {
    for (final k in keys) {
      final v = _raw[k];
      if (v != null &&
          v is! List &&
          v is! Map &&
          '$v'.isNotEmpty &&
          '$v' != 'null') return '$v';
    }
    if (_raw['overview'] is Map) {
      final o = _raw['overview'] as Map;
      for (final k in keys) {
        final v = o[k];
        if (v != null && '$v'.isNotEmpty && '$v' != 'null') return '$v';
      }
    }
    return fallback;
  }

  void _quickCreate(BuildContext context, String label) {
    final module = label == 'Contact'
        ? 'Contacts'
        : label == 'Lead'
            ? 'Leads'
            : label == 'Task'
                ? 'Tasks'
                : 'Events';
    if (module == 'Tasks') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const TasksScreen()));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRecordScreen(
          module: module,
          fields: fieldSpecFor(module),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isEvening = DateTime.now().hour >= 17 || DateTime.now().hour < 5;
    final greeting = isEvening ? 'Good evening' : 'Good morning';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '$greeting, ${appState.displayName.split(' ').first}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const Text('Your agenda, follow-ups and CRM insights',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchScreen())),
                    icon: const Icon(Icons.search)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ActionTile(
                      icon: Icons.map_outlined,
                      label: 'Map',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MapsScreen()))),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _ActionTile(
                      icon: Icons.qr_code_scanner,
                      label: 'Scan Business Card',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ScanBusinessCardScreen()))),
                ),
              ),
            ],
          ),
          const _SectionLabel('QUICK CREATE'),
          Row(
            children: [
              for (final a in const [
                QuickAction('Lead', Icons.add),
                QuickAction('Contact', Icons.add),
                QuickAction('Task', Icons.add),
                QuickAction('Meeting', Icons.add),
              ])
                Expanded(
                  child: InkWell(
                    onTap: () => _quickCreate(context, a.label),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(height: 6),
                          Text(a.label,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const _SectionLabel('OVERVIEW'),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(_error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                  TextButton(onPressed: _fetch, child: const Text('Retry')),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                      child: _OverviewTile(
                          title: 'Revenue',
                          value: _overview('—', const [
                            'revenue',
                            'totalRevenue',
                            'closedWonAmount'
                          ]),
                          color: AppColors.held)),
                  Expanded(
                      child: _OverviewTile(
                          title: 'Leads',
                          value: _overview(
                              '0', const ['leads', 'leadCount', 'leadsCount']),
                          color: AppColors.planned)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                      child: _OverviewTile(
                          title: 'Open Tickets',
                          value: _overview('0',
                              const ['openTickets', 'tickets', 'ticketCount']),
                          color: AppColors.warning)),
                  Expanded(
                      child: _OverviewTile(
                          title: 'Pipeline',
                          value: _overview(
                              '—', const ['pipeline', 'pipelineAmount']),
                          color: AppColors.hot)),
                ],
              ),
            ),
            const _SectionLabel('PIPELINE'),
            ContentCard(
              padding: const EdgeInsets.all(14),
              child: _pipeline.isEmpty
                  ? const Text('No pipeline stages yet',
                      style: TextStyle(color: AppColors.textSecondary))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (final s in _pipeline) _pipeRow(s)],
                    ),
            ),
            const _SectionLabel("TODAY'S AGENDA"),
            if (_agenda.isEmpty)
              const ContentCard(
                  child: Text('No events for the day',
                      style: TextStyle(color: AppColors.textSecondary)))
            else
              for (final item in _agenda)
                ContentCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Column(
                          children: [
                            Text(formatHour(item.start),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            Text(formatAmPm(item.start),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(item.type,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      StatusChip(item.status, color: statusColor(item.status)),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

String formatHour(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatAmPm(DateTime d) => d.hour >= 12 ? 'PM' : 'AM';

/// Default field specs for generic create screens per module.
List<CreateField> fieldSpecFor(String module) {
  switch (module) {
    case 'Leads':
      return const [
        CreateField('Salutation', 'Lead Details',
            type: FieldType.select, options: ['Mr.', 'Ms.', 'Mrs.', 'Dr.']),
        CreateField('First Name', 'Lead Details', required: true),
        CreateField('Last Name', 'Lead Details', required: true),
        CreateField('Company', 'Lead Details', required: true),
        CreateField('Primary Email', 'Lead Details', type: FieldType.email),
        CreateField('Office Phone', 'Lead Details', type: FieldType.phone),
        CreateField('Mobile Phone', 'Lead Details', type: FieldType.phone),
        CreateField('Designation', 'Lead Details',
            type: FieldType.select,
            options: ['CEO', 'Manager', 'Owner', 'Sales Executive']),
        CreateField('Country', 'Address Details',
            type: FieldType.select,
            options: ['Pakistan', 'India', 'UAE', 'USA']),
        CreateField('Street', 'Address Details'),
        CreateField('PO Box', 'Address Details'),
        CreateField('Postal Code', 'Address Details'),
        CreateField('City', 'Address Details'),
        CreateField('State', 'Address Details',
            type: FieldType.select,
            options: ['Punjab', 'Sindh', 'KPK', 'Balochistan']),
        CreateField('Description', 'Description Details',
            type: FieldType.multiline),
      ];
    case 'Contacts':
      return const [
        CreateField('Salutation', 'Basic Information',
            type: FieldType.select, options: ['Mr.', 'Ms.', 'Mrs.', 'Dr.']),
        CreateField('First Name', 'Basic Information', required: true),
        CreateField('Last Name', 'Basic Information', required: true),
        CreateField('Primary Email', 'Basic Information',
            type: FieldType.email),
        CreateField('Office Phone', 'Basic Information', type: FieldType.phone),
        CreateField('Mobile Phone', 'Basic Information', type: FieldType.phone),
        CreateField('Home Phone', 'Basic Information', type: FieldType.phone),
        CreateField('Date of Birth', 'Basic Information', type: FieldType.date),
        CreateField('Portal User', 'Customer Portal Details',
            type: FieldType.yesno),
        CreateField('Support Start Date', 'Customer Portal Details',
            type: FieldType.date),
        CreateField('Support End Date', 'Customer Portal Details',
            type: FieldType.date),
        CreateField('Mailing Country', 'Address Details',
            type: FieldType.select,
            options: ['Pakistan', 'India', 'UAE', 'USA']),
        CreateField('Mailing Street', 'Address Details'),
        CreateField('Mailing P.O. Box', 'Address Details'),
        CreateField('Mailing City', 'Address Details'),
        CreateField('Mailing State', 'Address Details',
            type: FieldType.select,
            options: ['Punjab', 'Sindh', 'KPK', 'Balochistan']),
        CreateField('Mailing Zip', 'Address Details'),
        CreateField('Description', 'Description Details',
            type: FieldType.multiline),
        CreateField('Linkedin URL', 'Socials', type: FieldType.text),
        CreateField('Facebook URL', 'Socials', type: FieldType.text),
      ];
    case 'Documents':
      return const [
        CreateField('File Name', 'Basic Information', required: true),
        CreateField('Active', 'Basic Information', type: FieldType.yesno),
        CreateField('Document Type', 'File Sharing Info',
            type: FieldType.select, options: ['Private', 'Public', 'Shared']),
        CreateField('Description', 'Description Details',
            type: FieldType.multiline),
      ];
    default:
      return const [
        CreateField('Name', 'Details', required: true),
        CreateField('Description', 'Details', type: FieldType.multiline),
      ];
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _OverviewTile(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

Widget _pipeRow(PipelineStage stage) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(stage.name, style: const TextStyle(fontSize: 14)),
        ),
        Text('${stage.deals} deals',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: LinearProgressIndicator(
            value: stage.amount > 0 ? (stage.amount / 50).clamp(0.0, 1.0) : 0,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    ),
  );
}
