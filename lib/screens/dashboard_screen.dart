import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

import 'module_create_screen.dart';
import 'maps_screen.dart';
import 'scan_business_card.dart';

/// Dashboard rebuilt to match the reference prototype: an eyebrow + greeting,
/// a two-up quick-action grid (Map / Scan Business Card), a gradient hero
/// showing the open pipeline, pipeline-by-stage bars, the overview stats,
/// today's agenda card and a running tasks section. Every figure comes from
/// the `/dashboard` API (with events/tasks best-effort on top); nothing is
/// fabricated.
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
  List<CrmRecord> _tasks = const [];

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
      List<CrmRecord> tasks = const [];
      try {
        tasks = await api.records('Tasks');
      } catch (_) {
        // Tasks are a best-effort dashboard section.
      }
      if (!mounted) return;
      setState(() {
        _raw = raw;
        _pipeline = _pipelineFrom(raw);
        _agenda = agenda;
        _tasks = tasks.take(4).toList();
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

  String _money(String raw) {
    final v = double.tryParse(raw.replaceAll(',', '').replaceAll('Rs', '').trim());
    if (v == null) return raw;
    final compact = v >= 1000000
        ? 'Rs ${_trim(v / 1000000)}M'
        : v >= 1000
            ? 'Rs ${_trim(v / 1000)}k'
            : 'Rs ${_trim(v)}';
    return compact;
  }

  String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isEvening = DateTime.now().hour >= 17 || DateTime.now().hour < 5;
    final greeting = isEvening ? 'Good evening' : 'Good morning';
    final nameParts = appState.displayName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : appState.displayName;

    final pipelineTotal = _overview('—', const [
      'pipelineAmount',
      'pipeline',
      'totalPipeline'
    ]);
    final revenue = _overview('—', const ['revenue', 'totalRevenue', 'closedWonAmount']);
    final leadsCount = _overview('0', const ['leads', 'leadCount', 'leadsCount']);
    final tickets = _overview('0', const ['openTickets', 'tickets', 'ticketCount']);
    final openDeals = _pipeline.fold<int>(0, (s, st) => s + st.deals);
    final closedWon = _pipeline
        .where((st) =>
            st.name.toLowerCase().contains('won') ||
            st.name.toLowerCase().contains('closed'))
        .fold<double>(0, (s, st) => s + st.amount);
    final maxAmount =
        _pipeline.fold<double>(0, (m, st) => st.amount > m ? st.amount : m);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          // ---- Greeting: eyebrow + big heading ----
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_todayLabel(),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('$greeting, $firstName',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ---- Quick actions (Map / Scan Business Card) ----
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                    icon: Icons.map_outlined,
                    label: 'Map',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MapsScreen()))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan Business Card',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScanBusinessCardScreen()))),
              ),
            ],
          ),

          // ---- Sections below depend on the API state ----
          if (_loading)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
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
            // ---- Hero: Open pipeline ----
            HeroCard(
              label: 'OPEN PIPELINE',
              figure: _money(pipelineTotal),
              subtitle:
                  '$openDeals active deals · ${_money('$closedWon')} won this quarter',
              bars: _pipeline.isEmpty
                  ? null
                  : [
                      for (final st in _pipeline.take(4))
                        maxAmount > 0 ? st.amount / maxAmount : 0,
                    ],
            ),
            const SizedBox(height: 12),

            // ---- Quick create ----
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
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
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- Pipeline by stage ----
            if (_pipeline.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Text('No pipeline stages yet',
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              )
            else
              BarChartCard(
                title: 'PIPELINE BY STAGE',
                entries: [
                  for (final st in _pipeline) (st.name, st.amount),
                ],
                formatValue: (v) => _money('$v'),
              ),
            const SizedBox(height: 8),

            // ---- Overview stats ----
            const SectionHead('Overview'),
            Row(
              children: [
                Expanded(
                    child: _OverviewTile(
                        title: 'Revenue',
                        value: _money(revenue),
                        color: AppColors.held)),
                const SizedBox(width: 10),
                Expanded(
                    child: _OverviewTile(
                        title: 'Leads',
                        value: leadsCount,
                        color: AppColors.planned)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _OverviewTile(
                        title: 'Open Tickets',
                        value: tickets,
                        color: AppColors.warning)),
                const SizedBox(width: 10),
                Expanded(
                    child: _OverviewTile(
                        title: 'Pipeline',
                        value: _money(pipelineTotal),
                        color: AppColors.hot)),
              ],
            ),
            const SizedBox(height: 6),

            // ---- Today's agenda card ----
            const SectionHead('Today'),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_todayLabel(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  if (_agenda.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Nothing scheduled today.',
                          style: TextStyle(
                              fontSize: 13.5, color: AppColors.textHint)),
                    )
                  else
                    for (final item in _agenda)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            TintedIconBox(
                                _activityIcon(item.type),
                                color: _activityColor(item.type),
                                size: 38),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 1),
                                  Text(
                                      '${formatHour(item.start)} ${formatAmPm(item.start)} · ${item.type}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---- Tasks ----
            const SectionHead('Tasks'),
            if (_tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No tasks to show yet.',
                    style:
                        TextStyle(fontSize: 13.5, color: AppColors.textHint)),
              )
            else
              for (final task in _tasks)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(task.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      if (task.status != null)
                        StatusChip(task.status!,
                            color: statusColor(task.status)),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  IconData _activityIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('call')) return Icons.call_outlined;
    if (t.contains('mail') || t.contains('email'))
      return Icons.mail_outline;
    if (t.contains('meet')) return Icons.people_outline;
    if (t.contains('task') || t.contains('note'))
      return Icons.description_outlined;
    return Icons.event_outlined;
  }

  Color _activityColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('call')) return AppColors.held;
    if (t.contains('mail') || t.contains('email')) return AppColors.planned;
    if (t.contains('meet')) return AppColors.hot;
    return AppColors.info;
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
        CreateField('Salutation', 'Identity'),
        CreateField('First Name', 'Identity', required: true),
        CreateField('Last Name', 'Identity', required: true),
        CreateField('Company', 'Identity', required: true),
        CreateField('Title', 'Identity'),
        CreateField('Email', 'Contact', type: FieldType.email),
        CreateField('Secondary Email', 'Contact', type: FieldType.email),
        CreateField('Phone', 'Contact', type: FieldType.phone),
        CreateField('Mobile', 'Contact', type: FieldType.phone),
        CreateField('Fax', 'Contact', type: FieldType.phone),
        CreateField('Website', 'Contact'),
        CreateField('Lead Source', 'Qualification'),
        CreateField('Lead Status', 'Qualification'),
        CreateField('Campaign Id', 'Qualification'),
        CreateField('Industry', 'Qualification'),
        CreateField('Annual Revenue', 'Qualification'),
        CreateField('No Of Employees', 'Qualification'),
        CreateField('Rating', 'Qualification'),
        CreateField('Interest', 'Qualification'),
        CreateField('Lead Score', 'Qualification'),
        CreateField('Next Follow Up', 'Qualification', type: FieldType.date),
        CreateField('Street', 'Address'),
        CreateField('City', 'Address'),
        CreateField('State', 'Address'),
        CreateField('Country', 'Address'),
        CreateField('Postal Code', 'Address'),
        CreateField('PO Box', 'Address'),
        CreateField('Description', 'Notes', type: FieldType.multiline),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
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

class _OverviewTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _OverviewTile(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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