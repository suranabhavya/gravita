import 'package:flutter/material.dart';
import 'base_company_page.dart';

/// Member Company Page - Limited access
class MemberCompanyPage extends BaseCompanyPage {
  const MemberCompanyPage({super.key});

  @override
  State<MemberCompanyPage> createState() => _MemberCompanyPageState();
}

class _MemberCompanyPageState extends BaseCompanyPageState<MemberCompanyPage> {
  @override
  int get tabCount => 2; // People, Teams (no Structure)

  @override
  List<String> get tabLabels => const ['People', 'Teams'];

  @override
  bool get showSettingsIcon => false; // Member cannot access settings

  @override
  bool get showInviteFAB => false; // Member cannot invite

  @override
  bool get showCreateTeamFAB => false; // Member cannot create teams

  @override
  bool get showStructureTab => false; // Member cannot view structure
}

