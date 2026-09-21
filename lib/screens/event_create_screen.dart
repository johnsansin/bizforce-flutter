import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/form_widgets.dart';

/// Create Event form: Name, Assigned To, Start/End, Status, Activity Type,
/// Agenda and Participants — matching the reference layout.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _agenda = TextEditingController();
  String _assignedTo = '';
  String _status = 'Planned';
  String _activityType = 'Call';
  late DateTime _start = DateTime.now();
  late DateTime _end = DateTime.now().add(const Duration(minutes: 30));

  @override
  void dispose() {
    _name.dispose();
    _agenda.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assignedTo.isEmpty) {
      _assignedTo = context.read<AppState>().displayName;
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an event name')));
      return;
    }
    final api = context.read<AppState>().api;
    final assignedId = context.read<AppState>().profile['id'];
    try {
      await api.createRecord('Events', {
        'subject': _name.text.trim(),
        'status': _status,
        if (assignedId != null && assignedId.isNotEmpty)
          'assignedTo': assignedId,
        'activityType': _activityType,
        'priority': 'Medium',
        'description': _agenda.text.trim(),
        'startAt': _start.toUtc().toIso8601String(),
        'endAt': _end.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to reach the server.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Create Event'),
        actions: [SaveButton(onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LabeledField(
            label: 'Name',
            required: true,
            child: AppTextField(hint: 'Enter Name', controller: _name),
          ),
          LabeledField(
            label: 'Assigned To',
            required: true,
            child: SelectSheetField(
              hint: 'Select Assigned To',
              value: _assignedTo,
              sheetTitle: 'Select Assigned To',
              options: [_assignedTo],
              onSelected: (v) => setState(() => _assignedTo = v ?? ''),
            ),
          ),
          LabeledField(
            label: 'Start Date & Time',
            required: true,
            child: DateTimeField(
              value: _start,
              onChanged: (v) => setState(() => _start = v),
            ),
          ),
          LabeledField(
            label: 'End Date & Time',
            required: true,
            child: DateTimeField(
              value: _end,
              onChanged: (v) => setState(() {
                _end = v;
                if (_end.isBefore(_start)) _start = _end;
              }),
            ),
          ),
          LabeledField(
            label: 'Status',
            required: true,
            child: SelectSheetField(
              hint: 'Select Status',
              value: _status,
              sheetTitle: 'Select Status',
              options: kEventStatuses,
              onSelected: (v) => setState(() => _status = v ?? ''),
            ),
          ),
          LabeledField(
            label: 'Activity Type',
            required: true,
            child: SelectSheetField(
              hint: 'Select Activity Type',
              value: _activityType,
              sheetTitle: 'Select Activity Type',
              options: kActivityTypes,
              onSelected: (v) => setState(() => _activityType = v ?? 'Call'),
            ),
          ),
          LabeledField(
            label: 'Agenda',
            child: AppTextField(hint: 'Type here agenda', controller: _agenda),
          ),
        ],
      ),
    );
  }
}
