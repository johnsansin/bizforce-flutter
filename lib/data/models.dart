import 'package:flutter/material.dart';

/// Core domain models used across the app.

/// Builds a [CrmRecord] from an API record map.
///
/// Handles the label/field conventions shared by CRM REST APIs:
/// `label` (or firstname/lastname/name), `id`, `module`, and flat field
/// values. All remaining scalar values are kept as display fields so a
/// detail screen always renders something meaningful.
CrmRecord crmRecordFromJson(String module, Map<dynamic, dynamic> m) {
  final id = '${m['id'] ?? ''}';
  final first = '${m['firstname'] ?? ''}';
  final last = '${m['lastname'] ?? ''}';
  final full = [first, last].where((s) => s.isNotEmpty).join(' ');
  final explicitName = m['label'] ?? m['title'] ?? m['subject'] ?? m['name'];
  final name =
      ('${explicitName ?? ''}'.isEmpty ? full : '$explicitName').trim();
  final fields = <String, String>{};
  m.forEach((k, v) {
    final key = '$k';
    if (v == null || v is Map || v is List) return;
    final value = '$v';
    if (value.isEmpty || value == 'null') return;
    fields[key] = value;
  });
  final moduleName = '${m['module'] ?? module}';
  return CrmRecord(
    id: id.isEmpty ? name.hashCode.toString() : id,
    name: name.isEmpty ? '(Unnamed $moduleName)' : name,
    module: moduleName,
    subtitle:
        fields['organizationname'] ?? fields['accountname'] ?? fields['email'],
    fields: fields,
    status: fields['leadstatus'] ?? fields['status'] ?? fields['ticketstatus'],
  );
}

class CrmRecord {
  final String id;
  final String name;
  final String module;
  final String? subtitle;
  final Map<String, String> fields;
  final List<String> tags;
  final String? status;
  final double rating;
  final DateTime? created;
  final DateTime? modified;

  const CrmRecord({
    required this.id,
    required this.name,
    required this.module,
    this.subtitle,
    this.fields = const {},
    this.tags = const [],
    this.status,
    this.rating = 0,
    this.created,
    this.modified,
  });

  /// Lookup a display value for a field label, e.g. `fields['Mobile Phone']`.
  String field(String label) => fields[label] ?? '';

  bool get hasValue => name.isNotEmpty;

  CrmRecord copyWith({String? status, Map<String, String>? fields}) =>
      CrmRecord(
        id: id,
        name: name,
        module: module,
        subtitle: subtitle,
        fields: fields ?? this.fields,
        tags: tags,
        status: status ?? this.status,
        rating: rating,
        created: created,
        modified: modified,
      );
}

class MenuItem {
  final String label;
  final IconData icon;
  final String module;
  final String? colorHex;

  const MenuItem(this.label, this.icon, this.module, {this.colorHex});
}

class MenuSection {
  final String title;
  final List<MenuItem> items;
  const MenuSection(this.title, this.items);
}

class AgendaItem {
  final DateTime start;
  final DateTime end;
  final String title;
  final String type;
  final String priority;
  final String status;

  const AgendaItem({
    required this.start,
    required this.end,
    required this.title,
    this.type = 'Call',
    this.priority = 'High',
    this.status = 'Planned',
  });
}

class QuickAction {
  final String label;
  final IconData icon;
  const QuickAction(this.label, this.icon);
}

class PipelineStage {
  final String name;
  final int deals;
  final double amount;
  const PipelineStage(this.name, this.deals, this.amount);
}

class LeadStatusDefinition {
  final String label;
  final Color color;
  const LeadStatusDefinition(this.label, this.color);
}

const List<LeadStatusDefinition> kLeadStatuses = [
  LeadStatusDefinition('Cold', Color(0xFF8E9CB2)),
  LeadStatusDefinition('Warm', Color(0xFFE8A33D)),
  LeadStatusDefinition('Hot', Color(0xFFE5533D)),
  LeadStatusDefinition('Inactive', Color(0xFF4A5A6A)),
];

const List<String> kActivityTypes = [
  'Call',
  'Meeting',
  'Mobile Call',
  'Onsite meeting',
  'Onsite Service',
  'Group Event',
  'Google Meet',
  'Zoom Meet',
  'Teams Meeting',
  'Webex Meeting',
  'Jio Meet',
];

const List<String> kEventStatuses = [
  'Planned',
  'Held',
  'Not Held',
  'Canceled',
  'Rescheduled',
  'Skipped',
];

const List<String> kUsersAndGroups = [
  'Users',
  'Sin Johnsan',
  'Groups',
  'Team Selling',
  'Marketing Group',
  'Support Group',
];

class EventDraft {
  String name;
  String assignedTo;
  DateTime start;
  DateTime end;
  String status;
  String activityType;
  final List<String> participants;
  String agenda;
  factory EventDraft.basic(DateTime start, DateTime end) =>
      EventDraft(start: start, end: end);

  EventDraft({
    this.name = '',
    this.assignedTo = '',
    required this.start,
    required this.end,
    this.status = 'Planned',
    this.activityType = 'Call',
    List<String>? participants,
    this.agenda = '',
  }) : participants = participants ?? [];
}

class TimelogEntry {
  final String id;
  final String name;
  final Duration spent;
  final String notes;
  final DateTime logged;
  const TimelogEntry({
    required this.id,
    required this.name,
    required this.spent,
    this.notes = '',
    required this.logged,
  });
}

/// Parses CRM date/time strings (ISO, `yyyy-MM-dd hh:mm a`, `yyyy-MM-dd`
/// or an epoch millisecond number). Returns null when unparseable.
DateTime? parseCrmDateTime(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso.toLocal();
  final asInt = int.tryParse(s);
  if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
  final space = s.replaceAll('T', ' ').trim();
  final match = RegExp(
          r'^(\d{4})-(\d{1,2})-(\d{1,2})(?: (\d{1,2}):(\d{1,2}))?(?::(\d{2}))?(?: ?([AaPp])[Mm])?$')
      .firstMatch(space);
  if (match == null) return null;
  var h = int.parse(match.group(4) ?? '0');
  final m = int.parse(match.group(5) ?? '0');
  final sec = int.parse(match.group(6) ?? '0');
  final ampm = match.group(7);
  if (ampm != null) {
    if (ampm.toLowerCase() == 'p' && h < 12) h += 12;
    if (ampm.toLowerCase() == 'a' && h == 12) h = 0;
  }
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    h,
    m,
    sec,
  );
}

String _fieldOf(CrmRecord r, List<String> keys) {
  for (final k in keys) {
    final v = r.fields[k];
    if (v != null && v.trim().isNotEmpty) return v.trim();
    final loose = r.fields.entries
        .where(
            (e) => e.key.toLowerCase().replaceAll(' ', '') == k.toLowerCase())
        .toList();
    if (loose.isNotEmpty) return loose.first.value.trim();
  }
  return '';
}

/// Converts Events module records into calendar [AgendaItem]s.
List<AgendaItem> eventItemsFrom(List<CrmRecord> records) {
  final items = <AgendaItem>[];
  for (final r in records) {
    final startRaw = _fieldOf(r, const [
      'start',
      'startdateandtime',
      'start_date',
      'date_start',
      'Start Date & Time',
      'Start Date'
    ]);
    final start = parseCrmDateTime(startRaw);
    if (start == null) continue;
    final endRaw = _fieldOf(r, const [
      'end',
      'enddateandtime',
      'end_date',
      'date_end',
      'End Date & Time',
      'End Date'
    ]);
    final end = parseCrmDateTime(endRaw) ?? start.add(const Duration(hours: 1));
    final title = r.name;
    final type = _fieldOf(r, const [
      'activitytype',
      'eventtype',
      'Activity Type',
      'Event Type',
      'type'
    ]);
    final priority = _fieldOf(r, const ['priority', 'Priority']);
    final status = r.status ?? _fieldOf(r, const ['status', 'Status']);
    items.add(AgendaItem(
      start: start,
      end: end,
      title: title,
      type: type.isEmpty ? (title.isNotEmpty ? 'Event' : '') : type,
      priority: priority.isEmpty ? 'Medium' : priority,
      status: status.isEmpty ? 'Planned' : status,
    ));
  }
  items.sort((a, b) => a.start.compareTo(b.start));
  return items;
}
