import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class CreateTeamFromMembersScreen extends StatefulWidget {
  final List<String> selectedMemberIds;
  final List<Map<String, dynamic>> members;

  const CreateTeamFromMembersScreen({
    Key? key,
    required this.selectedMemberIds,
    required this.members,
  }) : super(key: key);

  @override
  State<CreateTeamFromMembersScreen> createState() =>
      _CreateTeamFromMembersScreenState();
}

class _CreateTeamFromMembersScreenState
    extends State<CreateTeamFromMembersScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _approvalLimitController = TextEditingController();

  String? _selectedTeamLeadId;
  bool _isLoading = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _approvalLimitController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = {
        'teamName': _teamNameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'memberUserIds': widget.selectedMemberIds,
        if (_selectedTeamLeadId != null) 'teamLeadUserId': _selectedTeamLeadId,
        if (_approvalLimitController.text.isNotEmpty)
          'teamLeadApprovalLimit': double.parse(_approvalLimitController.text),
      };

      final response = await ApiService.post(
        '/teams/from-members',
        body,
        includeAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to create team');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d2818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Team',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Members Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.members.length} members selected',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Team Name
                Text(
                  'Team Name *',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _teamNameController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., Mumbai Dealership',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Team name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Location
                Text(
                  'Location',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., Mumbai, India',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Brief description of the team...',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Team Lead Selection
                Text(
                  'Team Lead (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedTeamLeadId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1a4d2e),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hint: Text(
                        'Select a team lead',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No team lead'),
                        ),
                        ...widget.members.map((member) {
                          return DropdownMenuItem<String?>(
                            value: member['id'],
                            child: Text(member['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTeamLeadId = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Approval Limit (if team lead selected)
                if (_selectedTeamLeadId != null) ...[
                  Text(
                    'Team Lead Approval Limit (Optional)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _approvalLimitController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., 50000',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      prefixText: '\$ ',
                      prefixStyle: GoogleFonts.inter(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0) {
                          return 'Please enter a valid amount';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ade80),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            'Create Team',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

