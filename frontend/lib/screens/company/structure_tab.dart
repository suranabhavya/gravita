import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/department_model.dart';
import '../../widgets/glass_container.dart';

class StructureTab extends StatefulWidget {
  final List<DepartmentTree> departments;
  final int unassignedCount;
  final Function({String? parentDepartmentId}) onCreateDepartment;
  final Function(DepartmentTree department)? onDepartmentTap;
  final Function(DepartmentTree department)? onDepartmentLongPress;

  const StructureTab({
    super.key,
    required this.departments,
    required this.unassignedCount,
    required this.onCreateDepartment,
    this.onDepartmentTap,
    this.onDepartmentLongPress,
  });

  @override
  State<StructureTab> createState() => _StructureTabState();
}

class _StructureTabState extends State<StructureTab> {
  bool _isTreeView = true;
  final Map<String, bool> _expandedDepartments = {};
  
  // For compact view drill-down navigation
  String? _currentDepartmentId;
  List<DepartmentTree> _navigationStack = [];

  void _toggleDepartment(String departmentId) {
    setState(() {
      _expandedDepartments[departmentId] = !(_expandedDepartments[departmentId] ?? false);
    });
  }

  void _navigateToDepartment(DepartmentTree department) {
    setState(() {
      _navigationStack.add(department);
      _currentDepartmentId = department.id;
    });
  }


  void _navigateToBreadcrumb(int index) {
    setState(() {
      _navigationStack = _navigationStack.sublist(0, index + 1);
      _currentDepartmentId = _navigationStack.isNotEmpty ? _navigationStack.last.id : null;
    });
  }

  DepartmentTree? _findDepartmentById(String id, List<DepartmentTree> depts) {
    for (final dept in depts) {
      if (dept.id == id) return dept;
      final found = _findDepartmentById(id, dept.children);
      if (found != null) return found;
    }
    return null;
  }

  List<DepartmentTree> _getCurrentViewDepartments() {
    if (_currentDepartmentId == null) {
      return widget.departments;
    }
    
    final currentDept = _findDepartmentById(_currentDepartmentId!, widget.departments);
    return currentDept?.children ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View Toggle and Breadcrumb (in compact mode)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
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
                          setState(() {
                            _isTreeView = true;
                            _currentDepartmentId = null;
                            _navigationStack = [];
                          });
                        }),
                        _buildToggleButton('Compact', !_isTreeView, () {
                          setState(() {
                            _isTreeView = false;
                            _currentDepartmentId = null;
                            _navigationStack = [];
                          });
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              // Breadcrumb (only in compact mode)
              if (!_isTreeView && _navigationStack.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildBreadcrumb(),
              ],
            ],
          ),
        ),

        Expanded(
          child: _isTreeView ? _buildTreeView() : _buildCompactView(),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _currentDepartmentId = null;
                _navigationStack = [];
              });
            },
            child: Text(
              'Company Root',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          ...List.generate(_navigationStack.length, (index) {
            return Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  '›',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _navigateToBreadcrumb(index),
                  child: Text(
                    _navigationStack[index].name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
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
    final currentDepts = _currentDepartmentId == null 
        ? widget.departments 
        : _findDepartmentById(_currentDepartmentId!, widget.departments)?.children ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (_currentDepartmentId == null) ...[
          Text(
            'Company Hierarchy',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...currentDepts.map((dept) => _buildDepartmentTree(dept)),
        if (widget.unassignedCount > 0 && _currentDepartmentId == null) ...[
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
        if (_currentDepartmentId == null) ...[
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
                    onPressed: () => widget.onCreateDepartment(),
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
          onLongPress: widget.onDepartmentLongPress != null ? () => widget.onDepartmentLongPress!(dept) : null,
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
                          fontSize: level == 0 ? 16 : 15,
                          fontWeight: level == 0 ? FontWeight.w700 : FontWeight.w600,
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
                          '${dept.teamCount} depts • ${dept.memberCount} members',
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

  Widget _buildCompactView() {
    final currentDepts = _getCurrentViewDepartments();
    final currentDept = _currentDepartmentId != null
        ? _findDepartmentById(_currentDepartmentId!, widget.departments)
        : null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (currentDept != null) ...[
          // Department header
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentDept.name,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (currentDept.managerName != null)
                            Text(
                              '${currentDept.managerName}, Manager',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${currentDept.teamCount} departments • ${currentDept.memberCount} members',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Departments (${currentDept.children.length})',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Text(
            'Company Hierarchy',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Department cards
        ...currentDepts.map((dept) => _buildDepartmentCard(dept)),
        // Teams at current level
        if (currentDept != null && currentDept.teams.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Teams (${currentDept.teams.length})',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...currentDept.teams.map((team) => _buildTeamCard(team)),
        ],
        // Unassigned count (only at root)
        if (widget.unassignedCount > 0 && _currentDepartmentId == null) ...[
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
        // Create button
        if (_currentDepartmentId == null) ...[
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
                    onPressed: () => widget.onCreateDepartment(),
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
        ] else ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onCreateDepartment(parentDepartmentId: _currentDepartmentId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Add Department',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0d2818),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDepartmentCard(DepartmentTree dept) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => _navigateToDepartment(dept),
          onLongPress: widget.onDepartmentLongPress != null ? () => widget.onDepartmentLongPress!(dept) : null,
          child: Row(
            children: [
              Icon(
                Icons.business,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (dept.managerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${dept.managerName}, Manager',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${dept.teamCount} depts • ${dept.memberCount} members',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
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
        ),
      ),
    );
  }

  Widget _buildTeamCard(DepartmentTeam team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.group_work,
              color: Colors.white.withValues(alpha: 0.9),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (team.location != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      team.location!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${team.memberCount} members',
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
      ),
    );
  }
}
