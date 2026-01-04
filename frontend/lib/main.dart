import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/landing/landing_page.dart';
import 'screens/home/home_page.dart';
import 'screens/dashboard/dashboard_router.dart';
import 'providers/permission_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionProvider(),
      child: MaterialApp(
        title: 'Gravita',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const LandingPage(),
        routes: {
          '/home': (context) => const HomePage(),
          '/dashboard': (context) => const DashboardRouter(),
        },
      ),
    );
  }
}
