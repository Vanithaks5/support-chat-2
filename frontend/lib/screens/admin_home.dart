import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/chat_message.dart';
import '../models/user_summary.dart';
import '../providers/auth_provider.dart';
import '../widgets/chat_view.dart';
import '../widgets/brand_lockup.dart';

/// What the admin sees: every user on the left, the selected conversation on the right.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<UserSummary> _users = [];
  List<ChatMessage> _messages = [];
  String? _selectedId;
  bool _loadingUsers = true;
  String? _error;
  Timer? _timer;

  UserSummary? get _selected {
    for (final u in _users) {
      if (u.id == _selectedId) return u;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    try {
      final users = await auth.api.adminUsers();
      List<ChatMessage>? msgs;
      final id = _selectedId;
      if (id != null) msgs = await auth.api.adminConversation(id);
      if (!mounted) return;
      setState(() {
        _users = users;
        if (msgs != null && id == _selectedId) _messages = msgs;
        _loadingUsers = false;
        _error = null;
      });
    } catch (e) {
      auth.handleError(e);
      if (mounted) {
        setState(() {
          _loadingUsers = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _select(UserSummary u) async {
    setState(() {
      _selectedId = u.id;
      _messages = [];
    });
    await _refresh();
  }

  Future<void> _reply(String text) async {
    final auth = context.read<AuthProvider>();
    final id = _selectedId;
    if (id == null) return;
    try {
      await auth.api.adminReply(id, text);
    } catch (e) {
      auth.handleError(e);
      rethrow;
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wide = MediaQuery.of(context).size.width >= 720;
    final selected = _selected;

    final Widget body;
    if (wide) {
      body = Row(
        children: [
          SizedBox(width: 320, child: _userList()),
          const VerticalDivider(width: 1),
          Expanded(child: _chatPanel(selected, showBack: false)),
        ],
      );
    } else {
      body = selected == null ? _userList() : _chatPanel(selected, showBack: true);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLockup(logoHeight: 30),
            const SizedBox(width: 14),
            Text(
              'Admin - Support Inbox',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(auth.user!.name),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [TextButton(onPressed: _refresh, child: const Text('Retry'))],
            ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _userList() {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator());
    if (_users.isEmpty) {
      return const Center(child: Text('No users have registered yet.'));
    }
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final u = _users[i];
        return ListTile(
          selected: u.id == _selectedId,
          selectedTileColor: scheme.primaryContainer.withOpacity(0.4),
          leading: CircleAvatar(
            child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase()),
          ),
          title: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            u.lastMessage ?? u.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (u.lastMessageAt != null)
                Text(formatTime(u.lastMessageAt!),
                    style: TextStyle(fontSize: 11, color: scheme.outline)),
              if (u.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${u.unreadCount}',
                      style: TextStyle(color: scheme.onPrimary, fontSize: 11)),
                ),
            ],
          ),
          onTap: () => _select(u),
        );
      },
    );
  }

  Widget _chatPanel(UserSummary? selected, {required bool showBack}) {
    if (selected == null) {
      return const Center(child: Text('Select a user to view the conversation.'));
    }
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: ListTile(
            leading: showBack
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedId = null),
                  )
                : null,
            title: Text(selected.name),
            subtitle: Text(selected.email),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ChatView(
            key: ValueKey(selected.id),
            messages: _messages,
            myRole: 'admin',
            onSend: _reply,
            hint: 'Reply to ${selected.name}...',
            emptyText: 'This user has not sent any messages yet.',
          ),
        ),
      ],
    );
  }
}
