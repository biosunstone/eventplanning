import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
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
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'Event Planning Admin',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const AdminLoginScreen(),
      ),
    );
  }
}