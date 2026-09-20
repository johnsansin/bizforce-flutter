import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/api_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/form_widgets.dart';

enum FieldType { text, select, date, yesno, phone, email, multiline }

class CreateField {
  final String label;
  final String section;
  final FieldType type;
  final List<String>? options;
  final bool required;
  final String? initial;
  const CreateField(this.label, this.section,
      {this.type = FieldType.text,
      this.options,
      this.required = false,
      this.initial});
}

/// Data-driven create screen with section tabs (e.g. Lead Details / Address
/// Details / Description Details / Profile Picture) and labeled fields.
///
/// `onSave` is invoked with the collected values. When a backend is
/// configured the new record is posted to the module endpoint.
class CreateRecordScreen extends StatefulWidget {
  final String module;
  final List<CreateField> fields;
  final String? Function(Map<String, String> values)? validator;
  final Future<void> Function(Map<String, String> values)? onSave;
  const CreateRecordScreen({
    super.key,
    required this.module,
    this.fields = const [],
    this.validator,
    this.onSave,
  });

  @override
  State<CreateRecordScreen> createState() => _CreateRecordScreenState();
}

class _CreateRecordScreenState extends State<CreateRecordScreen> {
  late PageController _controller;
  late Map<String, TextEditingController> _text;
  late Map<String, String> _select;
  late Map<String, DateTime> _dates;
  int _tab = 0;
  bool _saving = false;

  List<String> get _sections =>
      widget.fields.map((f) => f.section).toSet().toList();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _text = {};
    _select = {};
    _dates = {};
    for (final f in widget.fields) {
      _text[f.label] = TextEditingController(text: f.initial ?? '');
      if (f.options != null && f.options!.isNotEmpty && f.initial != null)
        _select[f.label] = f.initial!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _collect() => {
        for (final f in widget.fields)
          f.label: (f.type == FieldType.select || f.type == FieldType.yesno)
              ? (_select[f.label] ?? '')
              : _text[f.label]!.text.trim(),
      };

  Future<void> _save() async {
    final values = _collect();
    final error = widget.validator?.call(values);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);
    if (widget.onSave != null) {
      await widget.onSave!(values);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
      return;
    }
    final api = context.read<AppState>().api;
    try {
      await api.createRecord(widget.module, {
        for (final e in values.entries) e.key: e.value,
      });
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
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
  Widget build(BuildContext context) {
    final sections = _sections;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
        title:
            Text('Create ${widget.module.replaceFirst(RegExp(r'e?s$'), '')}'),
        actions: [SaveButton(onPressed: _saving ? () {} : _save)],
      ),
      body: Column(
        children: [
          if (sections.length > 1) _sectionStrip(sections),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _tab = i),
              children: [
                for (final s in sections) _sectionBody(s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionStrip(List<String> sections) {
    return Container(
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (int i = 0; i < sections.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(sections[i]),
                  selected: _tab == i,
                  onSelected: (_) {
                    setState(() => _tab = i);
                    _controller.animateToPage(i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: _tab == i ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                      color: _tab == i ? AppColors.primary : AppColors.divider),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionBody(String section) {
    final fields = widget.fields.where((f) => f.section == section).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final f in fields) _buildField(f),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildField(CreateField f) {
    switch (f.type) {
      case FieldType.select:
        return LabeledField(
          label: f.label,
          required: f.required,
          child: SelectSheetField(
            hint: 'Select an Option',
            value: _select[f.label],
            sheetTitle: 'Select ${f.label}',
            options: f.options ?? const [],
            onSelected: (v) => setState(() => _select[f.label] = v ?? ''),
          ),
        );
      case FieldType.yesno:
        return LabeledField(
          label: f.label,
          required: f.required,
          child: YesNoField(
              value: _select[f.label] ?? 'Yes',
              onChanged: (v) => setState(() => _select[f.label] = v)),
        );
      case FieldType.date:
        return LabeledField(
          label: f.label,
          required: f.required,
          child: DateTimeField(
            value: _dates[f.label] ?? DateTime.now(),
            onChanged: (v) => setState(() => _dates[f.label] = v),
            showTime: false,
          ),
        );
      case FieldType.phone:
        return LabeledField(
          label: f.label,
          required: f.required,
          child: AppTextField(
              hint: 'Enter ${f.label}',
              controller: _text[f.label],
              keyboardType: TextInputType.phone),
        );
      case FieldType.email:
        return LabeledField(
          label: f.label,
          required: f.required,
          child: AppTextField(
              hint: 'Enter ${f.label}',
              controller: _text[f.label],
              keyboardType: TextInputType.emailAddress),
        );
      case FieldType.multiline:
        return LabeledField(
          label: f.label,
          required: f.required,
          child: TextField(
            controller: _text[f.label],
            maxLines: 3,
            decoration: InputDecoration(hintText: 'Enter ${f.label}'),
          ),
        );
      case FieldType.text:
        return LabeledField(
          label: f.label,
          required: f.required,
          child: AppTextField(
              hint: 'Enter ${f.label}', controller: _text[f.label]),
        );
    }
  }
}
