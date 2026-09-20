import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Tasks landing screen: a segmented list picker ("My tasks due this week")
/// plus the task rows with running-status chips, matching the reference.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<CrmRecord> _tasks = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  List<CrmRecord> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _tasks;
    return _tasks.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Column(
        children: [
          _listPickerRow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                  hintText: 'Search Tasks',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? EmptyState(
                        title: 'Could not load tasks',
                        body: _error!,
                        icon: Icons.cloud_off,
                        action: TextButton(
                            onPressed: _fetch, child: const Text('Retry')),
                      )
                    : _filtered.isEmpty
                        ? const EmptyState(
                            title: 'No tasks found',
                            body: 'Tap + to create a new task',
                            icon: Icons.checklist_rtl)
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final task = _filtered[i];
                                return InkWell(
                                  onTap: () => _openTask(task),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            color: task.status == 'In Progress'
                                                ? AppColors.planned
                                                : AppColors.textHint),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(task.name,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(
                                                  'Task Type · ${task.field('Task Type')}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors
                                                          .textSecondary)),
                                            ],
                                          ),
                                        ),
                                        StatusChip(task.status ?? '',
                                            color: statusColor(task.status)),
                                      ],
                                    ),
                                  ),
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

  Widget _listPickerRow() {
    return InkWell(
      onTap: _showListPicker,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.assignment_outlined,
                size: 18, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Expanded(
                child: Text('My tasks due this week',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Icon(Icons.keyboard_arrow_down,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  void _showListPicker() {
    const lists = [
      'My tasks due this week',
      'My tasks due next week',
      'My tasks due this month',
      'My completed tasks',
      'My pending tasks'
    ];
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final l in lists)
            ListTile(
                leading: const Icon(Icons.check_box_outline_blank),
                title: Text(l),
                onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _openTask(CrmRecord task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
  }

  Future<void> _createTask() async {
    final appState = context.read<AppState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _AddTaskDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      final now = DateTime.now();
      final body = {
        'Subject': name.trim(),
        'taskType': 'Checklist Item',
        'status': 'Not Started',
        'dueDate': '${FormattersDate.date(now)} ${FormattersDate.time(now)}',
        'assignedTo':
            appState.displayName.isEmpty ? 'Users' : appState.displayName,
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
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
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
                          StatusChip(task.status!,
                              color: statusColor(task.status)),
                          const SizedBox(width: 8),
                          const StatusChip('Checklist Item',
                              color: AppColors.textSecondary, dot: false),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
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
