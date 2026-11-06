import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';

/// Holds the logged-in user + JWT. The token is kept in the browser's
/// localStorage (via shared_preferences) so a page refresh keeps you logged in.
class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';

  final ApiService api = ApiService();

  AppUser? user;
  bool initializing = true;

  bool get isLoggedIn => user != null;

  /// Called once at startup: restore a saved session if the token is still valid.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_tokenKey);
      if (saved != null) {
        api.token = saved;
        user = await api.me();
      }
    } catch (_) {
      api.token = null;
      user = null;
      await _clearToken();
    }
    initializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String password,
      {double? latitude, double? longitude}) async {
    final result = await api.login(email.trim(), password,
        latitude: latitude, longitude: longitude);
    await _startSession(result);
  }

  Future<void> register(String name, String email, String password,
      {double? latitude, double? longitude}) async {
    final result = await api.register(name.trim(), email.trim(), password,
        latitude: latitude, longitude: longitude);
    await _startSession(result);
  }

  Future<void> _startSession(LoginResult result) async {
    api.token = result.token;
    user = result.user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.token);
    notifyListeners();
  }

  Future<void> logout() async {
    api.token = null;
    user = null;
    await _clearToken();
    notifyListeners();
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Screens call this when a request fails; an expired token logs you out.
  void handleError(Object e) {
    if (e is ApiException && e.isUnauthorized) logout();
  }
}
