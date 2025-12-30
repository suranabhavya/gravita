import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/company_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../models/department_model.dart';
import '../../services/company_service.dart';
import '../../services/team_service.dart';
import '../../services/user_service.dart';
import '../../services/department_service.dart';
import '../../services/invitation_service.dart';
import '../../widgets/create_team_bottom_sheet.dart';
import '../../widgets/create_department_bottom_sheet.dart';
import 'people_tab.dart';
import 'teams_tab.dart';
import 'structure_tab.dart';
import 'user_detail_page.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  final CompanyService _companyService = CompanyService();
  final TeamService _teamService = TeamService();
  final UserService _userService = UserService();
  final DepartmentService _departmentService = DepartmentService();
  final InvitationService _invitationService = InvitationService();

  Company? _company;
  List<TeamListItem> _teams = [];
  CompanyMembersResponse? _membersData;
  List<DepartmentTree> _departments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTab = _tabController.index);
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final company = await _companyService.getCompany();
      final teams = await _teamService.getCompanyTeams();
      final membersData = await _userService.getCompanyMembers();
      final departments = await _departmentService.getCompanyDepartments();

      setState(() {
        _company = company;
        _teams = teams;
        _membersData = membersData;
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleInviteMember() async {
    // Show invite member bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInviteMemberSheet(),
    );
  }

  Future<void> _handleCreateDepartment({String? parentDepartmentId}) async {
    if (_teams.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create teams first before creating departments'),
          ),
        );
      }
      return;
    }

    // Get teams that are not assigned to any department
    final assignedTeamIds = <String>{};
    for (final dept in _departments) {
      _collectTeamIds(dept, assignedTeamIds);
    }
    final unassignedTeams = _teams.where((t) => !assignedTeamIds.contains(t.id)).toList();

    if (unassignedTeams.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All teams are already assigned to departments'),
          ),
        );
      }
      return;
    }

    // Get all company members for manager selection
    final availableManagers = _membersData?.members ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateDepartmentBottomSheet(
        availableTeams: unassignedTeams,
        existingDepartments: _departments,
        availableManagers: availableManagers,
        onSubmit: ({
          required String name,
          String? description,
          String? parentDepartmentId,
          String? managerId,
          required List<String> teamIds,
        }) async {
          try {
            // Close the bottom sheet first
            if (mounted) {
              Navigator.of(context).pop();
            }

            await _departmentService.createDepartment(
              name: name,
              description: description,
              parentDepartmentId: parentDepartmentId,
              managerId: managerId,
              teamIds: teamIds,
            );

            // Reload all data
            await _loadData();

            // Switch to Structure tab to show the newly created department
            // Use a small delay to ensure state update is complete
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 100));
              if (_tabController.index != 2) {
                _tabController.animateTo(2);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Department created successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create department: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _collectTeamIds(DepartmentTree dept, Set<String> teamIds) {
    for (final team in dept.teams) {
      teamIds.add(team.id);
    }
    for (final child in dept.children) {
      _collectTeamIds(child, teamIds);
    }
  }

  void _showDepartmentContextMenu(DepartmentTree department) {
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
                  'Edit Department',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleEditDepartment(department);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.white),
                title: Text(
                  'Move Department',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleMoveDepartment(department);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Department',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement delete
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEditDepartment(DepartmentTree department) async {
    // TODO: Show edit department bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit department - Coming soon')),
    );
  }

  Future<void> _handleMoveDepartment(DepartmentTree department) async {
    // TODO: Show move department bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Move department - Coming soon')),
    );
  }

  Future<void> _handleCreateTeam() async {
    if (_membersData == null) return;

    final unassignedMembers = _membersData!.members
        .where((m) => m.isUnassigned)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTeamBottomSheet(
        availableMembers: unassignedMembers,
        onSubmit: ({
          required String name,
          String? description,
          String? location,
          required List<String> memberIds,
          String? teamLeadId,
        }) async {
          try {
            // Close the bottom sheet first
            if (mounted) {
              Navigator.of(context).pop();
            }
            
            // Create the team
            await _teamService.createTeam(
              name: name,
              description: description,
              location: location,
              memberIds: memberIds,
              teamLeadId: teamLeadId,
            );
            
            // Reload all data
            await _loadData();
            
            // Switch to Teams tab to show the newly created team
            // Use a small delay to ensure state update is complete
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 100));
              if (_tabController.index != 1) {
                _tabController.animateTo(1);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Team created successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create team: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildInviteMemberSheet() {
    final emailController = TextEditingController();
    String? selectedRoleType; // 'admin', 'manager', 'member', 'viewer'
    String? selectedTeamId;

    return StatefulBuilder(
      builder: (context, setState) {
        // Role options with descriptions
        final roleOptions = [
          {
            'value': 'admin',
            'label': 'Admin',
            'description': 'Full control',
          },
          {
            'value': 'manager',
            'label': 'Manager',
            'description': 'Manage & approve',
          },
          {
            'value': 'member',
            'label': 'Member',
            'description': 'Create listings',
          },
          {
            'value': 'viewer',
            'label': 'Viewer',
            'description': 'Read-only',
          },
        ];

        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Color(0xFF0d2818),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text(
                      'Invite New Member',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Email Address Field
                    Text(
                      'Email Address *',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: TextField(
                        controller: emailController,
                        style: GoogleFonts.inter(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'sarah@example.com',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Assign Role Field
                    Text(
                      'Assign Role?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...roleOptions.map((role) {
                      final isSelected = selectedRoleType == role['value'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedRoleType = role['value'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role['label'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '(${role['description'] as String})',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    
                    // Assign to Team Field
                    Text(
                      'Assign to Team',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _teams.isEmpty 
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: selectedTeamId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF1a4d2e),
                        style: GoogleFonts.inter(
                          color: _teams.isEmpty 
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white,
                          fontSize: 14,
                        ),
                        hint: Text(
                          _teams.isEmpty 
                              ? 'No teams yet'
                              : 'Select a team (optional)',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        items: _teams.isEmpty
                            ? [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  enabled: false,
                                  child: Text('Create teams after inviting'),
                                ),
                              ]
                            : [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('No team (optional)'),
                                ),
                                ..._teams.map((team) {
                                  return DropdownMenuItem<String>(
                                    value: team.id,
                                    child: Text(team.name),
                                  );
                                }),
                              ],
                        onChanged: _teams.isEmpty 
                            ? null
                            : (value) {
                                setState(() {
                                  selectedTeamId = value;
                                });
                              },
                      ),
                    ),
                    if (_teams.isEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip: You can organize members into teams after they join',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: emailController.text.trim().isEmpty || selectedRoleType == null
                            ? null
                            : () async {
                                try {
                                  await _invitationService.inviteMembers(
                                    email: emailController.text.trim(),
                                    teamId: selectedTeamId,
                                    roleType: selectedRoleType, // Backend will find/create role by type
                                  );
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invitation sent')),
                                    );
                                    _loadData(); // Refresh data
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to send invitation: $e')),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: Text(
                          'Send Invite',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0d2818),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _company?.name ?? 'Company',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (_company != null)
                              Text(
                                '${_company!.industry ?? "Company"} • ${_membersData?.members.length ?? 0} members',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          // Navigate to settings
                        },
                      ),
                    ],
                  ),
                ),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'People'),
                      Tab(text: 'Teams'),
                      Tab(text: 'Structure'),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Error loading data',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _loadData,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              key: ValueKey('${_teams.length}-${_membersData?.members.length ?? 0}'), // Force rebuild when data changes
                              children: [
                                if (_membersData != null && _company != null)
                                  PeopleTab(
                                    key: ValueKey('people-${_membersData!.members.length}'),
                                    membersData: _membersData!,
                                    stats: _company!.stats ?? CompanyStats(
                                      totalMembers: 0,
                                      unassignedMembers: 0,
                                      totalTeams: 0,
                                      totalDepartments: 0,
                                    ),
                                    onInviteMember: (_) => _handleInviteMember(),
                                    onMemberTap: (user) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UserDetailPage(user: user),
                                        ),
                                      );
                                    },
                                    onMemberMenuTap: (user) {
                                      // Show member menu
                                    },
                                  )
                                else
                                  const Center(child: Text('Loading...', style: TextStyle(color: Colors.white))),
                                TeamsTab(
                                  key: ValueKey('teams-${_teams.length}'),
                                  teams: _teams,
                                  unassignedCount: _membersData?.unassignedCount ?? 0,
                                  onTeamTap: (team) {
                                    // Navigate to team detail
                                  },
                                  onTeamLongPress: (team) {
                                    // Show team menu
                                  },
                                  onCreateTeam: _handleCreateTeam,
                                  onCreateTeamFromUnassigned: (members) {
                                    _handleCreateTeam();
                                  },
                                ),
                                StructureTab(
                                  key: ValueKey('structure-${_departments.length}'),
                                  departments: _departments,
                                  unassignedCount: _membersData?.unassignedCount ?? 0,
                                  onCreateDepartment: ({String? parentDepartmentId}) {
                                    _handleCreateDepartment(parentDepartmentId: parentDepartmentId);
                                  },
                                  onDepartmentTap: (dept) {
                                    // Could navigate to department detail page
                                  },
                                  onDepartmentLongPress: (dept) {
                                    _showDepartmentContextMenu(dept);
                                  },
                                ),
                              ],
                            ),
                ),
              ],
            ),

            // FAB
            if (_currentTab == 0)
              Positioned(
                right: 24,
                bottom: 100,
                child: FloatingActionButton(
                  onPressed: _handleInviteMember,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.person_add, color: Color(0xFF0d2818)),
                ),
              )
            else if (_currentTab == 1)
              Positioned(
                right: 24,
                bottom: 100,
                child: FloatingActionButton(
                  onPressed: _handleCreateTeam,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.group_add, color: Color(0xFF0d2818)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
