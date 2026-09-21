import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';

class RecordEditScreen extends StatefulWidget {
  final CrmRecord record;
  const RecordEditScreen({super.key, required this.record});
  @override
  State<RecordEditScreen> createState() => _RecordEditScreenState();
}

class _RecordEditScreenState extends State<RecordEditScreen> {
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;
  static const _hidden = {
    'id',
    'companyId',
    'createdAt',
    'updatedAt',
    'createdBy',
    'customFields',
    'convertedAt',
    'convertedAccountId',
    'convertedContactId',
    'convertedPotentialId',
    'isConverted'
  };

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final entry in widget.record.fields.entries)
        if (!_hidden.contains(entry.key))
          entry.key: TextEditingController(text: entry.value),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _label(String key) => key
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AppState>().api.updateRecord(
          widget.record.module,
          widget.record.id,
          {for (final e in _controllers.entries) e.key: e.value.text.trim()});
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to reach the server.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Edit ${widget.record.module}'), actions: [
          TextButton(
              onPressed: _saving ? null : _save, child: const Text('Save')),
        ]),
        body: _controllers.isEmpty
            ? const Center(
                child: Text('No editable fields returned by the server.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final entry in _controllers.entries) ...[
                    TextField(
                      controller: entry.value,
                      minLines: entry.key.toLowerCase().contains('description')
                          ? 3
                          : 1,
                      maxLines: entry.key.toLowerCase().contains('description')
                          ? 6
                          : 1,
                      decoration: InputDecoration(labelText: _label(entry.key)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_saving) const Center(child: CircularProgressIndicator()),
                ],
              ),
      );
}
