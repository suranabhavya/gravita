import 'package:flutter/material.dart';
import '../dashboard/dashboard_router.dart';
import '../add_material/add_material_page.dart';
import '../company/company_page_router.dart';
import '../profile/profile_page.dart';
import '../../widgets/glass_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardRouter(),
    const AddMaterialPage(),
    const CompanyPageRouter(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page content - fill available space
          Positioned.fill(
            child: _pages[_currentIndex],
          ),
          // Bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: GlassBottomNavBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

