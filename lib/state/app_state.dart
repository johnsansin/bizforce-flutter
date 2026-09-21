import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_service.dart';

/// Global app state: session, theme and settings.
class AppState extends ChangeNotifier {
  AppState() {
    _load();
  }

  static const _kUserKey = 'signed_in_user';
  static const _kEmailKey = 'signed_in_email';
  static const _kThemeKey = 'dark_mode';
  static const _kKeepSignedIn = 'keep_signed_in';
  static const _kTokenKey = 'api_auth_token';

  final ApiService _api = ApiService();
  ApiService get api => _api;

  bool _ready = false;
  bool get ready => _ready;

  String _user = '';
  String _email = '';
  bool _keepSignedIn = false;
  bool _darkMode = false;
  bool _signedIn = false;
  Map<String, String> _profile = const {};

  String get user => _user;
  String get email => _email;
  bool get keepSignedIn => _keepSignedIn;
  bool get darkMode => _darkMode;
  bool get signedIn => _signedIn;
  Map<String, String> get profile => _profile;

  /// Display name of the signed-in user (from profile if available).
  String get displayName {
    final name = _profile['name'] ??
        _profile['fullName'] ??
        _profile['username'] ??
        _profile['firstName'];
    if (name != null && name.isNotEmpty) {
      final last = _profile['lastName'];
      if (last != null && last.isNotEmpty && name != last) return '$name $last';
      return name;
    }
    return _user.isNotEmpty ? _user : 'User';
  }

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _user = prefs.getString(_kUserKey) ?? '';
    _email = prefs.getString(_kEmailKey) ?? '';
    _keepSignedIn = prefs.getBool(_kKeepSignedIn) ?? false;
    _darkMode = prefs.getBool(_kThemeKey) ?? false;
    final token = prefs.getString(_kTokenKey);
    _signedIn =
        _user.isNotEmpty && _keepSignedIn && token != null && token.isNotEmpty;
    if (token != null && token.isNotEmpty) _api.configure(token: token);
    _ready = true;
    notifyListeners();
    if (_signedIn) refreshProfile();
  }

  /// Loads the signed-in user's profile from the API (called after sign-in
  /// and on cold start when a saved session exists).
  Future<void> refreshProfile() async {
    try {
      final profile = await _api.profile();
      _profile = profile;
      if (profile['name'] != null && _user.isEmpty) _user = profile['name']!;
      if (profile['email'] != null && _email.isEmpty)
        _email = profile['email']!;
      notifyListeners();
    } catch (_) {
      // Profile is optional; the app still works from the saved session.
    }
  }

  Future<void> signIn({
    required String user,
    required String email,
    bool keepSignedIn = true,
  }) async {
    _user = user;
    _email = email;
    _keepSignedIn = keepSignedIn;
    _signedIn = true;
    final token = _api.token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, user);
    await prefs.setString(_kEmailKey, email);
    await prefs.setBool(_kKeepSignedIn, keepSignedIn);
    if (token != null && token.isNotEmpty)
      await prefs.setString(_kTokenKey, token);
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
    await prefs.remove(_kEmailKey);
    await prefs.remove(_kTokenKey);
    await prefs.setBool(_kKeepSignedIn, false);
    _api.clearToken();
    _profile = const {};
    _user = '';
    _email = '';
    _signedIn = false;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThemeKey, value);
    notifyListeners();
  }
}
