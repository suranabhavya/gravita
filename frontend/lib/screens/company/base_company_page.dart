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
import '../../widgets/glass_text_field.dart';
import '../../widgets/glass_container.dart';
import 'people_tab.dart';
import 'teams_tab.dart';
import 'structure_tab.dart';
import 'user_detail_page.dart';

/// Base class for role-specific company pages
/// Contains shared data loading and business logic
abstract class BaseCompanyPage extends StatefulWidget {
  const BaseCompanyPage({super.key});
}

abstract class BaseCompanyPageState<T extends BaseCompanyPage> extends State<T> with TickerProviderStateMixin {
  TabController? _tabController;
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

  // Override these in subclasses to customize behavior
  int get tabCount;
  List<String> get tabLabels;
  bool get showSettingsIcon;
  bool get showInviteFAB;
  bool get showCreateTeamFAB;
  bool get showStructureTab;

  @override
  void initState() {
    super.initState();
    _initTabController();
    _loadData();
  }

  void _initTabController() {
    _tabController = TabController(length: tabCount, vsync: this);
    _tabController!.addListener(() {
      if (mounted) {
        setState(() => _currentTab = _tabController!.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
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

    final availableManagers = _membersData?.members ?? [];
    final parentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(parentContext);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => CreateDepartmentBottomSheet(
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
            Navigator.of(bottomSheetContext).pop();
            await _departmentService.createDepartment(
              name: name,
              description: description,
              parentDepartmentId: parentDepartmentId,
              managerId: managerId,
              teamIds: teamIds,
            );
            await _loadData();
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 100));
              if (_tabController != null && _tabController!.index != tabCount - 1) {
                _tabController!.animateTo(tabCount - 1);
              }
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Department created successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
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

  Future<void> _handleCreateTeam() async {
    if (_membersData == null) return;

    final unassignedMembers = _membersData!.members
        .where((m) => m.isUnassigned)
        .toList();

    final parentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(parentContext);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => CreateTeamBottomSheet(
        availableMembers: unassignedMembers,
        onSubmit: ({
          required String name,
          String? description,
          String? location,
          required List<String> memberIds,
          String? teamLeadId,
        }) async {
          try {
            Navigator.of(bottomSheetContext).pop();
            await _teamService.createTeam(
              name: name,
              description: description,
              location: location,
              memberIds: memberIds,
              teamLeadId: teamLeadId,
            );
            await _loadData();
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 100));
              if (_tabController != null && _tabController!.index != 1) {
                _tabController!.animateTo(1);
              }
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Team created successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Failed to create team: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildInviteMemberSheet() {
    return _InviteMemberSheetContent(
      onInvite: (emails) async {
        try {
          await _invitationService.inviteMembers(
            emails: emails,
            teamId: null, // No team assignment
            roleType: 'member', // Default to member role
          );
          if (mounted) {
            Navigator.of(context).pop();
            final count = emails.length;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  count == 1 
                      ? 'Invitation sent' 
                      : '$count invitations sent',
                ),
              ),
            );
            _loadData();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send invitation: $e')),
            );
          }
        }
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
                      if (showSettingsIcon)
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                        ),
                    ],
                  ),
                ),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: _tabController == null
                      ? const SizedBox.shrink()
                      : TabBar(
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
                          tabs: tabLabels.map((label) => Tab(text: label)).toList(),
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
                          : _tabController == null
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : TabBarView(
                                  controller: _tabController,
                                  key: ValueKey('${_teams.length}-${_membersData?.members.length ?? 0}'),
                                  children: buildTabViews(),
                                ),
                ),
              ],
            ),

            // FABs
            if (showInviteFAB && _currentTab == 0)
              Positioned(
                right: 24,
                bottom: 100,
                child: FloatingActionButton(
                  onPressed: _handleInviteMember,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.person_add, color: Color(0xFF0d2818)),
                ),
              ),
            if (showCreateTeamFAB && _currentTab == 1)
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

  List<Widget> buildTabViews() {
    final views = <Widget>[];
    
    // People tab
    if (_membersData != null && _company != null) {
      views.add(
        PeopleTab(
          key: ValueKey('people-${_membersData!.members.length}'),
          membersData: _membersData!,
          stats: _company!.stats ?? CompanyStats(
            totalMembers: 0,
            unassignedMembers: 0,
            totalTeams: 0,
            totalDepartments: 0,
          ),
          onInviteMember: showInviteFAB ? (_) => _handleInviteMember() : (_) {},
          onMemberTap: (user) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailPage(user: user),
              ),
            );
          },
          onMemberMenuTap: (user) {},
        ),
      );
    } else {
      views.add(const Center(child: Text('Loading...', style: TextStyle(color: Colors.white))));
    }

    // Teams tab
    views.add(
      TeamsTab(
        key: ValueKey('teams-${_teams.length}-${_teams.map((t) => t.id).join(',')}'),
        teams: _teams,
        unassignedCount: _membersData?.unassignedCount ?? 0,
        onTeamTap: (team) {},
        onTeamLongPress: (team) {},
        onCreateTeam: showCreateTeamFAB ? _handleCreateTeam : () {},
        onCreateTeamFromUnassigned: (members) {
          if (showCreateTeamFAB) {
            _handleCreateTeam();
          }
        },
      ),
    );

    // Structure tab (if applicable)
    if (showStructureTab) {
      views.add(
        StructureTab(
          key: ValueKey('structure-${_departments.length}'),
          departments: _departments,
          unassignedCount: _membersData?.unassignedCount ?? 0,
          onCreateDepartment: ({String? parentDepartmentId}) {
            _handleCreateDepartment(parentDepartmentId: parentDepartmentId);
          },
          onDepartmentTap: (dept) {},
          onDepartmentLongPress: (dept) {},
        ),
      );
    }

    return views;
  }
}

class _InviteMemberSheetContent extends StatefulWidget {
  final Function(List<String>) onInvite;

  const _InviteMemberSheetContent({
    required this.onInvite,
  });

  @override
  State<_InviteMemberSheetContent> createState() => _InviteMemberSheetContentState();
}

class _InviteMemberSheetContentState extends State<_InviteMemberSheetContent> {
  final List<TextEditingController> _emailControllers = [TextEditingController()];

  @override
  void dispose() {
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEmailField() {
    setState(() {
      final newController = TextEditingController();
      newController.addListener(() {
        if (mounted) {
          setState(() {}); // Rebuild when text changes
        }
      });
      _emailControllers.add(newController);
    });
  }

  void _removeEmailField(int index) {
    if (_emailControllers.length > 1) {
      setState(() {
        _emailControllers[index].dispose();
        _emailControllers.removeAt(index);
      });
    }
  }

  List<String> _getValidEmails() {
    final emails = <String>[];
    for (var controller in _emailControllers) {
      final email = controller.text.trim();
      if (email.isNotEmpty && email.contains('@')) {
        emails.add(email);
      }
    }
    return emails;
  }

  @override
  Widget build(BuildContext context) {
    final validEmails = _getValidEmails();
    final hasValidEmails = validEmails.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0d2818),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite Team Members',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All invited members will join as Team Members. You can change their roles later.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(_emailControllers.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < _emailControllers.length - 1 ? 24 : 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GlassTextField(
                                hintText: 'team.member@example.com',
                                controller: _emailControllers[index],
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            if (_emailControllers.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: GlassContainer(
                                  width: 48,
                                  height: 48,
                                  isCircular: true,
                                  padding: EdgeInsets.zero,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _removeEmailField(index),
                                      borderRadius: BorderRadius.circular(24),
                                      child: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    _buildAddEmailButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GlassContainer(
                    width: double.infinity,
                    height: 56,
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFF22c55e),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: hasValidEmails
                            ? () {
                                print('[InviteMember] Sending ${validEmails.length} invitations: $validEmails');
                                widget.onInvite(validEmails);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            validEmails.isEmpty
                                ? 'Send Invite'
                                : validEmails.length == 1
                                    ? 'Send Invite'
                                    : 'Send ${validEmails.length} Invites',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEmailButton() {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addEmailField,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Another Email',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

