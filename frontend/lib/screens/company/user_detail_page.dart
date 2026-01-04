import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/permission_context_model.dart';
import '../../widgets/glass_container.dart';
import '../../services/permissions_service.dart';
import '../../services/company_service.dart';
import '../../providers/permission_provider.dart';

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
  final _companyService = CompanyService();
  PermissionContext? _permissionContext;
  bool _isLoadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionContext();
  }

  Future<void> _loadPermissionContext() async {
    try {
      setState(() => _isLoadingPermissions = true);
      
      // Try to get companyId from PermissionProvider first
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      String? companyId = permissionProvider.context?.companyId;
      
      // If not available, get from company service
      if (companyId == null || companyId.isEmpty) {
        try {
          final company = await _companyService.getCompany();
          companyId = company.id;
        } catch (e) {
          print('Error loading company: $e');
        }
      }
      
      if (companyId != null && companyId.isNotEmpty) {
        final context = await _permissionsService.getPermissionContext(widget.user.id, companyId);
        setState(() {
          _permissionContext = context;
          _isLoadingPermissions = false;
        });
      } else {
        setState(() => _isLoadingPermissions = false);
      }
    } catch (e) {
      print('Error loading permission context: $e');
      setState(() => _isLoadingPermissions = false);
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
                'Role & Permissions',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPermissions)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_permissionContext != null)
            _buildPermissionContextDisplay()
          else
            Text(
              'No role assigned',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionContextDisplay() {
    final context = _permissionContext!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role Type
        _buildInfoRow(
          Icons.badge,
          'Role',
          _getRoleDisplayName(context.roleType),
        ),
        const SizedBox(height: 12),
        
        // Scope
        _buildInfoRow(
          Icons.account_tree,
          'Scope',
          _getScopeDisplayName(context.scopeType, context.scopeId),
        ),
        const SizedBox(height: 12),
        
        // Max Approval Amount
        if (context.permissions.canApproveListings) ...[
          _buildInfoRow(
            Icons.attach_money,
            'Max Approval Amount',
            '\$${context.maxApprovalAmount.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
        ],
        
        // Permissions
        Text(
          'Permissions',
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
          children: [
            if (context.permissions.canManageStructure)
              _buildPermissionBadge('Manage Structure'),
            if (context.permissions.canApproveListings)
              _buildPermissionBadge('Approve Listings'),
            if (context.permissions.canAccessSettings)
              _buildPermissionBadge('Access Settings'),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.green.shade300,
        ),
      ),
    );
  }

  String _getRoleDisplayName(RoleType roleType) {
    switch (roleType) {
      case RoleType.admin:
        return 'Company Admin';
      case RoleType.manager:
        return 'Manager';
      case RoleType.lead:
        return 'Team Lead';
      case RoleType.member:
        return 'Team Member';
    }
  }

  String _getScopeDisplayName(ScopeType scopeType, String? scopeId) {
    switch (scopeType) {
      case ScopeType.company:
        return 'Company-wide';
      case ScopeType.department:
        return scopeId != null ? 'Department (${scopeId.substring(0, 8)}...)' : 'Department';
      case ScopeType.team:
        return scopeId != null ? 'Team (${scopeId.substring(0, 8)}...)' : 'Team';
    }
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

