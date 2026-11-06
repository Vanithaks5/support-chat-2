import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../widgets/chat_view.dart';
import '../widgets/brand_lockup.dart';

/// What a normal user sees: a chat with the admin.
class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(pollInterval, (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    try {
      final msgs = await auth.api.myMessages();
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      auth.handleError(e);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _send(String text) async {
    final auth = context.read<AuthProvider>();
    try {
      final location = await getUserLocation();
      await auth.api.sendMessage(text,
          latitude: location.latitude, longitude: location.longitude);
    } catch (e) {
      auth.handleError(e);
      rethrow;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      appBar: AppBar(
        title: const BrandLockup(logoHeight: 30),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(user.name),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              if (_error != null)
                MaterialBanner(
                  content: Text(_error!),
                  actions: [
                    TextButton(onPressed: _load, child: const Text('Retry'))
                  ],
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ChatView(
                        messages: _messages,
                        myRole: 'user',
                        onSend: _send,
                        hint: 'Write a message to the admin...',
                        emptyText:
                            'No messages yet. Say hello to the admin below!',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
