import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/admin_home.dart';
import 'screens/login_screen.dart';
import 'screens/user_home.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const SupportChatApp(),
    ),
  );
}

class SupportChatApp extends StatelessWidget {
  const SupportChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instaresponse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE31837),
          primary: const Color(0xFFE31837),
          secondary: const Color(0xFF004C97),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEAF4FC),
          foregroundColor: Color(0xFF164B73),
          centerTitle: false,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE31837),
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF004C97),
          ),
        ),
        useMaterial3: true,
      ),
      home: const _Root(),
    );
  }
}

/// Chooses the screen from the login state and role.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = auth.user;
    if (user == null) return const LoginScreen();
    return user.isAdmin ? const AdminHome() : const UserHome();
  }
}
