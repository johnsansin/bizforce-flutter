import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/record_detail.dart';

/// Quotes list + detail (with a printable-style preview tab). Records come
/// from the Quotes module API.
class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  List<CrmRecord> _quotes = [];
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
    final api = context.read<AppState>().api;
    try {
      final records = await api.records('Quotes');
      if (!mounted) return;
      setState(() {
        _quotes = records;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load quotes.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  title: 'Could not load quotes',
                  body: _error!,
                  icon: Icons.cloud_off,
                  action:
                      TextButton(onPressed: _fetch, child: const Text('Retry')),
                )
              : _quotes.isEmpty
                  ? const EmptyState(
                      title: 'There are no Quotes.',
                      body: 'You can add Quotes by clicking the button below',
                      icon: Icons.request_quote)
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _quotes.length,
                        separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 72,
                            color: Theme.of(context).dividerColor),
                        itemBuilder: (context, i) {
                          final q = _quotes[i];
                          final stage =
                              q.fields['Quote Stage']?.isNotEmpty == true
                                  ? q.fields['Quote Stage']!
                                  : (q.status ?? 'New');
                          return ListTile(
                            leading: RecordAvatar(q.name),
                            title: Text(q.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            subtitle: Text('Quote Stage · $stage',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            trailing:
                                StatusChip(stage, color: statusColor(stage)),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => _QuoteDetail(quote: q))),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _QuoteDetail extends StatelessWidget {
  final CrmRecord quote;
  const _QuoteDetail({required this.quote});

  @override
  Widget build(BuildContext context) {
    final record = quote;
    final tabs = [
      RecordTab('One View', (records) => _QuoteOneView(record: record)),
      RecordTab('Preview', (records) => _QuotePreview(record: record)),
      RecordTab(
          'Activity',
          (records) => const Center(
              child: Text('No activities found',
                  style: TextStyle(color: AppColors.textSecondary)))),
      RecordTab(
          'Details',
          (records) => ListView(children: [
                const SizedBox(height: 12),
                KeyFieldsSection(record.fields)
              ])),
    ];
    return RecordDetailScreen(
        record: record, tabs: tabs, showProfileRating: false);
  }
}

class _QuoteOneView extends StatelessWidget {
  final CrmRecord record;
  const _QuoteOneView({required this.record});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text('Description',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
              record.fields['Description'] ??
                  record.fields['description'] ??
                  'Add Description',
              style: TextStyle(
                  fontSize: 14,
                  color: (record.fields['Description']?.isNotEmpty ?? false) ||
                          (record.fields['description']?.isNotEmpty ?? false)
                      ? AppColors.textPrimary
                      : AppColors.textHint)),
        ),
        const SizedBox(height: 16),
        KeyFieldsSection(record.fields),
      ],
    );
  }
}

/// Printable quote preview built from the quote record's own fields.
class _QuotePreview extends StatelessWidget {
  final CrmRecord record;
  const _QuotePreview({required this.record});

  String _f(String label) =>
      record.fields[label] ?? record.fields[label.toLowerCase()] ?? '';

  @override
  Widget build(BuildContext context) {
    final quoteNo = _f('Quote No.') != '' ? _f('Quote No.') : record.id;
    final quoteDate = _f('Quote Date');
    final validUntil = _f('Valid Until');
    final city =
        _f('Billing City') != '' ? _f('Billing City') : _f('Mailing City');
    final account =
        _f('Account Name') != '' ? _f('Account Name') : _f('Contact Name');
    final title = record.name;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BizForce CRM',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark)),
              Text('QUOTE',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.isNotEmpty ? '$account,' : '—',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary)),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ]),
              ),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Quote No. $quoteNo',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textPrimary)),
                      if (quoteDate.isNotEmpty)
                        Text('Quote Date $quoteDate',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textPrimary)),
                      if (validUntil.isNotEmpty)
                        Text('Valid Until $validUntil',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textPrimary)),
                    ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Billing Address',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text(city.isNotEmpty ? '$city,' : '—',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6)),
            child: const Row(
              children: [
                Expanded(
                    child: Text('Item Name',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700))),
                SizedBox(
                    width: 30,
                    child: Text('Qty',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700))),
                SizedBox(
                    width: 50,
                    child: Text('List Price',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700))),
                SizedBox(
                    width: 50,
                    child: Text('Total',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const Divider(height: 8),
          const Row(
            children: [
              Expanded(
                  child: Text('No line items on this quote',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary))),
            ],
          ),
          const Divider(height: 12),
          const SizedBox(height: 16),
          const Text('Thank you for your business!',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
