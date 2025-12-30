import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/team_model.dart';
import '../models/department_model.dart';
import '../models/user_model.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/team_card.dart';

class CreateDepartmentBottomSheet extends StatefulWidget {
  final List<TeamListItem> availableTeams;
  final List<DepartmentTree> existingDepartments;
  final List<User> availableManagers;
  final String? initialParentDepartmentId;

  final Function({
    required String name,
    String? description,
    String? parentDepartmentId,
    String? managerId,
    required List<String> teamIds,
  }) onSubmit;

  const CreateDepartmentBottomSheet({
    super.key,
    required this.availableTeams,
    required this.existingDepartments,
    required this.availableManagers,
    this.initialParentDepartmentId,
    required this.onSubmit,
  });

  @override
  State<CreateDepartmentBottomSheet> createState() => _CreateDepartmentBottomSheetState();
}

class _CreateDepartmentBottomSheetState extends State<CreateDepartmentBottomSheet> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  // Step 1: Department Details
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedParentDepartmentId;

  @override
  void initState() {
    super.initState();
    _selectedParentDepartmentId = widget.initialParentDepartmentId;
  }
  
  // Step 2: Select Teams
  final Set<String> _selectedTeamIds = {};
  
  // Step 3: Assign Manager (optional)
  String? _selectedManagerId;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a department name')),
      );
      return;
    }
    if (_currentStep == 1 && _selectedTeamIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one team')),
      );
      return;
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _submit() {
    widget.onSubmit(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      parentDepartmentId: _selectedParentDepartmentId,
      managerId: _selectedManagerId,
      teamIds: _selectedTeamIds.toList(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFF0d2818),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Create Department',
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
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < 2)
                        Container(
                          width: 8,
                          height: 3,
                          color: index < _currentStep
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Step ${_currentStep + 1} of 3: ${_getStepTitle(_currentStep)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          // Footer buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentStep == 2 ? 'Create Department' : 'Next',
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
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Department Details';
      case 1:
        return 'Select Teams';
      case 2:
        return 'Assign Manager';
      default:
        return '';
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassTextField(
            label: 'Department Name',
            controller: _nameController,
            hintText: 'e.g., Operations, Sales, Engineering',
          ),
          const SizedBox(height: 20),
          GlassTextField(
            label: 'Description (optional)',
            controller: _descriptionController,
            hintText: 'Describe what this department does...',
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 20),
          // Parent Department Selection
          if (widget.existingDepartments.isNotEmpty) ...[
            Text(
              'Parent Department (optional)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedParentDepartmentId,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1a4d2e),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                ),
                hint: Text(
                  'None (Top-level department)',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None (Top-level department)'),
                  ),
                  ..._buildDepartmentOptions(widget.existingDepartments),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedParentDepartmentId = value;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDepartmentOptions(List<DepartmentTree> departments, {int level = 0}) {
    final items = <DropdownMenuItem<String>>[];
    for (final dept in departments) {
      final prefix = '  ' * level;
      items.add(
        DropdownMenuItem<String>(
          value: dept.id,
          child: Text('$prefix${dept.name}'),
        ),
      );
      if (dept.children.isNotEmpty) {
        items.addAll(_buildDepartmentOptions(dept.children, level: level + 1));
      }
    }
    return items;
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Select teams to include',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.availableTeams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_work_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No teams available',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create teams first to add them to departments',
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
                  itemCount: widget.availableTeams.length,
                  itemBuilder: (context, index) {
                    final team = widget.availableTeams[index];
                    final isSelected = _selectedTeamIds.contains(team.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: TeamCard(
                        team: team,
                        isSelected: isSelected,
                        showCheckbox: true,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTeamIds.remove(team.id);
                            } else {
                              _selectedTeamIds.add(team.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${_selectedTeamIds.length} team${_selectedTeamIds.length != 1 ? 's' : ''} selected',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Choose a department manager (optional)',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'You can skip this and assign a manager later',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.availableManagers.isEmpty
              ? Center(
                  child: Text(
                    'No managers available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: widget.availableManagers.length + 1, // +1 for "None" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedManagerId == null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(
                            Icons.person_off,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          title: Text(
                            'No Manager',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Assign later',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.white)
                              : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.white70),
                          onTap: () {
                            setState(() {
                              _selectedManagerId = null;
                            });
                          },
                        ),
                      );
                    }
                    final manager = widget.availableManagers[index - 1];
                    final isSelected = _selectedManagerId == manager.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            manager.name.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          manager.name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          manager.email,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.white)
                            : const Icon(Icons.radio_button_unchecked,
                                color: Colors.white70),
                        onTap: () {
                          setState(() {
                            _selectedManagerId = manager.id;
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

