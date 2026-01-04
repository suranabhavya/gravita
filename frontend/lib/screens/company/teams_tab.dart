import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../widgets/team_card.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/permission_gate.dart';

class TeamsTab extends StatelessWidget {
  final List<TeamListItem> teams;
  final int unassignedCount;
  final Function(TeamListItem) onTeamTap;
  final Function(TeamListItem) onTeamLongPress;
  final VoidCallback onCreateTeam;
  final Function(List<User>) onCreateTeamFromUnassigned;

  const TeamsTab({
    super.key,
    required this.teams,
    required this.unassignedCount,
    required this.onTeamTap,
    required this.onTeamLongPress,
    required this.onCreateTeam,
    required this.onCreateTeamFromUnassigned,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (unassignedCount > 0) ...[
          GlassContainer(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$unassignedCount people without teams',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PermissionGate(
                  permission: 'manage_structure',
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onCreateTeamFromUnassigned([]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Create Team from Unassigned',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0d2818),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Teams (${teams.length})',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Select',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_work_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No teams yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first team to get started',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return TeamCard(
                      team: team,
                      onTap: () => onTeamTap(team),
                      onLongPress: () => onTeamLongPress(team),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

