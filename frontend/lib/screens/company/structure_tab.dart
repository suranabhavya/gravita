import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/department_model.dart';
import '../../widgets/glass_container.dart';

class StructureTab extends StatefulWidget {
  final List<DepartmentTree> departments;
  final int unassignedCount;
  final VoidCallback onCreateDepartment;

  const StructureTab({
    super.key,
    required this.departments,
    required this.unassignedCount,
    required this.onCreateDepartment,
  });

  @override
  State<StructureTab> createState() => _StructureTabState();
}

class _StructureTabState extends State<StructureTab> {
  bool _isTreeView = true;
  final Map<String, bool> _expandedDepartments = {};

  void _toggleDepartment(String departmentId) {
    setState(() {
      _expandedDepartments[departmentId] = !(_expandedDepartments[departmentId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Structure',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Tree', _isTreeView, () {
                      setState(() => _isTreeView = true);
                    }),
                    _buildToggleButton('Grid', !_isTreeView, () {
                      setState(() => _isTreeView = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isTreeView ? _buildTreeView() : _buildGridView(),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTreeView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Company Hierarchy',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.departments.map((dept) => _buildDepartmentTree(dept)),
        if (widget.unassignedCount > 0) ...[
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Unassigned: ${widget.unassignedCount} people',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Group teams into departments?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onCreateDepartment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Create Department',
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
    );
  }

  Widget _buildDepartmentTree(DepartmentTree dept, {int level = 0}) {
    final isExpanded = _expandedDepartments[dept.id] ?? false;
    final hasChildren = dept.children.isNotEmpty || dept.teams.isNotEmpty;
    final hasSubDepartments = dept.children.isNotEmpty;
    final hasTeams = dept.teams.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: hasChildren ? () => _toggleDepartment(dept.id) : null,
          child: Container(
            padding: EdgeInsets.only(left: level * 24.0, top: 8, bottom: 8),
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  )
                else
                  const SizedBox(width: 20),
                Icon(
                  Icons.business,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (dept.managerName != null)
                        Text(
                          '${dept.managerName}, Manager',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      if (dept.teamCount > 0 || dept.memberCount > 0)
                        Text(
                          '${dept.teamCount} teams • ${dept.memberCount} members',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasChildren)
                  Text(
                    'Tap to expand',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          // Show teams first
          if (hasTeams) ...[
            ...dept.teams.map((team) => Container(
              padding: EdgeInsets.only(left: (level + 1) * 24.0 + 20, top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.group_work,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      team.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  if (team.location != null)
                    Text(
                      team.location!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${team.memberCount} members',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
          // Show sub-departments
          if (hasSubDepartments) ...[
            ...dept.children.map((child) => _buildDepartmentTree(child, level: level + 1)),
          ],
        ],
      ],
    );
  }

  Widget _buildGridView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Departments (${widget.departments.length})',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: widget.departments.length,
          itemBuilder: (context, index) {
            final dept = widget.departments[index];
            return GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dept.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (dept.managerName != null)
                    Text(
                      dept.managerName!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  Text(
                    '${dept.teamCount} teams • ${dept.memberCount} members',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

