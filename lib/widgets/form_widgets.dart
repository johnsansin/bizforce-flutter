import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// A field with a label printed above it and the input below
/// (matches the create/form layouts).
class LabeledField<T> extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;
  const LabeledField(
      {super.key,
      required this.label,
      required this.child,
      this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (required)
                    const TextSpan(
                        text: ' *',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700)),
                ],
              ),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Field that opens a bottom-sheet selector with a search box, used for
/// "Select an option", "Select Assigned To", "Select Status", etc.
class SelectSheetField extends StatelessWidget {
  final String hint;
  final String? value;
  final String sheetTitle;
  final List<String> options;
  final ValueChanged<String?> onSelected;
  const SelectSheetField({
    super.key,
    required this.hint,
    this.value,
    required this.sheetTitle,
    required this.options,
    required this.onSelected,
  });

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final filtered = ValueNotifier<List<String>>(options);
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(sheetTitle,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: const InputDecoration(
                      hintText: 'Type to search',
                      prefixIcon: Icon(Icons.search, size: 20)),
                  onChanged: (q) {
                    final key = q.trim().toLowerCase();
                    filtered.value = key.isEmpty
                        ? options
                        : options
                            .where((o) => o.toLowerCase().contains(key))
                            .toList();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select an Option',
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: filtered,
                  builder: (context, list, _) => ListView(
                    children: [
                      for (final o in list)
                        ListTile(
                          dense: true,
                          title: Text(o),
                          selected: o == value,
                          onTap: () {
                            onSelected(o);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(value == null ? Icons.keyboard_arrow_down : Icons.close,
                size: 20, color: AppColors.textHint),
          ),
        ),
        child: value == null
            ? Text(hint,
                style: const TextStyle(color: AppColors.textHint, fontSize: 15))
            : Text(value!,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }
}

/// Yes/No segmented toggle.
class YesNoField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const YesNoField({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'Yes', label: Text('Yes')),
        ButtonSegment(value: 'No', label: Text('No')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Date+time picker field that opens Material pickers.
class DateTimeField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool showTime;
  const DateTimeField(
      {super.key,
      required this.value,
      required this.onChanged,
      this.showTime = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: const InputDecoration(
            suffixIcon: Icon(Icons.event, size: 20, color: AppColors.textHint)),
        child: Text(
          '${value.toLocal()}',
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    var next =
        DateTime(date.year, date.month, date.day, value.hour, value.minute);
    if (showTime) {
      final time = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(value));
      if (time != null)
        next =
            DateTime(next.year, next.month, next.day, time.hour, time.minute);
    }
    onChanged(next);
  }
}
