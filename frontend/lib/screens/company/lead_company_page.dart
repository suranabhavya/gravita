import 'package:flutter/material.dart';
import 'base_company_page.dart';

/// Lead Company Page - Team scope access
class LeadCompanyPage extends BaseCompanyPage {
  const LeadCompanyPage({super.key});

  @override
  State<LeadCompanyPage> createState() => _LeadCompanyPageState();
}

class _LeadCompanyPageState extends BaseCompanyPageState<LeadCompanyPage> {
  @override
  int get tabCount => 2; // People, Teams (no Structure)

  @override
  List<String> get tabLabels => const ['People', 'Teams'];

  @override
  bool get showSettingsIcon => false; // Lead cannot access settings

  @override
  bool get showInviteFAB => true; // Lead can invite to team

  @override
  bool get showCreateTeamFAB => false; // Lead cannot create teams

  @override
  bool get showStructureTab => false; // Lead cannot view structure
}

