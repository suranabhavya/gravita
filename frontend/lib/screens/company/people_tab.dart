import 'package:flutter/material.dart';
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

    return members;
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _filteredMembers;

    return Column(
      children: [
        // Search bar with filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
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
              const SizedBox(width: 12),
              // Filter button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      // TODO: Implement filter functionality
                    },
                    child: Icon(
                      Icons.filter_list,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Members List
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: 24 + MediaQuery.of(context).padding.bottom + 91, // Bottom navbar (75px) + margin (16px) = 91px
            ),
            children: [
              ...filteredMembers.map((member) => MemberCard(
                    user: member,
                    onTap: () => widget.onMemberTap(member),
                    onMenuTap: () => widget.onMemberMenuTap(member),
                  )),
            ],
          ),
        ),
      ],
    );
  }

}

