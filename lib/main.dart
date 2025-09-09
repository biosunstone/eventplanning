import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_login_screen.dart';

void main() {
  runApp(const EventPlanningApp());
}

class EventPlanningApp extends StatelessWidget {
  const EventPlanningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'Event Planning App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminLoginScreen(),
        },
      ),
    );
  }
}