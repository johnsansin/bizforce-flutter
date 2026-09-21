import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/form_widgets.dart';

class ActivityFormScreen extends StatefulWidget {
  final CrmRecord parent;
  final CrmRecord? activity;
  const ActivityFormScreen({super.key, required this.parent, this.activity});
  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  late final TextEditingController _subject;
  late final TextEditingController _description;
  late final TextEditingController _location;
  String _type = 'Task';
  String _status = 'Planned';
  String _priority = 'Medium';
  String _assignedTo = '';
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 1));
  List<Map<String, dynamic>> _users = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _subject = TextEditingController(text: a?.field('subject') ?? '');
    _description = TextEditingController(text: a?.field('description') ?? '');
    _location = TextEditingController(text: a?.field('location') ?? '');
    _type = a?.field('activityType').isNotEmpty == true ? a!.field('activityType') : 'Task';
    _status = a?.field('status').isNotEmpty == true ? a!.field('status') : 'Planned';
    _priority = a?.field('priority').isNotEmpty == true ? a!.field('priority') : 'Medium';
    _assignedTo = a?.field('assignedTo') ?? '';
    _start = parseCrmDateTime(a?.field('startAt') ?? '') ?? DateTime.now();
    _end = parseCrmDateTime(a?.field('endAt') ?? '') ?? _start.add(const Duration(hours: 1));
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await context.read<AppState>().api.activeUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        if (_assignedTo.isEmpty && users.isNotEmpty) _assignedTo = '${users.first['id']}';
      });
    } catch (_) {}
  }

  String _userName(Map<String, dynamic> user) {
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    return name.isNotEmpty ? name : '${user['name'] ?? user['email'] ?? user['id']}';
  }

  Future<void> _save() async {
    if (_subject.text.trim().isEmpty || _assignedTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and Assigned To are required')),
      );
      return;
    }
    setState(() => _saving = true);
    final body = {
      'subject': _subject.text.trim(),
      'activityType': _type,
      'status': _status,
      'priority': _priority,
      'assignedTo': _assignedTo,
      'description': _description.text.trim(),
      'location': _location.text.trim(),
      'startAt': _start.toUtc().toIso8601String(),
      'endAt': _end.toUtc().toIso8601String(),
      if (_type == 'Task') 'dueAt': _end.toUtc().toIso8601String(),
    };
    try {
      final api = context.read<AppState>().api;
      if (widget.activity == null) {
        await api.createRecordActivity(widget.parent.module, widget.parent.id, body);
      } else {
        await api.updateRecord('Activities', widget.activity!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.activity == null ? 'Add Activity' : 'Edit Activity'),
      actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('Save'))]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      LabeledField(label: 'Subject', required: true,
        child: AppTextField(controller: _subject, hint: 'Activity subject')),
      LabeledField(label: 'Activity Type', required: true,
        child: SelectSheetField(value: _type, hint: 'Select type', sheetTitle: 'Activity Type',
          options: const ['Task', 'Call', 'Meeting', 'Email', 'Follow Up'],
          onSelected: (v) => setState(() => _type = v ?? _type))),
      LabeledField(label: 'Assigned To', required: true,
        child: DropdownButtonFormField<String>(value: _assignedTo.isEmpty ? null : _assignedTo,
          isExpanded: true, decoration: const InputDecoration(hintText: 'Select user'),
          items: _users.map((u) => DropdownMenuItem(value: '${u['id']}', child: Text(_userName(u)))).toList(),
          onChanged: (v) => setState(() => _assignedTo = v ?? ''))),
      LabeledField(label: 'Status', child: SelectSheetField(value: _status, hint: 'Status', sheetTitle: 'Status',
        options: const ['Planned', 'In Progress', 'Held', 'Completed', 'Cancelled'],
        onSelected: (v) => setState(() => _status = v ?? _status))),
      LabeledField(label: 'Priority', child: SelectSheetField(value: _priority, hint: 'Priority', sheetTitle: 'Priority',
        options: const ['Low', 'Medium', 'High', 'Urgent'],
        onSelected: (v) => setState(() => _priority = v ?? _priority))),
      LabeledField(label: 'Start Date & Time', required: true,
        child: DateTimeField(value: _start, onChanged: (v) => setState(() => _start = v))),
      LabeledField(label: 'End / Due Date & Time', required: true,
        child: DateTimeField(value: _end, onChanged: (v) => setState(() => _end = v))),
      LabeledField(label: 'Location', child: AppTextField(controller: _location, hint: 'Location')),
      LabeledField(label: 'Description', child: TextField(controller: _description, maxLines: 4,
        decoration: const InputDecoration(hintText: 'Description'))),
      if (_saving) const Center(child: CircularProgressIndicator()),
    ]),
  );
}
