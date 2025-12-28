import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/member_card.dart';

class CreateTeamBottomSheet extends StatefulWidget {
  final List<User> availableMembers;
  final Function({
    required String name,
    String? description,
    String? location,
    required List<String> memberIds,
    String? teamLeadId,
  }) onSubmit;

  const CreateTeamBottomSheet({
    super.key,
    required this.availableMembers,
    required this.onSubmit,
  });

  @override
  State<CreateTeamBottomSheet> createState() => _CreateTeamBottomSheetState();
}

class _CreateTeamBottomSheetState extends State<CreateTeamBottomSheet> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  // Step 1: Select Members
  final Set<String> _selectedMemberIds = {};
  
  // Step 2: Team Details
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Step 3: Assign Team Lead
  String? _selectedTeamLeadId;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }
    if (_currentStep == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team name')),
      );
      return;
    }
    if (_currentStep == 2 && _selectedTeamLeadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team lead')),
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
    // Don't close the sheet here - let the parent handle it after async operation
    widget.onSubmit(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      memberIds: _selectedMemberIds.toList(),
      teamLeadId: _selectedTeamLeadId,
    );
    // Note: Navigator.pop() is now handled in the parent after async operation completes
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
                  'Create Team',
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
                      _currentStep == 2 ? 'Create Team' : 'Next',
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
        return 'Select Members';
      case 1:
        return 'Team Details';
      case 2:
        return 'Assign Team Lead';
      default:
        return '';
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Select unassigned members',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: widget.availableMembers.length,
            itemBuilder: (context, index) {
              final member = widget.availableMembers[index];
              final isSelected = _selectedMemberIds.contains(member.id);
              return MemberCard(
                user: member,
                isSelected: isSelected,
                showCheckbox: true,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedMemberIds.remove(member.id);
                    } else {
                      _selectedMemberIds.add(member.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${_selectedMemberIds.length} selected',
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

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassTextField(
            label: 'Team Name',
            controller: _nameController,
            hintText: 'e.g., Boston Warehouse Team',
          ),
          const SizedBox(height: 20),
          GlassTextField(
            label: 'Location (optional)',
            controller: _locationController,
            hintText: 'e.g., Boston, MA',
          ),
          const SizedBox(height: 20),
          GlassTextField(
            label: 'Description (optional)',
            controller: _descriptionController,
            hintText: 'Describe what this team does...',
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final selectedMembers = widget.availableMembers
        .where((m) => _selectedMemberIds.contains(m.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Choose a team lead from members',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: selectedMembers.length,
            itemBuilder: (context, index) {
              final member = selectedMembers[index];
              final isSelected = _selectedTeamLeadId == member.id;
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
                      member.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    member.email,
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
                      _selectedTeamLeadId = member.id;
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

