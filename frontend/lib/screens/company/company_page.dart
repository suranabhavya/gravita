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
import 'people_tab.dart';
import 'teams_tab.dart';
import 'structure_tab.dart';

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
            await _teamService.createTeam(
              name: name,
              description: description,
              location: location,
              memberIds: memberIds,
              teamLeadId: teamLeadId,
            );
            _loadData();
            if (mounted) {
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
    final emails = <String>[];

    return StatefulBuilder(
      builder: (context, setState) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                    'Invite Member',
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
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Email addresses',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...emails.map((email) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                email,
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                              onPressed: () {
                                setState(() => emails.remove(email));
                              },
                            ),
                          ],
                        ),
                      )),
                  TextField(
                    controller: emailController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter email address',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          if (emailController.text.isNotEmpty &&
                              emailController.text.contains('@')) {
                            setState(() {
                              emails.add(emailController.text.trim());
                              emailController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty && value.contains('@')) {
                        setState(() {
                          emails.add(value.trim());
                          emailController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: emails.isEmpty
                    ? null
                    : () async {
                        try {
                          await _invitationService.inviteMembers(emails: emails);
                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invitations sent')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send invitations: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text(
                  'Send Invitations',
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
                              children: [
                                if (_membersData != null && _company != null)
                                  PeopleTab(
                                    membersData: _membersData!,
                                    stats: _company!.stats ?? CompanyStats(
                                      totalMembers: 0,
                                      unassignedMembers: 0,
                                      totalTeams: 0,
                                      totalDepartments: 0,
                                    ),
                                    onInviteMember: (_) => _handleInviteMember(),
                                    onMemberTap: (user) {
                                      // Navigate to user detail
                                    },
                                    onMemberMenuTap: (user) {
                                      // Show member menu
                                    },
                                  )
                                else
                                  const Center(child: Text('Loading...', style: TextStyle(color: Colors.white))),
                                TeamsTab(
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
                                  departments: _departments,
                                  unassignedCount: _membersData?.unassignedCount ?? 0,
                                  onCreateDepartment: () {
                                    // Show create department sheet
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
