import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import 'models.dart';

enum ApiMethod { get, post, put, delete, patch }

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// HTTP client for the BizForce CRM backend (base URL in [AppConfig]).
///
/// All screens read their data through here — records, create/update/delete,
/// the dashboard summary, the signed-in user's profile and settings. There is
/// intentionally NO dummy data: if the API returns nothing, screens show an
/// empty state.
///
/// Endpoint map (all relative to [AppConfig.apiBaseUrl]):
///   GET  /auth/me                -> profile
///   POST /auth/login             -> { email, password }     -> token
///   POST /auth/register          -> { firstName, lastName, email, password, ... }
///   POST /auth/forgot-password   -> { email }
///   GET  /<Module>               -> list (search/page/per_page)
///   POST /<Module>               -> create record
///   PUT/PATCH /<Module>/<id>     -> update record
///   DELETE /<Module>/<id>        -> delete record
///   GET  /dashboard              -> dashboard summary
///   GET  /settings , PUT /settings -> user settings
class ApiService {
  ApiService({String? baseUrl, String? token}) {
    _baseUrl = baseUrl ?? _baseUrl;
    _token = token;
  }

  String _baseUrl = AppConfig.apiBaseUrl;
  String? _token;

  /// The auth token last returned by the backend, if any.
  String? get token => _token;

  /// Clears the stored auth token (used on sign-out).
  void clearToken() => _token = null;

  void configure({String? baseUrl, String? token}) {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (token != null) _token = token;
  }

  String _moduleSlug(String module) {
    final key = module.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const aliases = <String, String>{
      'deals': 'potentials',
      'deal': 'potentials',
      'opportunity': 'potentials',
      'opportunities': 'potentials',
      'lead': 'leads',
      'contact': 'contacts',
      'account': 'accounts',
      'organizations': 'accounts',
      'organization': 'accounts',
      'case': 'tickets',
      'ticket': 'tickets',
      'phonecalls': 'calllogs',
      'events': 'calendar',
      'activities': 'calendar',
      'tasks': 'calendar',
      'cases': 'tickets',
      'timelogs': 'timeentries',
    };
    return aliases[key] ?? key;
  }

  String _fieldKey(String label) {
    final words = label
        .trim()
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (words.isEmpty) return label;
    final first = words.first[0].toLowerCase() + words.first.substring(1);
    return first +
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
  }

  Map<String, dynamic> _cleanRecordFields(
      String module, Map<String, dynamic> fields) {
    final slug = _moduleSlug(module);
    const allowed = <String, Set<String>>{
      'leads': {
        'salutation',
        'firstName',
        'lastName',
        'company',
        'assignedTo',
        'title',
        'email',
        'secondaryEmail',
        'phone',
        'mobile',
        'fax',
        'website',
        'leadSource',
        'leadStatus',
        'campaignId',
        'industry',
        'annualRevenue',
        'noOfEmployees',
        'rating',
        'interest',
        'leadScore',
        'nextFollowUp',
        'description',
        'street',
        'city',
        'state',
        'country',
        'postalCode',
        'poBox'
      },
      'calendar': {
        'subject',
        'activityType',
        'status',
        'priority',
        'description',
        'startAt',
        'endAt',
        'dueAt',
        'assignedTo',
        'location',
        'visibility'
      },
    };
    const integerFields = {'noOfEmployees', 'leadScore'};
    const numberFields = {'annualRevenue'};
    final result = <String, dynamic>{};
    for (final entry in fields.entries) {
      final key = _fieldKey(entry.key);
      if (allowed[slug] != null && !allowed[slug]!.contains(key)) continue;
      dynamic value = entry.value;
      if (value is String) {
        value = value.trim();
        if (value.isEmpty) continue;
      }
      if (integerFields.contains(key)) {
        value = int.tryParse('$value');
        if (value == null) continue;
      } else if (numberFields.contains(key)) {
        value = double.tryParse('$value');
        if (value == null) continue;
      }
      result[key] = value;
    }
    return result;
  }

  /// Core HTTP helper shared by every endpoint.
  Future<dynamic> request(
    String path, {
    ApiMethod method = ApiMethod.get,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final root = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final endpoint = path.startsWith('/') ? path : '/$path';
    final cleanQuery = query == null
        ? null
        : Map<String, dynamic>.fromEntries(query.entries.where(
            (entry) => entry.value != null && '${entry.value}'.isNotEmpty));
    final uri = Uri.parse('$root$endpoint')
        .replace(queryParameters: cleanQuery?.map((k, v) => MapEntry(k, '$v')));
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };

    http.Response response;
    switch (method) {
      case ApiMethod.get:
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 25));
      case ApiMethod.post:
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 25));
      case ApiMethod.put:
        response = await http
            .put(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 25));
      case ApiMethod.patch:
        response = await http
            .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 25));
      case ApiMethod.delete:
        response = await http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 25));
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        return response.body;
      }
    }
    throw ApiException(
      _messageFor(response),
      statusCode: response.statusCode,
    );
  }

  // ---------------------------------------------------------------- auth

  /// Authenticates against the configured backend.
  ///
  /// POST {baseUrl}/auth/login with email+password, expecting a token in
  /// the response (accepted keys: `token`, `access_token`, `accessToken`,
  /// `jwt`, `auth_token`), nested in `data`/`result` if needed.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final data = await request('/auth/login',
        method: ApiMethod.post,
        auth: false,
        body: {
          'email': email,
          'password': password,
        });
    final token = _deepFind(
        data, {'token', 'access_token', 'accessToken', 'jwt', 'auth_token'});
    if (token == null || token.isEmpty) {
      throw ApiException('The server did not return a login token.');
    }
    _token = token;
    final name = _deepFind(data,
            {'name', 'fullName', 'displayName', 'userName', 'username'}) ??
        _deepFind(data, {'user', 'data', 'result'}, nested: 'name');
    return (name != null && name.isNotEmpty)
        ? name
        : AppConfig.deriveDisplayName(email);
  }

  /// Registers a new user ("Register" option on the login screen).
  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? company,
    String? phone,
  }) async {
    final data = await request('/auth/register',
        method: ApiMethod.post,
        auth: false,
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'name': '$firstName $lastName'.trim(),
          'email': email,
          'password': password,
          if (company != null) 'company': company,
          if (phone != null) 'phone': phone,
        });
    final token = _deepFind(
        data, {'token', 'access_token', 'accessToken', 'jwt', 'auth_token'});
    if (token != null && token.isNotEmpty) _token = token;
    return '$firstName $lastName'.trim();
  }

  /// Fetches the signed-in user's profile as a display map.
  Future<Map<String, String>> profile() async {
    final data = await request('/auth/me');
    final map = _asMap(data);
    final fields = <String, String>{};
    map.forEach((k, v) {
      if (v == null || v is Map || v is List) return;
      final s = '$v';
      if (s.isNotEmpty && s != 'null') fields[k.toString()] = s;
    });
    return fields;
  }

  // --------------------------------------------------------------- records

  /// Fetches a module's records: GET /<Module>?search=&page=&per_page=.
  /// Returns an empty list when the API has no records for the module.
  Future<List<CrmRecord>> records(String module,
      {String? search,
      int page = 1,
      int perPage = 100,
      DateTime? from,
      DateTime? to}) async {
    final isCalendar =
        module == 'Events' || module == 'Activities' || module == 'Tasks';
    final path = '/${_moduleSlug(module)}';
    final data = await request(path, query: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (!isCalendar) 'page': '$page',
      if (!isCalendar) 'limit': '$perPage',
      if (module == 'Tasks') 'kind': 'todo',
      if (isCalendar)
        'from': (from ?? DateTime.now().subtract(const Duration(days: 365)))
            .toUtc()
            .toIso8601String(),
      if (isCalendar)
        'to': (to ?? DateTime.now().add(const Duration(days: 365)))
            .toUtc()
            .toIso8601String(),
    });
    return _parsedRecords(module, data);
  }

  /// Creates a record in a module (Lead, Contact, Task, ...).
  Future<void> createRecord(String module, Map<String, dynamic> fields) async {
    final isCalendar =
        module == 'Events' || module == 'Activities' || module == 'Tasks';
    final path = isCalendar ? '/calendar' : '/${_moduleSlug(module)}';
    final normalized = module == 'Tasks'
        ? <String, dynamic>{
            ...fields,
            'activityType': 'Task',
            if (fields['dueDate'] != null) 'dueAt': fields['dueDate'],
          }
        : fields;
    final body = _cleanRecordFields(module, normalized);
    if (_moduleSlug(module) == 'leads' &&
        '${body['assignedTo'] ?? ''}'.trim().isEmpty) {
      final me = await profile();
      final assignee = me['id'] ?? me['userId'];
      if (assignee != null && assignee.isNotEmpty) {
        body['assignedTo'] = assignee;
      }
    }
    await request(path, method: ApiMethod.post, body: body);
  }

  /// Updates an existing record.
  Future<void> updateRecord(
      String module, String id, Map<String, dynamic> fields) async {
    final path =
        module == 'Events' || module == 'Activities' || module == 'Tasks'
            ? '/calendar/$id'
            : '/${_moduleSlug(module)}/$id';
    await request(path,
        method: ApiMethod.put, body: _cleanRecordFields(module, fields));
  }

  /// Deletes an existing record.
  Future<void> deleteRecord(String module, String id) async {
    final path =
        module == 'Events' || module == 'Activities' || module == 'Tasks'
            ? '/calendar/$id'
            : '/${_moduleSlug(module)}/$id';
    await request(path, method: ApiMethod.delete);
  }

  Future<CrmRecord> record(String module, String id) async {
    final data = await request('/${_moduleSlug(module)}/$id');
    final map = _unwrapMap(data);
    if (map.isEmpty) {
      throw ApiException('The requested record could not be found.');
    }
    return crmRecordFromJson(module, map);
  }

  Future<List<CrmRecord>> recordActivities(String module, String id) async {
    final data =
        await request('/records/${_moduleSlug(module)}/$id/activities');
    return _parsedRecords('Activities', data);
  }

  Future<void> createRecordActivity(
      String module, String id, Map<String, dynamic> fields) async {
    await request('/records/${_moduleSlug(module)}/$id/activities',
        method: ApiMethod.post, body: fields);
  }

  // --------------------------------------------------------------- summary
  Future<List<Map<String, dynamic>>> activeUsers() async =>
      _mapList(await request('/calendar/users/active'));

  Future<List<Map<String, dynamic>>> picklists(String module) async =>
      _mapList(await request('/settings/picklists/all',
          query: {'module': _moduleSlug(module)}));

  Future<List<CrmRecord>> relatedRecords(
      String module, String id, String relatedModule) async {
    final data = await request(
        '/records/${_moduleSlug(module)}/$id/related/${_moduleSlug(relatedModule)}');
    return _parsedRecords(relatedModule, data);
  }

  Future<List<Map<String, dynamic>>> chatUsers() async =>
      _mapList(await request('/chat/users'));

  Future<List<Map<String, dynamic>>> chatConversations() async =>
      _mapList(await request('/chat/conversations'));

  Future<List<Map<String, dynamic>>> chatMessages(
          String conversationId) async =>
      _mapList(await request('/chat/conversations/$conversationId/messages'));

  Future<String> createChatConversation(List<String> participantIds) async {
    final data = await request('/chat/conversations',
        method: ApiMethod.post, body: {'participantIds': participantIds});
    final map = _unwrapMap(data);
    return '${map['id'] ?? ''}';
  }

  Future<void> sendChatMessage(String conversationId, String message) async {
    await request('/chat/conversations/$conversationId/messages',
        method: ApiMethod.post, body: {'body': message});
  }

  Future<void> markChatRead(String conversationId) async {
    await request('/chat/conversations/$conversationId/read',
        method: ApiMethod.post);
  }

  Future<List<Map<String, dynamic>>> notifications() async =>
      _mapList(await request('/settings/notifications'));

  Future<void> markNotificationRead(String id) async {
    await request('/settings/notifications/$id/read', method: ApiMethod.put);
  }

  Future<void> markAllNotificationsRead() async {
    await request('/settings/notifications/read-all', method: ApiMethod.put);
  }

  /// Dashboard summary (overview counts, pipeline stages, today's agenda).
  Future<Map<String, dynamic>> dashboard() async {
    try {
      final data = await request('/dashboard');
      return _asMap(data);
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      final results = await Future.wait([
        records('Leads', perPage: 100),
        records('Deals', perPage: 100),
        records('Cases', perPage: 100),
      ]);
      final deals = results[1];
      final stages = <String, List<CrmRecord>>{};
      for (final deal in deals) {
        final stage =
            deal.field('stage').isEmpty ? 'Unspecified' : deal.field('stage');
        stages.putIfAbsent(stage, () => []).add(deal);
      }
      final pipelineAmount = deals.fold<double>(
        0,
        (sum, record) => sum + (double.tryParse(record.field('amount')) ?? 0),
      );
      final revenue = deals
          .where((record) => record.field('stage') == 'Closed Won')
          .fold<double>(
            0,
            (sum, record) =>
                sum + (double.tryParse(record.field('amount')) ?? 0),
          );
      return {
        'revenue': revenue,
        'leads': results[0].length,
        'pipelineAmount': pipelineAmount,
        'openTickets': results[2]
            .where((record) => record.status?.toLowerCase() != 'closed')
            .length,
        'pipeline': [
          for (final entry in stages.entries)
            {
              'name': entry.key,
              'deals': entry.value.length,
              'amount': entry.value.fold<double>(
                0,
                (sum, record) =>
                    sum + (double.tryParse(record.field('amount')) ?? 0),
              ),
            },
        ],
      };
    }
  }

  // -------------------------------------------------------------- settings

  /// Fetches the current user/app settings key-value map.
  Future<Map<String, dynamic>> settings() async {
    final data = await request('/settings');
    final map = _asMap(data);
    final nested = map['settings'];
    return nested is Map ? nested.map((k, v) => MapEntry('$k', v)) : map;
  }

  /// Persists settings (PUT the whole map, or PATCH a delta).
  Future<void> updateSettings(Map<String, dynamic> delta,
      {bool patch = false}) async {
    await request('/settings',
        method: ApiMethod.put, body: {'settings': delta});
  }

  // ---------------------------------------------------------------- parsing

  List<CrmRecord> _parsedRecords(String module, dynamic data) {
    final list = _findRecordList(data);
    return list
        .whereType<Map>()
        .map((m) => crmRecordFromJson(module, m))
        .toList();
  }

  List<dynamic> _findRecordList(dynamic value) {
    if (value is List) return value;
    if (value is! Map) return const [];
    for (final key in const [
      "data",
      "result",
      "records",
      "items",
      "entities",
      "events",
      "activities",
    ]) {
      if (!value.containsKey(key)) continue;
      final nested = value[key];
      final found = _findRecordList(nested);
      if (found.isNotEmpty || nested is List) return found;
    }
    return const [];
  }

  List<Map<String, dynamic>> _mapList(dynamic value) => _findRecordList(value)
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry("$key", value)))
      .toList();

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      final map = data.map((k, v) => MapEntry('$k', v));
      for (final key in const ['data', 'result', 'record', 'user']) {
        final value = map[key];
        if (value is Map) {
          return value.map((k, v) => MapEntry('$k', v));
        }
      }
      return map;
    }
    if (data is List && data.isNotEmpty && data.first is Map) {
      return data.first.map((k, v) => MapEntry('$k', v));
    }
    return const {};
  }

  Map<dynamic, dynamic> _unwrapMap(dynamic data) {
    if (data is! Map) return const {};
    for (final key in const ['data', 'result', 'record', 'item']) {
      if (data[key] is Map) return data[key] as Map;
    }
    return data;
  }

  /// Recursively finds the first string value for any of [keys].
  static String? _deepFind(dynamic node, Set<String> keys, {String? nested}) {
    if (node is Map) {
      for (final key in keys) {
        final v = node[key];
        if (v is String && v.isNotEmpty) return v;
      }
      if (nested != null) {
        final inner = node[nested];
        if (inner is Map) {
          for (final key in keys) {
            final v = inner[key];
            if (v is String && v.isNotEmpty) return v;
          }
        }
      }
      for (final v in node.values) {
        if (v is Map || v is List) {
          final found = _deepFind(v, keys, nested: nested);
          if (found != null && found.isNotEmpty) return found;
        }
      }
    } else if (node is List) {
      for (final v in node) {
        final found = _deepFind(v, keys, nested: nested);
        if (found != null && found.isNotEmpty) return found;
      }
    }
    return null;
  }

  String _messageFor(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      if (body is Map) {
        final msg =
            body['message'] ?? body['error'] ?? body['detail'] ?? body['msg'];
        if (msg != null && '$msg'.isNotEmpty) return '$msg';
      }
    } catch (_) {}
    return 'Request failed (${r.statusCode})';
  }
}
