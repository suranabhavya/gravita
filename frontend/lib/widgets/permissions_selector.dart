import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/permissions_model.dart';
import '../widgets/glass_container.dart';

class PermissionsSelector extends StatefulWidget {
  final UserPermissions? initialPermissions;
  final Function(UserPermissions) onPermissionsChanged;

  const PermissionsSelector({
    super.key,
    this.initialPermissions,
    required this.onPermissionsChanged,
  });

  @override
  State<PermissionsSelector> createState() => _PermissionsSelectorState();
}

class _PermissionsSelectorState extends State<PermissionsSelector> {
  late UserPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.initialPermissions ?? UserPermissions(
      people: PeoplePermissions(),
      teams: TeamsPermissions(),
      departments: DepartmentsPermissions(),
      listings: ListingsPermissions(),
      analytics: AnalyticsPermissions(),
      settings: SettingsPermissions(),
    );
  }

  void _updatePermissions() {
    widget.onPermissionsChanged(_permissions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildCategory(
          'People & Members',
          Icons.people,
          [
            _PermissionItem('view_members', 'View Members', 'View company members list'),
            _PermissionItem('invite_members', 'Invite Members', 'Send invitations to new members'),
            _PermissionItem('edit_members', 'Edit Members', 'Edit member profiles'),
            _PermissionItem('remove_members', 'Remove Members', 'Remove members from company'),
            _PermissionItem('view_all_profiles', 'View All Profiles', 'View detailed profiles'),
          ],
          (key, value) {
            setState(() {
              _permissions = _permissions.copyWith(
                people: PeoplePermissions(
                  viewMembers: key == 'view_members' ? value : _permissions.people?.viewMembers,
                  inviteMembers: key == 'invite_members' ? value : _permissions.people?.inviteMembers,
                  editMembers: key == 'edit_members' ? value : _permissions.people?.editMembers,
                  removeMembers: key == 'remove_members' ? value : _permissions.people?.removeMembers,
                  viewAllProfiles: key == 'view_all_profiles' ? value : _permissions.people?.viewAllProfiles,
                ),
              );
            });
            _updatePermissions();
          },
          (key) {
            switch (key) {
              case 'view_members':
                return _permissions.people?.viewMembers ?? false;
              case 'invite_members':
                return _permissions.people?.inviteMembers ?? false;
              case 'edit_members':
                return _permissions.people?.editMembers ?? false;
              case 'remove_members':
                return _permissions.people?.removeMembers ?? false;
              case 'view_all_profiles':
                return _permissions.people?.viewAllProfiles ?? false;
              default:
                return false;
            }
          },
        ),
        const SizedBox(height: 16),
        _buildCategory(
          'Teams',
          Icons.group_work,
          [
            _PermissionItem('view_teams', 'View Teams', 'View teams list and details'),
            _PermissionItem('create_teams', 'Create Teams', 'Create new teams'),
            _PermissionItem('edit_teams', 'Edit Teams', 'Edit team information'),
            _PermissionItem('delete_teams', 'Delete Teams', 'Delete teams'),
            _PermissionItem('manage_team_members', 'Manage Team Members', 'Add/remove members'),
            _PermissionItem('assign_team_leads', 'Assign Team Leads', 'Assign team leaders'),
          ],
          (key, value) {
            setState(() {
              final currentTeams = _permissions.teams ?? TeamsPermissions();
              _permissions = _permissions.copyWith(
                teams: TeamsPermissions(
                  viewTeams: key == 'view_teams' ? value : (currentTeams.viewTeams ?? false),
                  createTeams: key == 'create_teams' ? value : (currentTeams.createTeams ?? false),
                  editTeams: key == 'edit_teams' ? value : (currentTeams.editTeams ?? false),
                  deleteTeams: key == 'delete_teams' ? value : (currentTeams.deleteTeams ?? false),
                  manageTeamMembers: key == 'manage_team_members' ? value : (currentTeams.manageTeamMembers ?? false),
                  assignTeamLeads: key == 'assign_team_leads' ? value : (currentTeams.assignTeamLeads ?? false),
                ),
              );
            });
            _updatePermissions();
          },
          (key) {
            switch (key) {
              case 'view_teams':
                return _permissions.teams?.viewTeams ?? false;
              case 'create_teams':
                return _permissions.teams?.createTeams ?? false;
              case 'edit_teams':
                return _permissions.teams?.editTeams ?? false;
              case 'delete_teams':
                return _permissions.teams?.deleteTeams ?? false;
              case 'manage_team_members':
                return _permissions.teams?.manageTeamMembers ?? false;
              case 'assign_team_leads':
                return _permissions.teams?.assignTeamLeads ?? false;
              default:
                return false;
            }
          },
        ),
        const SizedBox(height: 16),
        _buildCategory(
          'Departments',
          Icons.business,
          [
            _PermissionItem('view_departments', 'View Departments', 'View department structure'),
            _PermissionItem('create_departments', 'Create Departments', 'Create new departments'),
            _PermissionItem('edit_departments', 'Edit Departments', 'Edit department information'),
            _PermissionItem('delete_departments', 'Delete Departments', 'Delete departments'),
            _PermissionItem('move_departments', 'Move Departments', 'Reorganize hierarchy'),
            _PermissionItem('assign_team_to_department', 'Assign Teams', 'Assign teams to departments'),
          ],
          (key, value) {
            setState(() {
              final currentDepts = _permissions.departments ?? DepartmentsPermissions();
              _permissions = _permissions.copyWith(
                departments: DepartmentsPermissions(
                  viewDepartments: key == 'view_departments' ? value : (currentDepts.viewDepartments ?? false),
                  createDepartments: key == 'create_departments' ? value : (currentDepts.createDepartments ?? false),
                  editDepartments: key == 'edit_departments' ? value : (currentDepts.editDepartments ?? false),
                  deleteDepartments: key == 'delete_departments' ? value : (currentDepts.deleteDepartments ?? false),
                  moveDepartments: key == 'move_departments' ? value : (currentDepts.moveDepartments ?? false),
                  assignTeamToDepartment: key == 'assign_team_to_department' ? value : (currentDepts.assignTeamToDepartment ?? false),
                ),
              );
            });
            _updatePermissions();
          },
          (key) {
            switch (key) {
              case 'view_departments':
                return _permissions.departments?.viewDepartments ?? false;
              case 'create_departments':
                return _permissions.departments?.createDepartments ?? false;
              case 'edit_departments':
                return _permissions.departments?.editDepartments ?? false;
              case 'delete_departments':
                return _permissions.departments?.deleteDepartments ?? false;
              case 'move_departments':
                return _permissions.departments?.moveDepartments ?? false;
              case 'assign_team_to_department':
                return _permissions.departments?.assignTeamToDepartment ?? false;
              default:
                return false;
            }
          },
        ),
        const SizedBox(height: 16),
        _buildCategory(
          'Listings',
          Icons.inventory,
          [
            _PermissionItem('create', 'Create Listings', 'Create new material listings'),
            _PermissionItem('edit_own', 'Edit Own Listings', 'Edit listings you created'),
            _PermissionItem('edit_any', 'Edit Any Listings', 'Edit any company listings'),
            _PermissionItem('delete', 'Delete Listings', 'Delete listings'),
            _PermissionItem('approve', 'Approve Listings', 'Approve pending listings'),
            _PermissionItem('view_all', 'View All Listings', 'View all company listings'),
          ],
          (key, value) {
            setState(() {
              final currentListings = _permissions.listings ?? ListingsPermissions();
              _permissions = _permissions.copyWith(
                listings: ListingsPermissions(
                  create: key == 'create' ? value : (currentListings.create ?? false),
                  editOwn: key == 'edit_own' ? value : (currentListings.editOwn ?? false),
                  editAny: key == 'edit_any' ? value : (currentListings.editAny ?? false),
                  delete: key == 'delete' ? value : (currentListings.delete ?? false),
                  approve: key == 'approve' ? value : (currentListings.approve ?? false),
                  viewAll: key == 'view_all' ? value : (currentListings.viewAll ?? false),
                ),
              );
            });
            _updatePermissions();
          },
          (key) {
            switch (key) {
              case 'create':
                return _permissions.listings?.create ?? false;
              case 'edit_own':
                return _permissions.listings?.editOwn ?? false;
              case 'edit_any':
                return _permissions.listings?.editAny ?? false;
              case 'delete':
                return _permissions.listings?.delete ?? false;
              case 'approve':
                return _permissions.listings?.approve ?? false;
              case 'view_all':
                return _permissions.listings?.viewAll ?? false;
              default:
                return false;
            }
          },
        ),
        const SizedBox(height: 16),
        _buildCategory(
          'Analytics',
          Icons.analytics,
          [
            _PermissionItem('view_own', 'View Own Analytics', 'View your personal analytics'),
            _PermissionItem('view_own_team', 'View Team Analytics', 'View your team analytics'),
            _PermissionItem('view_department', 'View Department Analytics', 'View department analytics'),
            _PermissionItem('view_company', 'View Company Analytics', 'View company-wide analytics'),
          ],
          (key, value) {
            setState(() {
              final currentAnalytics = _permissions.analytics ?? AnalyticsPermissions();
              _permissions = _permissions.copyWith(
                analytics: AnalyticsPermissions(
                  viewOwn: key == 'view_own' ? value : (currentAnalytics.viewOwn ?? false),
                  viewOwnTeam: key == 'view_own_team' ? value : (currentAnalytics.viewOwnTeam ?? false),
                  viewDepartment: key == 'view_department' ? value : (currentAnalytics.viewDepartment ?? false),
                  viewCompany: key == 'view_company' ? value : (currentAnalytics.viewCompany ?? false),
                ),
              );
            });
            _updatePermissions();
          },
          (key) {
            switch (key) {
              case 'view_own':
                return _permissions.analytics?.viewOwn ?? false;
              case 'view_own_team':
                return _permissions.analytics?.viewOwnTeam ?? false;
              case 'view_department':
                return _permissions.analytics?.viewDepartment ?? false;
              case 'view_company':
                return _permissions.analytics?.viewCompany ?? false;
              default:
                return false;
            }
          },
        ),
        const SizedBox(height: 16),
        _buildCategory(
          'Settings',
          Icons.settings,
          [
            _PermissionItem('view_settings', 'View Settings', 'View company settings'),
            _PermissionItem('manage_company', 'Manage Company', 'Edit company information'),
            _PermissionItem('manage_roles', 'Manage Roles', 'Create and edit roles'),
            _PermissionItem('manage_permissions', 'Manage Permissions', 'Manage user permissions'),
          ],
          (key, value) {
            setState(() {
              final currentSettings = _permissions.settings ?? SettingsPermissions();
              _permissions = _permissions.copyWith(
                settings: SettingsPermissions(
                  viewSettings: key == 'view_settings' ? value : (currentSettings.viewSettings ?? false),
                  manageCompany: key == 'manage_company' ? value : (currentSettings.manageCompany ?? false),
                  manageRoles: key == 'manage_roles' ? value : (currentSettings.manageRoles ?? false),
                  managePermissions: key == 'manage_permissions' ? value : (currentSettings.managePermissions ?? false),
                ),
              );
            });
            _updatePermissions();
          },
          (key) {
            switch (key) {
              case 'view_settings':
                return _permissions.settings?.viewSettings ?? false;
              case 'manage_company':
                return _permissions.settings?.manageCompany ?? false;
              case 'manage_roles':
                return _permissions.settings?.manageRoles ?? false;
              case 'manage_permissions':
                return _permissions.settings?.managePermissions ?? false;
              default:
                return false;
            }
          },
        ),
      ],
    );
  }

  Widget _buildCategory(
    String title,
    IconData icon,
    List<_PermissionItem> permissions,
    Function(String, bool) onChanged,
    bool Function(String) getValue,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...permissions.map((perm) => _buildPermissionCheckbox(
                perm.key,
                perm.label,
                perm.description,
                getValue(perm.key),
                (value) => onChanged(perm.key, value),
              )),
        ],
      ),
    );
  }

  Widget _buildPermissionCheckbox(
    String key,
    String label,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            checkColor: Colors.white,
            fillColor: WidgetStateProperty.all(
              value ? Colors.green : Colors.white.withValues(alpha: 0.2),
            ),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionItem {
  final String key;
  final String label;
  final String description;

  _PermissionItem(this.key, this.label, this.description);
}

