import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'record_edit_screen.dart';

/// Tasks landing screen rebuilt to match the reference prototype: a
/// Mine / Shared segmented control, a dropdown sub-filter chip, and task
/// rows with a tick (tap to complete) and a trailing kind icon.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<CrmRecord> _tasks = [];
  bool _loading = true;
  String? _error;

  String _cat = 'mine';
  int _sub = 0;
  final Set<String> _doneLocal = {};

  static const List<(String, String)> _mineFilters = [
    ('this week', 'My tasks due this week'),
    ('next week', 'My tasks due next week'),
    ('this month', 'My tasks due this month'),
    ('completed', 'My completed tasks'),
    ('pending', 'My pending tasks'),
  ];

  List<CrmRecord> get _filtered {
    if (_cat == 'shared') return _tasks;
    final key = _mineFilters[_sub].$1;
    if (key == 'completed') {
      return _tasks.where((t) => _isDone(t.id, t)).toList();
    }
    if (key == 'pending') {
      return _tasks.where((t) => !_isDone(t.id, t)).toList();
    }
    return _tasks;
  }

  bool _isDone(String id, CrmRecord task) {
    if (_doneLocal.contains(id)) return true;
    final status = (task.status ?? task.field('Status')).toLowerCase();
    return status.contains('complete') ||
        status.contains('held') ||
        status.contains('closed');
  }

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
      final records = await api.records('Tasks');
      if (!mounted) return;
      setState(() {
        _tasks = records;
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
        _error = 'Unable to load tasks.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final subLabel = _mineFilters[_sub].$2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedControl<String>(
                options: const [('Mine', 'mine'), ('Shared', 'shared')],
                selected: _cat,
                onChanged: (v) => setState(() => _cat = v),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _cat == 'mine'
                  ? DropdownChip(subLabel, onTap: _showListPicker)
                  : DropdownChip('All Tasks', onTap: _showListPicker, enabled: false),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? EmptyState(
                        title: 'Could not load tasks',
                        body: _error!,
                        icon: Icons.cloud_off_outlined,
                        action: TextButton(
                            onPressed: _fetch, child: const Text('Retry')),
                      )
                    : list.isEmpty
                        ? EmptyState(
                            title: _cat == 'mine'
                                ? 'Nothing in this list'
                                : 'No tasks found',
                            body: 'Add a task to get started.',
                            icon: Icons.checklist_rtl,
                            action: FilledButton.icon(
                              onPressed: _loading ? null : _createTask,
                              icon: const Icon(Icons.add),
                              label: const Text('Add a task'),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 90),
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final task = list[i];
                                return _TaskRow(
                                  task: task,
                                  done: _isDone(task.id, task),
                                  onOpen: () => _openTask(task),
                                  onToggle: () => setState(() {
                                    if (_doneLocal.contains(task.id)) {
                                      _doneLocal.remove(task.id);
                                    } else {
                                      _doneLocal.add(task.id);
                                    }
                                  }),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _createTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showListPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Text('My tasks',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (int i = 0; i < _mineFilters.length; i++)
              ListTile(
                leading: Icon(
                    _sub == i
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _sub == i
                        ? AppColors.primary
                        : AppColors.textSecondary),
                title: Text(_mineFilters[i].$2,
                    style: TextStyle(
                        fontWeight: _sub == i ? FontWeight.w700 : null)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _sub = i);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTask(CrmRecord task) async {
    CrmRecord fullTask = task;
    try {
      fullTask = await context.read<AppState>().api.record('Tasks', task.id);
    } catch (_) {
      // Fall back to list data if the calendar detail call is unavailable.
    }
    if (!mounted) return;
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: fullTask)),
    ).then((changed) {
      if (changed == true) _fetch();
    });
  }

  Future<void> _createTask() async {
    final appState = context.read<AppState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _AddTaskDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      final assignedId = appState.profile['id'];
      final body = {
        'subject': name.trim(),
        'activityType': 'Task',
        'status': 'Planned',
        'priority': 'Medium',
        'dueAt': DateTime.now()
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        if (assignedId != null && assignedId.isNotEmpty)
          'assignedTo': assignedId,
      };
      await appState.api.createRecord('Tasks', body);
      if (!mounted) return;
      await _fetch();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Create failed: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to reach the server.')));
    }
  }
}

class _TaskRow extends StatelessWidget {
  final CrmRecord task;
  final bool done;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  const _TaskRow({
    required this.task,
    required this.done,
    required this.onOpen,
    required this.onToggle,
  });

  IconData _kindIcon() {
    final t = (task.field('Activity Type') + ' ' + (task.status ?? '')).toLowerCase();
    if (t.contains('call')) return Icons.call_outlined;
    if (t.contains('meet') ||
        t.contains('event') ||
        t.contains('onsite'))
      return Icons.event_outlined;
    if (t.contains('mail') || t.contains('email'))
      return Icons.mail_outline;
    if (t.contains('task') || t.contains('note') || t.contains('zoom'))
      return Icons.description_outlined;
    return Icons.checklist_rtl;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = task.subtitle;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: done ? AppColors.held : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: done ? AppColors.held : Theme.of(context).dividerColor,
                      width: 2.2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.name,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          color:
                              done ? AppColors.textHint : null)),
                  const SizedBox(height: 2),
                  Text(
                      [
                        if (subtitle != null && subtitle.isNotEmpty) subtitle,
                        if (task.field('Activity Type').isNotEmpty)
                          task.field('Activity Type'),
                        if (!done) task.status ?? ''
                      ].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(_kindIcon(),
                  size: 19, color: done ? AppColors.textHint : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avoids importing formatters wholesale; local date helpers.
class FormattersDate {
  static String date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();
  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final TextEditingController _name = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Task'),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Task name'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isNotEmpty) Navigator.pop(context, name);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Task detail with One View / Subtasks / Activity / Details tabs, timelog
/// controls (Pause/Resume/Stop) and the closed re-open banner.
class TaskDetailScreen extends StatefulWidget {
  final CrmRecord task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  int _tab = 0;
  bool _showReopen = false;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RecordEditScreen(record: widget.task)),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1),
          (_) => setState(() => _elapsed += const Duration(seconds: 1)));
    }
    setState(() => _running = !_running);
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _showReopen = true;
    });
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _edit),
        ],
      ),
      body: Column(
        children: [
          if (_showReopen)
            Container(
              color: AppColors.held,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('CLOSED · Would you like to re-open?',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showReopen = false),
                    child: const Text('Re-open',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const RecordAvatar('TS', size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusChip(task.status ?? 'Not Started',
                              color: statusColor(task.status)),
                          const SizedBox(width: 8),
                          const StatusChip('Checklist Item',
                              color: AppColors.textSecondary, dot: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                for (final t in const [
                  'One View',
                  'Subtasks',
                  'Activity',
                  'Details'
                ])
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = const [
                            'One View',
                            'Subtasks',
                            'Activity',
                            'Details'
                          ].indexOf(t)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                width: 2.5,
                                color: _tab ==
                                        const [
                                          'One View',
                                          'Subtasks',
                                          'Activity',
                                          'Details'
                                        ].indexOf(t)
                                    ? AppColors.primary
                                    : Colors.transparent),
                          ),
                        ),
                        child: Text(t,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _tab ==
                                        const [
                                          'One View',
                                          'Subtasks',
                                          'Activity',
                                          'Details'
                                        ].indexOf(t)
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
                _oneView(task),
                const _Placeholder(text: 'No records found'),
                const _Placeholder(text: 'No activities found'),
                ListView(
                  children: [
                    const SizedBox(height: 12),
                    KeyFieldsSection(task.fields),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _oneView(CrmRecord task) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text('Metrics',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        ContentCard(
          child: Text('Running Status · ${task.field('Running Status')}',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Timelog',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        ContentCard(
          child: Column(
            children: [
              Text(
                  task.field('Time Spent').isNotEmpty
                      ? task.field('Time Spent')
                      : _fmt(_elapsed),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()])),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _toggleTimer,
                      child: Text(_running ? 'Pause' : 'Resume'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _stopTimer,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      child: const Text('Stop'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KeyFieldsSection(task.fields),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String text;
  const _Placeholder({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Text(text,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ),
    );
  }
}