import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/permissions_model.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/permissions_selector.dart';
import '../../services/permissions_service.dart';

class UserDetailPage extends StatefulWidget {
  final User user;

  const UserDetailPage({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final _permissionsService = PermissionsService();
  UserPermissions? _permissions;
  bool _isLoadingPermissions = true;
  bool _isEditingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      setState(() => _isLoadingPermissions = true);
      final permissions = await _permissionsService.getUserPermissions(widget.user.id);
      setState(() {
        _permissions = permissions;
        _isLoadingPermissions = false;
      });
    } catch (e) {
      print('Error loading permissions: $e');
      setState(() => _isLoadingPermissions = false);
    }
  }

  Future<void> _savePermissions() async {
    if (_permissions == null) return;
    
    try {
      await _permissionsService.updateUserPermissions(widget.user.id, _permissions!);
      if (mounted) {
        setState(() => _isEditingPermissions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update permissions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Member Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        _showUserMenu(context);
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      _buildProfileSection(),
                      const SizedBox(height: 24),

                      // Contact Information
                      _buildContactSection(),
                      const SizedBox(height: 24),

                      // Teams Section
                      if (widget.user.teams.isNotEmpty) ...[
                        _buildTeamsSection(),
                        const SizedBox(height: 24),
                      ],

                      // Roles Section
                      if (widget.user.roles.isNotEmpty) ...[
                        _buildRolesSection(),
                        const SizedBox(height: 24),
                      ],

                      // Status & Join Date
                      _buildStatusSection(),
                      const SizedBox(height: 24),

                      // Permissions Section
                      _buildPermissionsSection(),
                      const SizedBox(height: 24),
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

  Widget _buildProfileSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage:             widget.user.avatarUrl != null ? NetworkImage(widget.user.avatarUrl!) : null,
            child: widget.user.avatarUrl == null
                ? Text(
                    widget.user.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            widget.user.name,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.user.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(widget.user.status),
                width: 1,
              ),
            ),
            child: Text(
              widget.user.status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(widget.user.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_mail,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Information',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email, 'Email', widget.user.email),
          if (widget.user.phone != null && widget.user.phone!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Phone', widget.user.phone!),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamsSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group_work,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Teams (${widget.user.teams.length})',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.user.teams.map((team) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (team.isTeamLead)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Team Lead',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.badge,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Roles (${widget.user.roles.length})',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.user.roles.map((role) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Account Information',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today,
            'Joined',
            _formatDate(widget.user.createdAt),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.person_outline,
            'Status',
            widget.user.status,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'invited':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildPermissionsSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Permissions',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (!_isEditingPermissions)
                TextButton(
                  onPressed: () {
                    setState(() => _isEditingPermissions = true);
                  },
                  child: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _isEditingPermissions = false);
                        _loadPermissions(); // Reload to discard changes
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _savePermissions,
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPermissions)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_isEditingPermissions && _permissions != null)
            PermissionsSelector(
              initialPermissions: _permissions,
              onPermissionsChanged: (permissions) {
                setState(() => _permissions = permissions);
              },
            )
          else if (_permissions != null)
            _buildPermissionsDisplay()
          else
            Text(
              'No permissions assigned',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionsDisplay() {
    final hasAnyPermission = _permissions?.people != null ||
        _permissions?.teams != null ||
        _permissions?.departments != null ||
        _permissions?.listings != null ||
        _permissions?.analytics != null ||
        _permissions?.settings != null;

    if (!hasAnyPermission) {
      return Text(
        'No permissions assigned',
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_permissions?.people != null) _buildPermissionCategory('People & Members', _permissions!.people!),
        if (_permissions?.teams != null) _buildPermissionCategory('Teams', _permissions!.teams!),
        if (_permissions?.departments != null) _buildPermissionCategory('Departments', _permissions!.departments!),
        if (_permissions?.listings != null) _buildPermissionCategory('Listings', _permissions!.listings!),
        if (_permissions?.analytics != null) _buildPermissionCategory('Analytics', _permissions!.analytics!),
        if (_permissions?.settings != null) _buildPermissionCategory('Settings', _permissions!.settings!),
      ],
    );
  }

  Widget _buildPermissionCategory(String category, dynamic permissions) {
    final enabledPermissions = <String>[];
    
    if (permissions is PeoplePermissions) {
      if (permissions.viewMembers == true) enabledPermissions.add('View Members');
      if (permissions.inviteMembers == true) enabledPermissions.add('Invite Members');
      if (permissions.editMembers == true) enabledPermissions.add('Edit Members');
      if (permissions.removeMembers == true) enabledPermissions.add('Remove Members');
      if (permissions.viewAllProfiles == true) enabledPermissions.add('View All Profiles');
    } else if (permissions is TeamsPermissions) {
      if (permissions.viewTeams == true) enabledPermissions.add('View Teams');
      if (permissions.createTeams == true) enabledPermissions.add('Create Teams');
      if (permissions.editTeams == true) enabledPermissions.add('Edit Teams');
      if (permissions.deleteTeams == true) enabledPermissions.add('Delete Teams');
      if (permissions.manageTeamMembers == true) enabledPermissions.add('Manage Team Members');
      if (permissions.assignTeamLeads == true) enabledPermissions.add('Assign Team Leads');
    } else if (permissions is DepartmentsPermissions) {
      if (permissions.viewDepartments == true) enabledPermissions.add('View Departments');
      if (permissions.createDepartments == true) enabledPermissions.add('Create Departments');
      if (permissions.editDepartments == true) enabledPermissions.add('Edit Departments');
      if (permissions.deleteDepartments == true) enabledPermissions.add('Delete Departments');
      if (permissions.moveDepartments == true) enabledPermissions.add('Move Departments');
      if (permissions.assignTeamToDepartment == true) enabledPermissions.add('Assign Teams');
    } else if (permissions is ListingsPermissions) {
      if (permissions.create == true) enabledPermissions.add('Create Listings');
      if (permissions.editOwn == true) enabledPermissions.add('Edit Own Listings');
      if (permissions.editAny == true) enabledPermissions.add('Edit Any Listings');
      if (permissions.delete == true) enabledPermissions.add('Delete Listings');
      if (permissions.approve == true) enabledPermissions.add('Approve Listings');
      if (permissions.viewAll == true) enabledPermissions.add('View All Listings');
    } else if (permissions is AnalyticsPermissions) {
      if (permissions.viewOwn == true) enabledPermissions.add('View Own Analytics');
      if (permissions.viewOwnTeam == true) enabledPermissions.add('View Team Analytics');
      if (permissions.viewDepartment == true) enabledPermissions.add('View Department Analytics');
      if (permissions.viewCompany == true) enabledPermissions.add('View Company Analytics');
    } else if (permissions is SettingsPermissions) {
      if (permissions.viewSettings == true) enabledPermissions.add('View Settings');
      if (permissions.manageCompany == true) enabledPermissions.add('Manage Company');
      if (permissions.manageRoles == true) enabledPermissions.add('Manage Roles');
      if (permissions.managePermissions == true) enabledPermissions.add('Manage Permissions');
    }

    if (enabledPermissions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: enabledPermissions.map((perm) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                perm,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.green.shade300,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0d2818),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: Text(
                  'Edit Member',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit member
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.white),
                title: Text(
                  'Send Message',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement send message
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.white),
                title: Text(
                  'Move to Team',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement move to team
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                title: Text(
                  'Remove from Company',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement remove from company
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

