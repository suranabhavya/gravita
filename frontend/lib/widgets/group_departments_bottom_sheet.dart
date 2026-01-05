import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/department_model.dart';
import '../models/user_model.dart';
import '../widgets/glass_text_field.dart';

class GroupDepartmentsBottomSheet extends StatefulWidget {
  final List<DepartmentTree> selectedDepartments;
  final List<User> availableManagers;
  final Function({
    required String name,
    String? description,
    String? managerId,
    required List<String> departmentIds,
  }) onSubmit;

  const GroupDepartmentsBottomSheet({
    super.key,
    required this.selectedDepartments,
    required this.availableManagers,
    required this.onSubmit,
  });

  @override
  State<GroupDepartmentsBottomSheet> createState() =>
      _GroupDepartmentsBottomSheetState();
}

class _GroupDepartmentsBottomSheetState
    extends State<GroupDepartmentsBottomSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedManagerId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a department name')),
      );
      return;
    }

    widget.onSubmit(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      managerId: _selectedManagerId,
      departmentIds: widget.selectedDepartments.map((d) => d.id).toList(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0d2818),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  'Create Parent Department',
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
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show departments being grouped
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'You\'re grouping:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...widget.selectedDepartments.map((dept) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dept.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Department name
                  GlassTextField(
                    label: 'Parent Department Name',
                    controller: _nameController,
                    hintText: 'e.g., Regional Operations, All Dealers',
                  ),
                  const SizedBox(height: 20),
                  // Description
                  GlassTextField(
                    label: 'Description (optional)',
                    controller: _descriptionController,
                    hintText: 'Describe this parent department...',
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 20),
                  // Manager selection
                  Text(
                    'Assign Department Manager (optional)',
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
                      value: _selectedManagerId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF1a4d2e),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      hint: Text(
                        'Select Manager',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Manager (assign later)'),
                        ),
                        ...widget.availableManagers.map((manager) {
                          return DropdownMenuItem<String>(
                            value: manager.id,
                            child: Text('${manager.name} (${manager.email})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedManagerId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info message about current managers
                  if (widget.selectedDepartments
                      .any((d) => d.managerName != null))
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Current managers (${widget.selectedDepartments.where((d) => d.managerName != null).map((d) => d.managerName).join(', ')}) will report to this new manager',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Footer button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
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
          ),
        ],
      ),
    );
  }
}
