// ignore_for_file: unused_import, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
// ignore: unused_import
import 'screens/savings_screen.dart';
import 'screens/tips_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/insights_screen.dart';
import 'classes/settings_screen.dart';
// ignore: unused_import
import 'screens/bottom_nav.dart';
// ignore: unused_import
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://gcqeaexzkkjrtyynyolc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjcWVhZXh6a2tqcnR5eW55b2xjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNjQ5OTMsImV4cCI6MjA2Nzc0MDk5M30.KdMJJAVZhE64jU8AUbq8ETQzL6QkKYcdtMn76bNUrmU',
  );
  if (!kIsWeb) {
    final plugin = PaystackPlugin();
    await plugin.initialize(publicKey: 'pk_test_9850c7bcd834050484d07672404524e38e645f9b');
  }
  runApp(const SmartSpendApp());
}

class SmartSpendApp extends StatelessWidget {
  const SmartSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Smart Spend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      routerConfig: _router,
    );
  }
}

final GlobalKey<SettingsScreenState> settingsKey = GlobalKey<SettingsScreenState>();

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsScreen(key: settingsKey),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionsScreen(),
    ),
  ],
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;
    final isLoginRoute = state.matchedLocation == '/login';
    final isSplashRoute = state.matchedLocation == '/splash';

    if (!loggedIn && !isLoginRoute && !isSplashRoute) {
      return '/login';
    }
    if (loggedIn && (isLoginRoute || isSplashRoute)) {
      return '/home';
    }
    return null;
  },
);
