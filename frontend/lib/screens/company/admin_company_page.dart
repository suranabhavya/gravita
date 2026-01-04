import 'package:flutter/material.dart';
import 'base_company_page.dart';

/// Admin Company Page - Full access to all features
class AdminCompanyPage extends BaseCompanyPage {
  const AdminCompanyPage({super.key});

  @override
  State<AdminCompanyPage> createState() => _AdminCompanyPageState();
}

class _AdminCompanyPageState extends BaseCompanyPageState<AdminCompanyPage> {
  @override
  int get tabCount => 3; // People, Teams, Structure

  @override
  List<String> get tabLabels => const ['People', 'Teams', 'Structure'];

  @override
  bool get showSettingsIcon => true; // Admin can access settings

  @override
  bool get showInviteFAB => true; // Admin can invite members

  @override
  bool get showCreateTeamFAB => true; // Admin can create teams

  @override
  bool get showStructureTab => true; // Admin can view structure
}

