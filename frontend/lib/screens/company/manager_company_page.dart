import 'package:flutter/material.dart';
import 'base_company_page.dart';

/// Manager Company Page - Department scope access
class ManagerCompanyPage extends BaseCompanyPage {
  const ManagerCompanyPage({super.key});

  @override
  State<ManagerCompanyPage> createState() => _ManagerCompanyPageState();
}

class _ManagerCompanyPageState extends BaseCompanyPageState<ManagerCompanyPage> {
  @override
  int get tabCount => 3; // People, Teams, Structure (department scope)

  @override
  List<String> get tabLabels => const ['People', 'Teams', 'Structure'];

  @override
  bool get showSettingsIcon => false; // Manager cannot access settings

  @override
  bool get showInviteFAB => true; // Manager can invite to department

  @override
  bool get showCreateTeamFAB => true; // Manager can create teams in department

  @override
  bool get showStructureTab => true; // Manager can view structure (department scope)
}

