import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/user_summary.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class LoginResult {
  final String token;
  final AppUser user;
  LoginResult(this.token, this.user);
}

/// Thin wrapper around the REST API. Attaches the JWT to every request.
class ApiService {
  String? token;

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException(
          'Cannot reach the server. Is the backend running at $apiBaseUrl?');
    }

    dynamic body;
    try {
      body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    var message = 'Request failed (${res.statusCode})';
    if (body is Map && body['detail'] != null) {
      final detail = body['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty && detail.first is Map) {
        final messages = detail
            .whereType<Map>()
            .map((item) {
              final fields = item['loc'];
              final field = fields is List && fields.isNotEmpty
                  ? fields.last.toString()
                  : '';
              final error = (item['msg'] ?? message).toString();
              return field.isEmpty ? error : '$field: $error';
            })
            .join(', ');
        if (messages.isNotEmpty) message = messages;
      }
    }
    throw ApiException(message, res.statusCode);
  }

  Future<dynamic> _get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers));

  Future<dynamic> _post(String path, Map<String, dynamic> body) => _send(
      () => http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  // ---- auth ----

  LoginResult _loginResult(dynamic json) => LoginResult(
        json['access_token'] as String,
        AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  Future<LoginResult> login(String email, String password,
      {double? latitude, double? longitude}) async {
    return _loginResult(await _post('/auth/login', {
      'email': email,
      'password': password,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    }));
  }

  Future<LoginResult> register(
      String name, String email, String password,
      {double? latitude, double? longitude}) async {
    return _loginResult(await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    }));
  }

  Future<AppUser> me() async =>
      AppUser.fromJson(await _get('/auth/me') as Map<String, dynamic>);

  // ---- user ----

  Future<List<ChatMessage>> myMessages() async {
    final list = await _get('/messages/me') as List;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(String text,
      {required double latitude, required double longitude}) =>
      _post('/messages/me', {
        'text': text,
        'latitude': latitude,
        'longitude': longitude,
      });

  // ---- admin ----

  Future<List<UserSummary>> adminUsers() async {
    final list = await _get('/admin/users') as List;
    return list
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> adminConversation(String userId) async {
    final list = await _get('/admin/users/$userId/messages') as List;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> adminReply(String userId, String text) =>
      _post('/admin/users/$userId/messages', {'text': text});
}
