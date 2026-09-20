import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/record_detail.dart';

/// Global search reached from the search icon in the app header.
/// Searches every enabled module and opens matches in their detail screen.
/// Uses live API data from each module's records endpoint.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  bool _loading = false;
  Map<String, List<CrmRecord>> _allRecords = const {};

  static const _modules = <String>[
    'Leads',
    'Contacts',
    'Tasks',
    'Events',
    'Documents',
    'Deals',
    'Products',
    'Organizations',
    'Quotes',
    'Cases',
    'Projects',
    'Employees',
    'Invoices',
    'Payments',
    'Purchase Orders',
    'Campaigns',
    'Vendors',
  ];

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadIndex() async {
    final api = context.read<AppState>().api;
    final index = <String, List<CrmRecord>>{};
    for (final module in _modules) {
      try {
        final remote = await api.records(module);
        if (remote.isNotEmpty) index[module] = remote;
      } catch (_) {
        // Skip modules that are unreachable or unavailable.
      }
    }
    if (mounted) setState(() => _allRecords = index);
  }

  void _onChanged(String value) {
    setState(() {
      _query = value.trim().toLowerCase();
      _loading = _query.isNotEmpty;
    });
    if (_query.isEmpty) return;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _query == value.trim().toLowerCase())
        setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final matches = _search();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search Leads, Contacts, Deals…',
              filled: true,
              isDense: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? const EmptyState(
              title: 'Search everything',
              body: 'Find any record across all your CRM modules.',
              icon: Icons.manage_search)
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : matches.isEmpty
                  ? EmptyState(
                      title: "No results for '$_query'",
                      body: 'Try a different keyword.',
                      icon: Icons.search_off)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final group in matches)
                          if (group.groupRecords.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                              child: Text(
                                group.module,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                            for (final r in group.groupRecords)
                              _resultTile(r, group.module),
                          ],
                      ],
                    ),
    );
  }

  List<_ModuleMatch> _search() {
    if (_query.isEmpty) return const [];
    final moduleScores = <String, List<CrmRecord>>{};
    for (final module in _modules) {
      final records = _allRecords[module] ?? const <CrmRecord>[];
      final hits = records.where((r) {
        final hay = [
          r.name,
          r.module,
          if (r.status != null) r.status!,
          ...r.fields.values
        ].join(' ').toLowerCase();
        return hay.contains(_query);
      }).toList();
      if (hits.isNotEmpty) moduleScores[module] = hits;
    }
    return [
      for (final e in moduleScores.entries) _ModuleMatch(e.key, e.value),
    ];
  }

  Widget _resultTile(CrmRecord record, String module) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecordDetailScreen(
            record: record,
            tabs: defaultRecordTabs(record: record),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            RecordAvatar(record.name, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (record.subtitle != null)
                    Text(record.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary)),
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
    );
  }
}

class _ModuleMatch {
  final String module;
  final List<CrmRecord> groupRecords;
  const _ModuleMatch(this.module, this.groupRecords);
}
