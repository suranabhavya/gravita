import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../models/team_model.dart';

class TeamCard extends StatelessWidget {
  final TeamListItem team;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showCheckbox;

  const TeamCard({
    super.key,
    required this.team,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showCheckbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.group_work,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            team.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (showCheckbox)
                          Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                      ],
                    ),
                    if (team.teamLeadName != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${team.teamLeadName} (Lead)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${team.memberCount} members',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 12),
                    if (team.location != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            team.location!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(
                          team.activeListingsCount > 0 ? Icons.check_circle : Icons.pause_circle,
                          size: 16,
                          color: team.activeListingsCount > 0
                              ? Colors.green.shade300
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          team.activeListingsCount > 0
                              ? '${team.activeListingsCount} active listings'
                              : 'No listings',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: team.activeListingsCount > 0
                                ? Colors.green.shade300
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

