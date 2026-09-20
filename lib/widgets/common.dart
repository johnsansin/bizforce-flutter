import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';

/// Initials avatar used across list and detail screens.
class RecordAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const RecordAvatar(this.name, {super.key, this.size = 44, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppColors.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        Formatters.initials(name),
        style: TextStyle(
          color: color ?? AppColors.primary,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Standard empty state block, e.g. "There are no Leads."
class EmptyState extends StatelessWidget {
  final String title;
  final String? body;
  final IconData icon;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Rounded search input used on every list screen.
class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
        isDense: true,
        suffixIcon: controller != null
            ? ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!,
                builder: (context, v, _) => v.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          controller!.clear();
                          onChanged('');
                        },
                      ),
              )
            : null,
      ),
    );
  }
}

/// Small colored tag for a status like Cold/Warm/Hot/New.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;
  const StatusChip(this.label,
      {super.key, required this.color, this.dot = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Colored status helper mapping a record's status string to a color.
Color statusColor(String? status) {
  switch (status) {
    case 'Cold':
      return AppColors.cold;
    case 'Warm':
      return AppColors.warm;
    case 'Hot':
      return AppColors.hot;
    case 'Inactive':
      return AppColors.inactive;
    case 'New':
    case 'Open':
    case 'Planned':
    case 'Pending':
    case 'In Progress':
      return AppColors.planned;
    case 'Closed Won':
    case 'Paid':
    case 'Closed':
    case 'Completed':
    case 'Held':
    case 'Active':
      return AppColors.held;
    case 'Canceled':
    case 'Not Held':
    case 'Skipped':
    case 'Rejected':
      return AppColors.notHeld;
    default:
      return AppColors.textSecondary;
  }
}

/// Card wrapping a list of key-value fields ("Key Fields" section).
class KeyFieldsSection extends StatelessWidget {
  final Map<String, String> fields;
  final String title;
  const KeyFieldsSection(this.fields, {super.key, this.title = 'Key Fields'});

  @override
  Widget build(BuildContext context) {
    final entries = fields.entries.where((e) => e.value.isNotEmpty).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Theme.of(context).dividerColor),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 140,
                          child: Text(entries[i].key,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 14))),
                      Expanded(
                          child: Text(entries[i].value,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-width container card with padding, for dashboards and detail pages.
class ContentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const ContentCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

/// "Save"-style top-right text action in form screens.
class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const SaveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      child: const Text('Save',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}
