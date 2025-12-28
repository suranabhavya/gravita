import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../widgets/member_card.dart';
import '../../widgets/glass_text_field.dart';

class PeopleTab extends StatefulWidget {
  final CompanyMembersResponse membersData;
  final CompanyStats stats;
  final Function(String) onInviteMember;
  final Function(User) onMemberTap;
  final Function(User) onMemberMenuTap;

  const PeopleTab({
    super.key,
    required this.membersData,
    required this.stats,
    required this.onInviteMember,
    required this.onMemberTap,
    required this.onMemberMenuTap,
  });

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTeamFilter;
  String? _selectedRoleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> get _filteredMembers {
    var members = widget.membersData.members;

    if (_searchQuery.isNotEmpty) {
      members = members
          .where((m) =>
              m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              m.email.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedTeamFilter != null && _selectedTeamFilter != 'all') {
      if (_selectedTeamFilter == 'unassigned') {
        members = members.where((m) => m.isUnassigned).toList();
      } else {
        members = members
            .where((m) => m.teams.any((t) => t.id == _selectedTeamFilter))
            .toList();
      }
    }

    return members;
  }

  Map<String, List<User>> get _groupedMembers {
    final grouped = <String, List<User>>{};
    final filtered = _filteredMembers;

    for (final member in filtered) {
      if (member.isUnassigned) {
        if (!grouped.containsKey('unassigned')) {
          grouped['unassigned'] = [];
        }
        grouped['unassigned']!.add(member);
      } else {
        for (final team in member.teams) {
          if (!grouped.containsKey(team.id)) {
            grouped[team.id] = [];
          }
          grouped[team.id]!.add(member);
        }
      }
    }

    return grouped;
  }

  List<String> get _availableTeams {
    final teams = <String>{};
    for (final member in widget.membersData.members) {
      for (final team in member.teams) {
        teams.add(team.id);
      }
    }
    return teams.toList();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedMembers;
    final unassigned = grouped['unassigned'] ?? [];
    final teamGroups = grouped.entries
        .where((e) => e.key != 'unassigned')
        .toList();

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassTextField(
            controller: _searchController,
            hintText: 'Search members...',
            suffixIcon: Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'All',
                  _selectedTeamFilter,
                  ['all', 'unassigned', ..._availableTeams],
                  (value) {
                    setState(() => _selectedTeamFilter = value == 'all' ? null : value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Role',
                  _selectedRoleFilter,
                  ['all'],
                  (value) {
                    setState(() => _selectedRoleFilter = value == 'all' ? null : value);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Members List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              if (unassigned.isNotEmpty) ...[
                _buildSectionHeader('Unassigned (${unassigned.length})'),
                const SizedBox(height: 12),
                ...unassigned.map((member) => MemberCard(
                      user: member,
                      onTap: () => widget.onMemberTap(member),
                      onMenuTap: () => widget.onMemberMenuTap(member),
                    )),
                const SizedBox(height: 24),
              ],
              ...teamGroups.map((group) {
                final teamId = group.key;
                final members = group.value;
                final teamName = members.first.teams
                    .firstWhere((t) => t.id == teamId)
                    .name;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('$teamName (${members.length})'),
                    const SizedBox(height: 12),
                    ...members.map((member) => MemberCard(
                          user: member,
                          onTap: () => widget.onMemberTap(member),
                          onMenuTap: () => widget.onMemberMenuTap(member),
                        )),
                    const SizedBox(height: 24),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButton<String>(
        value: value ?? 'all',
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF1a4d2e),
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option == 'all' ? label : option),
          );
        }).toList(),
        onChanged: (val) => onChanged(val),
      ),
    );
  }
}

