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
    final uri = Uri.parse('$root$endpoint').replace(queryParameters: query);
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
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
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
    if (token != null && token.isNotEmpty) _token = token;
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
      {String? search, int page = 1, int perPage = 100}) async {
    final data = await request('/$module', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': '$page',
      'per_page': '$perPage',
    });
    return _parsedRecords(module, data);
  }

  /// Creates a record in a module (Lead, Contact, Task, ...).
  Future<void> createRecord(String module, Map<String, dynamic> fields) async {
    await request('/$module', method: ApiMethod.post, body: {
      'module': module,
      ...fields,
    });
  }

  /// Updates an existing record.
  Future<void> updateRecord(
      String module, String id, Map<String, dynamic> fields) async {
    await request('/$module/$id', method: ApiMethod.put, body: fields);
  }

  /// Deletes an existing record.
  Future<void> deleteRecord(String module, String id) async {
    await request('/$module/$id', method: ApiMethod.delete);
  }

  // --------------------------------------------------------------- summary

  /// Dashboard summary (overview counts, pipeline stages, today's agenda).
  Future<Map<String, dynamic>> dashboard() async {
    final data = await request('/dashboard');
    return _asMap(data);
  }

  // -------------------------------------------------------------- settings

  /// Fetches the current user/app settings key-value map.
  Future<Map<String, dynamic>> settings() async {
    final data = await request('/settings');
    return _asMap(data);
  }

  /// Persists settings (PUT the whole map, or PATCH a delta).
  Future<void> updateSettings(Map<String, dynamic> delta,
      {bool patch = true}) async {
    await request('/settings',
        method: patch ? ApiMethod.patch : ApiMethod.put, body: delta);
  }

  // ---------------------------------------------------------------- parsing

  List<CrmRecord> _parsedRecords(String module, dynamic data) {
    if (data is! Map && data is! List) return const [];
    dynamic list = data;
    if (data is Map) {
      dynamic result =
          data['result'] ?? data['records'] ?? data['data'] ?? data['items'];
      if (result is Map && result['records'] is List)
        result = result['records'];
      if (result is Map && result['data'] is List) result = result['data'];
      if (result is Map && result['entities'] is List)
        result = result['entities'];
      result ??= data['result'];
      list = result;
      if (list is! List) list = [];
    }
    return list
        .whereType<Map>()
        .map((m) => crmRecordFromJson(module, m))
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return data.map((k, v) => MapEntry('$k', v));
    if (data is List && data.isNotEmpty && data.first is Map) {
      return data.first.map((k, v) => MapEntry('$k', v));
    }
    return const {};
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
