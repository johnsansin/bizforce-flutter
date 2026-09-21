import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/record_detail.dart';
import 'module_create_screen.dart';
import 'scan_business_card.dart';

/// Generic list screen for a CRM module (Leads, Contacts, Tasks, Documents,
/// Deals, Products, ...). Reads records live from the backend via
/// [AppState]'s [ApiService] — no dummy data. Shows search, empty state,
/// pull-to-refresh and the "Scan Business Card" affordance for Leads/Contacts.
class ModuleListScreen extends StatefulWidget {
  final String title;
  final String module;
  final bool searchable;
  final bool showFABPlus;
  final bool showScanBusinessCard;
  final List<RecordTab> Function(CrmRecord record)? tabFactory;
  const ModuleListScreen({
    super.key,
    required this.title,
    required this.module,
    this.searchable = true,
    this.showFABPlus = true,
    this.showScanBusinessCard = false,
    this.tabFactory,
  });

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<CrmRecord> _data = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _fetch({String? search}) async {
    final api = context.read<AppState>().api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final remote = await api.records(widget.module, search: search ?? _query);
      if (!mounted) return;
      setState(() {
        _data = remote;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _data = const [];
        _loading = false;
        _error =
            e is Exception ? e.toString() : 'Could not load ${widget.title}.';
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value.trim());
    _debounce = Timer(
        const Duration(milliseconds: 350), () => _fetch(search: value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.searchable)
            IconButton(
                icon: const Icon(Icons.search),
                onPressed: () =>
                    FocusScope.of(context).requestFocus(FocusNode())),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search ${widget.title}',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
      floatingActionButton: widget.showFABPlus
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CreateRecordScreen(
                          module: widget.module,
                          fields: _createFields(widget.module)))).then((saved) {
                if (saved == true) _fetch();
              }),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetch(search: _query),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: _error ?? 'There are no ${widget.title}.',
                body: _error == null
                    ? 'Records added in BizForce CRM will appear here.'
                    : 'Pull down to try again.',
                icon: _error == null
                    ? Icons.inbox_outlined
                    : Icons.cloud_off_outlined,
                action: widget.showScanBusinessCard
                    ? FilledButton(
                        onPressed: _scanBusinessCard,
                        child: const Text('Scan Business Card'),
                      )
                    : null,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetch(search: _query),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: _data.length,
        itemBuilder: (context, i) {
          final r = _data[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RecordListTile(record: r, onTap: () => _openDetail(r)),
          );
        },
      ),
    );
  }

  List<CreateField> _createFields(String module) {
    final key = module.toLowerCase();
    if (key == 'leads') {
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
    }
    if (key == 'contacts') {
      return const [
        CreateField('First Name', 'Basic Information'),
        CreateField('Last Name', 'Basic Information', required: true),
        CreateField('Email', 'Basic Information', type: FieldType.email),
        CreateField('Phone', 'Basic Information', type: FieldType.phone),
        CreateField('Organization Name', 'Basic Information'),
        CreateField('Description', 'Description', type: FieldType.multiline),
      ];
    }
    if (key == 'deals') {
      return const [
        CreateField('Name', 'Deal Details', required: true),
        CreateField('Amount', 'Deal Details'),
        CreateField('Sales Stage', 'Deal Details',
            type: FieldType.select,
            options: [
              'Prospecting',
              'Qualification',
              'Proposal',
              'Negotiation',
              'Closed Won',
              'Closed Lost'
            ]),
        CreateField('Description', 'Description', type: FieldType.multiline),
      ];
    }
    return const [
      CreateField('Name', 'Basic Information', required: true),
      CreateField('Status', 'Basic Information'),
      CreateField('Description', 'Description', type: FieldType.multiline),
    ];
  }

  Future<void> _openDetail(CrmRecord record) async {
    CrmRecord fullRecord = record;
    try {
      fullRecord =
          await context.read<AppState>().api.record(widget.module, record.id);
    } catch (_) {
      // Fall back to the list representation when detail loading is unavailable.
    }
    if (!mounted) return;
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordDetailScreen(
          record: fullRecord,
          tabs: widget.tabFactory?.call(fullRecord) ??
              defaultRecordTabs(record: fullRecord),
        ),
      ),
    ).then((changed) {
      if (changed == true) _fetch();
    });
  }

  void _scanBusinessCard() {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ScanBusinessCardScreen(module: widget.module)))
        .then((saved) {
      if (saved == true) _fetch();
    });
  }
}

class _RecordListTile extends StatelessWidget {
  final CrmRecord record;
  final VoidCallback onTap;
  const _RecordListTile({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = record.subtitle ??
        record.fields['Organization Name'] ??
        record.fields['Company'] ??
        record.fields['Primary Email'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              RecordAvatar(record.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w700)),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                    if (record.rating > 0) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.stars,
                            size: 14, color: AppColors.starGold),
                        const SizedBox(width: 4),
                        Text('Profile Rating ${'★' * record.rating.round()}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ],
                  ],
                ),
              ),
              if (record.status != null)
                StatusChip(record.status!, color: statusColor(record.status)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
