import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'create_team_from_members_screen.dart';

class UnassignedMembersScreen extends StatefulWidget {
  const UnassignedMembersScreen({Key? key}) : super(key: key);

  @override
  State<UnassignedMembersScreen> createState() => _UnassignedMembersScreenState();
}

class _UnassignedMembersScreenState extends State<UnassignedMembersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _unassignedMembers = [];
  Set<String> _selectedMemberIds = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUnassignedMembers();
  }

  Future<void> _loadUnassignedMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get(
        '/teams/unassigned-members',
        includeAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _unassignedMembers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load unassigned members');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedMemberIds.length == _unassignedMembers.length) {
        _selectedMemberIds.clear();
      } else {
        _selectedMemberIds = _unassignedMembers.map((m) => m['id'] as String).toSet();
      }
    });
  }

  void _createTeamFromSelected() {
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTeamFromMembersScreen(
          selectedMemberIds: _selectedMemberIds.toList(),
          members: _unassignedMembers
              .where((m) => _selectedMemberIds.contains(m['id']))
              .toList(),
        ),
      ),
    ).then((created) {
      if (created == true) {
        _loadUnassignedMembers(); // Refresh list
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final canManage = permissionProvider.canManageStructure;

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Unassigned Members'),
        ),
        body: const Center(
          child: Text('You don\'t have permission to manage members'),
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
          'Unassigned Members',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_unassignedMembers.isNotEmpty)
            TextButton.icon(
              onPressed: _selectAll,
              icon: Icon(
                _selectedMemberIds.length == _unassignedMembers.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: Colors.white,
              ),
              label: Text(
                _selectedMemberIds.length == _unassignedMembers.length
                    ? 'Deselect All'
                    : 'Select All',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading members',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUnassignedMembers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _unassignedMembers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'All members are assigned!',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No unassigned members found',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Info Banner
                        if (_unassignedMembers.length >= 3)
                          Container(
                            margin: const EdgeInsets.all(16),
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
                                const Icon(Icons.lightbulb_outline, color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You have ${_unassignedMembers.length} unassigned members. Consider creating a team!',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Member List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _unassignedMembers.length,
                            itemBuilder: (context, index) {
                              final member = _unassignedMembers[index];
                              final isSelected = _selectedMemberIds.contains(member['id']);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    child: Text(
                                      member['name']?[0]?.toUpperCase() ?? '?',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    member['name'] ?? 'Unknown',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    member['email'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleSelection(member['id']),
                                    activeColor: Colors.green,
                                  ),
                                  onTap: () => _toggleSelection(member['id']),
                                ),
                              );
                            },
                          ),
                        ),

                        // Bottom Action Bar
                        if (_selectedMemberIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_selectedMemberIds.length} selected',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Create a team from selected members',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: _createTeamFromSelected,
                                    icon: const Icon(Icons.group_add),
                                    label: const Text('Create Team'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4ade80),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}


