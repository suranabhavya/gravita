import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final canAccessSettings = permissionProvider.canAccessSettings;
    final isAdmin = permissionProvider.isAdmin;

    // Show access denied if user doesn't have permission
    if (!canAccessSettings || !isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF0d2818),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'You don\'t have permission to access settings. Only company admins can manage settings.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ade80),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Admin settings screen
    return Scaffold(
      backgroundColor: const Color(0xFF0d2818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Admin Settings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Company Settings Section
              _buildSectionTitle('Company Settings'),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                icon: Icons.business,
                title: 'Company Profile',
                subtitle: 'Update company name, type, and details',
                onTap: () {
                  // Navigate to company profile settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Company Profile settings coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                icon: Icons.category,
                title: 'Material Categories',
                subtitle: 'Manage material types and categories',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Material Categories settings coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Roles & Permissions Section
              _buildSectionTitle('Roles & Permissions'),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                icon: Icons.admin_panel_settings,
                title: 'Manage Roles',
                subtitle: 'View and edit role permissions',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Role management coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                icon: Icons.attach_money,
                title: 'Approval Limits',
                subtitle: 'Set default approval limits by role',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Approval limits settings coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Workflow Settings Section
              _buildSectionTitle('Workflow Settings'),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                icon: Icons.approval,
                title: 'Approval Workflow',
                subtitle: 'Configure approval chain and escalation',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Approval workflow settings coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                icon: Icons.access_time,
                title: 'Auto-Escalation',
                subtitle: 'Set auto-escalation timeout (currently 48 hours)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Auto-escalation settings coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Security & Audit Section
              _buildSectionTitle('Security & Audit'),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                icon: Icons.history,
                title: 'Activity Logs',
                subtitle: 'View company-wide activity logs',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity logs coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                icon: Icons.security,
                title: 'Security Settings',
                subtitle: 'Manage 2FA and security policies',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Security settings coming soon'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
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
}


