import 'package:flutter/material.dart';
import 'screens/landing/landing_page.dart';
import 'screens/home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gravita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LandingPage(),
      routes: {
        '/home': (context) => const HomePage(),
      },
    );
  }
}
