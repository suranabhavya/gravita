import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final context_ = permissionProvider.context;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0d2818),
            Color(0xFF1a4d2e),
            Color(0xFF0f2e1a),
            Color(0xFF052e16),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with role badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Member',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.group,
                              size: 16,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Team Member',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Stats Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Info Card
                      _buildInfoCard(),
                      const SizedBox(height: 16),

                      // Permissions Card
                      _buildPermissionsCard(context_),
                      const SizedBox(height: 16),

                      // Quick Actions
                      _buildQuickActionsCard(context),
                      const SizedBox(height: 16),

                      // Personal Overview
                      _buildOverviewCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can create material listings and view your team',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Permissions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildPermissionItem(
            icon: Icons.business_center,
            title: 'Manage Structure',
            description: 'Create/edit teams and departments',
            enabled: false,
          ),
          const SizedBox(height: 12),
          _buildPermissionItem(
            icon: Icons.check_circle,
            title: 'Approve Listings',
            description: 'Approve material listings',
            enabled: false,
          ),
          const SizedBox(height: 12),
          _buildPermissionItem(
            icon: Icons.settings,
            title: 'Access Settings',
            description: 'Company settings',
            enabled: false,
          ),
          const SizedBox(height: 12),
          _buildPermissionItem(
            icon: Icons.add_box,
            title: 'Create Listings',
            description: 'Create material listings',
            enabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: enabled ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(
          enabled ? Icons.check_circle : Icons.cancel,
          color: enabled ? Colors.green : Colors.grey,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            context,
            icon: Icons.add_box,
            title: 'Create Listing',
            onTap: () => Navigator.pushNamed(context, '/materials/create'),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: Icons.list_alt,
            title: 'My Listings',
            onTap: () => Navigator.pushNamed(context, '/materials/my-listings'),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: Icons.group,
            title: 'My Team',
            onTap: () => Navigator.pushNamed(context, '/teams/my-team'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Statistics',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your personal statistics will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}


