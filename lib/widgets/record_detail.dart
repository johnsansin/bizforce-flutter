import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/models.dart';
import '../widgets/common.dart';

class RecordTab {
  final String label;
  final Widget Function(List<CrmRecord> records) builder;
  const RecordTab(this.label, this.builder);
}

/// Generic record detail screen: header (avatar, name, status chips),
/// a tab strip, and the selected tab's body.
///
/// Matches the "One View / Activity / Details / Related" layout seen in
/// the reference app.
class RecordDetailScreen extends StatefulWidget {
  final CrmRecord record;
  final List<RecordTab> tabs;
  final List<CrmRecord>? relatedRecords;
  final Widget? headerAction;
  final bool showProfileRating;
  const RecordDetailScreen({
    super.key,
    required this.record,
    required this.tabs,
    this.relatedRecords,
    this.headerAction,
    this.showProfileRating = true,
  });

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return Scaffold(
      appBar: AppBar(
        title: Text(record.module),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _header(context, record),
          _tabStrip(context),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                for (final tab in widget.tabs)
                  tab.builder(widget.relatedRecords ?? const []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, CrmRecord record) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RecordAvatar(record.name, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700)),
                    if (widget.showProfileRating && record.rating > 0) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.stars,
                            color: AppColors.starGold, size: 18),
                        const SizedBox(width: 4),
                        Text('Profile Rating ${'★' * record.rating.round()}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ]),
                    ],
                  ],
                ),
              ),
              if (widget.headerAction != null) widget.headerAction!,
            ],
          ),
          const SizedBox(height: 8),
          if (record.tags.isNotEmpty || record.status != null)
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (record.tags.isNotEmpty)
                for (final t in record.tags)
                  StatusChip(t, color: AppColors.textSecondary, dot: false),
              if (record.status != null)
                StatusChip(record.status!, color: statusColor(record.status)),
            ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tabStrip(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          for (int i = 0; i < widget.tabs.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _index = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2.5,
                        color: _index == i
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Text(
                    widget.tabs[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _index == i
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pre-built default tab set: One View / Activity / Details / Related.
List<RecordTab> defaultRecordTabs({
  required CrmRecord record,
  Widget? oneViewExtra,
}) {
  return [
    RecordTab('One View',
        (records) => OneViewTab(record: record, extra: oneViewExtra)),
    RecordTab(
        'Activity',
        (records) => const _PlaceholderTab(
            icon: Icons.notifications_none, message: 'No activities found')),
    RecordTab('Details', (records) => _DetailsTab(record: record)),
    RecordTab('Related', (_) => RelatedTab(record: record)),
  ];
}

class OneViewTab extends StatelessWidget {
  final CrmRecord record;
  final Widget? extra;
  const OneViewTab({super.key, required this.record, this.extra});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        if (extra != null) extra!,
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Description',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Add Description',
              style: TextStyle(fontSize: 14, color: AppColors.textHint)),
        ),
        const SizedBox(height: 16),
        KeyFieldsSection(record.fields),
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final CrmRecord record;
  const _DetailsTab({required this.record});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        KeyFieldsSection(record.fields),
      ],
    );
  }
}

class RelatedTab extends StatelessWidget {
  final CrmRecord record;
  const RelatedTab({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: const [
        _PlaceholderTab(
          icon: Icons.link,
          message: 'No related records found',
        ),
      ],
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String message;
  const _PlaceholderTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
