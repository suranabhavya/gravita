import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';
import '../../services/api_service.dart';

class BulkInviteScreen extends StatefulWidget {
  const BulkInviteScreen({Key? key}) : super(key: key);

  @override
  State<BulkInviteScreen> createState() => _BulkInviteScreenState();
}

class _BulkInviteScreenState extends State<BulkInviteScreen> {
  final TextEditingController _emailsController = TextEditingController();
  String? _selectedRole = 'member';
  String? _selectedTeamId;
  bool _isLoading = false;
  List<String> _validEmails = [];
  List<String> _invalidEmails = [];

  final List<Map<String, String>> _roles = [
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'manager', 'label': 'Manager'},
    {'value': 'lead', 'label': 'Team Lead'},
    {'value': 'member', 'label': 'Member'},
  ];

  @override
  void dispose() {
    _emailsController.dispose();
    super.dispose();
  }

  void _validateEmails() {
    final text = _emailsController.text;
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    final valid = <String>[];
    final invalid = <String>[];
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    for (final line in lines) {
      final email = line.trim();
      if (emailRegex.hasMatch(email)) {
        valid.add(email);
      } else {
        invalid.add(email);
      }
    }
    
    setState(() {
      _validEmails = valid;
      _invalidEmails = invalid;
    });
  }

  Future<void> _sendInvitations() async {
    _validateEmails();
    
    if (_validEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_invalidEmails.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid Emails Detected'),
          content: Text(
            '${_invalidEmails.length} invalid email(s) will be skipped:\n\n${_invalidEmails.join('\n')}\n\nProceed with ${_validEmails.length} valid email(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      
      if (proceed != true) return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.post(
        '/invitations',
        {
          'emails': _validEmails,
          'roleType': _selectedRole,
          if (_selectedTeamId != null) 'teamId': _selectedTeamId,
        },
        includeAuth: true,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully sent ${_validEmails.length} invitation(s)'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to send invitations');
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
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final canManage = permissionProvider.canManageStructure;

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bulk Invite'),
        ),
        body: const Center(
          child: Text('You don\'t have permission to invite members'),
        ),
      );
    }

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
          'Bulk Invite Members',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
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
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter one email address per line. Invalid emails will be highlighted.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email Input
              Text(
                'Email Addresses',
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
                child: TextField(
                  controller: _emailsController,
                  maxLines: 10,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'rajesh@example.com\npriya@example.com\nsandeep@example.com',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (_) => _validateEmails(),
                ),
              ),
              const SizedBox(height: 8),
              if (_validEmails.isNotEmpty || _invalidEmails.isNotEmpty)
                Text(
                  '${_validEmails.length} valid, ${_invalidEmails.length} invalid',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _invalidEmails.isEmpty ? Colors.green : Colors.orange,
                  ),
                ),
              const SizedBox(height: 24),

              // Role Selection
              Text(
                'Assign Role',
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
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1a4d2e),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    items: _roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role['value'],
                        child: Text(role['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRole = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Team Selection (Optional)
              Text(
                'Assign to Team (Optional)',
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
                    value: _selectedTeamId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1a4d2e),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hint: Text(
                      'No team (unassigned)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No team (unassigned)'),
                      ),
                      // TODO: Load teams from API
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTeamId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendInvitations,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          'Send Invitations',
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
    );
  }
}

