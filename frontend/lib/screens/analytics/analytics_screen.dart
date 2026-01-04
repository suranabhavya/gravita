import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';
import '../../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  String? _error;

  ListingStats? _listingStats;
  TeamStats? _teamStats;
  MemberStats? _memberStats;
  ApprovalStats? _approvalStats;
  FinancialSummary? _financialSummary;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    final permissionContext = permissionProvider.context;

    if (permissionContext == null) {
      setState(() {
        _error = 'Permission context not available';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all analytics in parallel
      final results = await Future.wait([
        _analyticsService.getListingStats(permissionContext),
        _analyticsService.getTeamStats(permissionContext),
        _analyticsService.getMemberStats(permissionContext),
        _analyticsService.getApprovalStats(permissionContext),
        _analyticsService.getFinancialSummary(permissionContext),
      ]);

      setState(() {
        _listingStats = results[0] as ListingStats;
        _teamStats = results[1] as TeamStats;
        _memberStats = results[2] as MemberStats;
        _approvalStats = results[3] as ApprovalStats;
        _financialSummary = results[4] as FinancialSummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final permissionContext = permissionProvider.context;

    if (permissionContext == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final scopeDescription = AnalyticsScope.getScopeDescription(permissionContext);

    return Scaffold(
      backgroundColor: const Color(0xFF0d2818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              scopeDescription,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          if (AnalyticsScope.canExportAnalytics(permissionContext))
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalytics,
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
                        'Error loading analytics',
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
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Financial Summary
                        if (_financialSummary != null) ...[
                          _buildSectionTitle('Financial Overview'),
                          const SizedBox(height: 12),
                          _buildFinancialCard(_financialSummary!),
                          const SizedBox(height: 24),
                        ],

                        // Listing Stats
                        if (_listingStats != null) ...[
                          _buildSectionTitle('Listings'),
                          const SizedBox(height: 12),
                          _buildListingStatsCard(_listingStats!),
                          const SizedBox(height: 24),
                        ],

                        // Approval Stats (for approvers only)
                        if (permissionProvider.canApproveListings &&
                            _approvalStats != null) ...[
                          _buildSectionTitle('Approvals'),
                          const SizedBox(height: 12),
                          _buildApprovalStatsCard(_approvalStats!),
                          const SizedBox(height: 24),
                        ],

                        // Team Stats (for leads and above)
                        if (AnalyticsScope.canViewTeamAnalytics(permissionContext) &&
                            _teamStats != null) ...[
                          _buildSectionTitle('Team Overview'),
                          const SizedBox(height: 12),
                          _buildTeamStatsCard(_teamStats!),
                          const SizedBox(height: 24),
                        ],

                        // Member Stats (for managers and admins)
                        if (AnalyticsScope.canViewDepartmentAnalytics(permissionContext) &&
                            _memberStats != null) ...[
                          _buildSectionTitle('Members'),
                          const SizedBox(height: 12),
                          _buildMemberStatsCard(_memberStats!),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFinancialCard(FinancialSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ade80), Color(0xFF22c55e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Value',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.formatCurrency(summary.totalValue),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFinancialMetric(
                  'Approved',
                  summary.formatCurrency(summary.approvedValue),
                ),
              ),
              Expanded(
                child: _buildFinancialMetric(
                  'Pending',
                  summary.formatCurrency(summary.pendingValue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildListingStatsCard(ListingStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', stats.total, Colors.blue),
              ),
              Expanded(
                child: _buildStatItem('Draft', stats.draft, Colors.grey),
              ),
              Expanded(
                child: _buildStatItem('Pending', stats.pending, Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Approved', stats.approved, Colors.green),
              ),
              Expanded(
                child: _buildStatItem('Rejected', stats.rejected, Colors.red),
              ),
              Expanded(
                child: _buildStatItem('Listed', stats.listed, Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalStatsCard(ApprovalStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Pending', stats.pending, Colors.orange),
          ),
          Expanded(
            child: _buildStatItem('Approved', stats.approved, Colors.green),
          ),
          Expanded(
            child: _buildStatItem('Rejected', stats.rejected, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatsCard(TeamStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Teams', stats.totalTeams, Colors.blue),
          ),
          Expanded(
            child: _buildStatItem('Members', stats.totalMembers, Colors.green),
          ),
          Expanded(
            child: _buildStatItem('Unassigned', stats.unassignedMembers, Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStatsCard(MemberStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Total', stats.total, Colors.blue),
          ),
          Expanded(
            child: _buildStatItem('Active', stats.active, Colors.green),
          ),
          Expanded(
            child: _buildStatItem('Invited', stats.invited, Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}


