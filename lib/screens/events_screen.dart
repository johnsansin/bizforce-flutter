import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'event_create_screen.dart';

/// "My Events": a month calendar grid with the day's agenda below and a FAB
/// to create a new event/meeting. Events come from the Events module API.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime _shown = DateTime.now();
  DateTime? _selectedDay;
  List<AgendaItem> _agenda = [];
  bool _loading = true;
  String? _error;

  DateTime get _baseDay {
    final base = _selectedDay ?? _shown;
    return base;
  }

  List<AgendaItem> get _dayAgenda => _agenda.where((a) {
        final d = _baseDay;
        return a.start.year == d.year &&
            a.start.month == d.month &&
            a.start.day == d.day;
      }).toList();

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
      final from = DateTime(_shown.year, _shown.month, 1);
      final to = DateTime(_shown.year, _shown.month + 1, 1);
      final records = await api.records('Events', from: from, to: to);
      if (!mounted) return;
      setState(() {
        _agenda = eventItemsFrom(records);
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
        _error = 'Unable to load events.';
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    setState(() => _shown = DateTime(_shown.year, _shown.month - 1, 1));
    _fetch();
  }

  void _nextMonth() {
    setState(() => _shown = DateTime(_shown.year, _shown.month + 1, 1));
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  title: 'Could not load events',
                  body: _error!,
                  icon: Icons.cloud_off,
                  action:
                      TextButton(onPressed: _fetch, child: const Text('Retry')),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 90),
                    children: [
                      _monthHeader(context),
                      _weekDayRow(context),
                      _calendarGrid(context),
                      _agendaHeader(context),
                      if (_dayAgenda.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                              child: Text('No events for the day',
                                  style: TextStyle(
                                      color: AppColors.textSecondary))),
                        )
                      else
                        for (final item in _dayAgenda) _agendaTile(item),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading
            ? null
            : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateEventScreen())).then((v) {
                  if (v == true) _fetch();
                }),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _monthHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Text(
              '${const [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec'
              ][_shown.month - 1]} ${_shown.year}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          _monthNav(Icons.chevron_left, _prevMonth),
          const SizedBox(width: 6),
          _monthNav(Icons.chevron_right, _nextMonth),
        ],
      ),
    );
  }

  Widget _monthNav(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _weekDayRow(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          for (final l in labels)
            Expanded(
                child: Center(
                    child: Text(l,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)))),
        ],
      ),
    );
  }

  Widget _calendarGrid(BuildContext context) {
    final first = DateTime(_shown.year, _shown.month, 1);
    final startOffset = first.weekday - 1; // Monday start
    final daysInMonth = DateTime(_shown.year, _shown.month + 1, 0).day;
    final today = _shown; // treat as "today" for display
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.82,
        ),
        itemCount: startOffset + daysInMonth,
        itemBuilder: (context, i) {
          if (i < startOffset) return const SizedBox.shrink();
          final day = i - startOffset + 1;
          final date = DateTime(_shown.year, _shown.month, day);
          final hasEvent = _agenda.any((a) =>
              a.start.year == date.year &&
              a.start.month == date.month &&
              a.start.day == date.day);
          final selected = _selectedDay != null && _selectedDay!.day == day;
          final isToday = today.day == day;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _selectedDay = date),
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : (isToday
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: isToday && !selected
                    ? Border.all(color: AppColors.primary, width: 1.4)
                    : null,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday || selected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : (hasEvent
                              ? AppColors.primary
                              : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : (hasEvent ? AppColors.primary : Colors.transparent),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _agendaHeader(BuildContext context) {
    final d = _baseDay;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text('${d.day} ${months[d.month - 1]} ${d.year}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
    );
  }

  Widget _agendaTile(AgendaItem item) {
    return ContentCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(_hh(item.start),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text(item.start.hour >= 12 ? 'PM' : 'AM',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
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
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(item.priority, color: AppColors.hot),
          const SizedBox(width: 6),
          StatusChip(item.status, color: statusColor(item.status)),
        ],
      ),
    );
  }

  String _hh(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
