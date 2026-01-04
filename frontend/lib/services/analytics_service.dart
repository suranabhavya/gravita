import 'dart:convert';
import 'api_service.dart';
import '../models/permission_context_model.dart';

/// Service for fetching analytics data with scope-based filtering
class AnalyticsService {
  /// Get analytics data based on user's scope
  /// - Admin: Company-wide analytics
  /// - Manager: Department analytics
  /// - Lead: Team analytics
  /// - Member: Personal analytics
  Future<Map<String, dynamic>> getAnalytics(PermissionContext context) async {
    final endpoint = _getAnalyticsEndpoint(context);
    
    final response = await ApiService.get(
      endpoint,
      includeAuth: true,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load analytics');
    }
  }

  /// Get the appropriate analytics endpoint based on scope
  String _getAnalyticsEndpoint(PermissionContext context) {
    switch (context.roleType) {
      case RoleType.admin:
        // Company-wide analytics
        return '/analytics/company';
      
      case RoleType.manager:
        // Department analytics (filtered by scope)
        if (context.scopeId != null) {
          return '/analytics/department/${context.scopeId}';
        }
        return '/analytics/company'; // Fallback
      
      case RoleType.lead:
        // Team analytics (filtered by scope)
        if (context.scopeId != null) {
          return '/analytics/team/${context.scopeId}';
        }
        return '/analytics/company'; // Fallback
      
      case RoleType.member:
        // Personal analytics
        return '/analytics/user/${context.userId}';
    }
  }

  /// Get listing statistics based on scope
  Future<ListingStats> getListingStats(PermissionContext context) async {
    try {
      final analytics = await getAnalytics(context);
      return ListingStats.fromJson(analytics['listings'] ?? {});
    } catch (e) {
      // Return empty stats on error
      return ListingStats.empty();
    }
  }

  /// Get team statistics based on scope
  Future<TeamStats> getTeamStats(PermissionContext context) async {
    try {
      final analytics = await getAnalytics(context);
      return TeamStats.fromJson(analytics['teams'] ?? {});
    } catch (e) {
      return TeamStats.empty();
    }
  }

  /// Get member statistics based on scope
  Future<MemberStats> getMemberStats(PermissionContext context) async {
    try {
      final analytics = await getAnalytics(context);
      return MemberStats.fromJson(analytics['members'] ?? {});
    } catch (e) {
      return MemberStats.empty();
    }
  }

  /// Get approval statistics based on scope
  Future<ApprovalStats> getApprovalStats(PermissionContext context) async {
    try {
      final analytics = await getAnalytics(context);
      return ApprovalStats.fromJson(analytics['approvals'] ?? {});
    } catch (e) {
      return ApprovalStats.empty();
    }
  }

  /// Get financial summary based on scope
  Future<FinancialSummary> getFinancialSummary(PermissionContext context) async {
    try {
      final analytics = await getAnalytics(context);
      return FinancialSummary.fromJson(analytics['financial'] ?? {});
    } catch (e) {
      return FinancialSummary.empty();
    }
  }
}

/// Listing statistics model
class ListingStats {
  final int total;
  final int draft;
  final int pending;
  final int approved;
  final int rejected;
  final int listed;

  ListingStats({
    required this.total,
    required this.draft,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.listed,
  });

  factory ListingStats.fromJson(Map<String, dynamic> json) {
    return ListingStats(
      total: json['total'] ?? 0,
      draft: json['draft'] ?? 0,
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
      listed: json['listed'] ?? 0,
    );
  }

  factory ListingStats.empty() {
    return ListingStats(
      total: 0,
      draft: 0,
      pending: 0,
      approved: 0,
      rejected: 0,
      listed: 0,
    );
  }
}

/// Team statistics model
class TeamStats {
  final int totalTeams;
  final int totalMembers;
  final int unassignedMembers;
  final double avgTeamSize;

  TeamStats({
    required this.totalTeams,
    required this.totalMembers,
    required this.unassignedMembers,
    required this.avgTeamSize,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    return TeamStats(
      totalTeams: json['totalTeams'] ?? 0,
      totalMembers: json['totalMembers'] ?? 0,
      unassignedMembers: json['unassignedMembers'] ?? 0,
      avgTeamSize: (json['avgTeamSize'] ?? 0).toDouble(),
    );
  }

  factory TeamStats.empty() {
    return TeamStats(
      totalTeams: 0,
      totalMembers: 0,
      unassignedMembers: 0,
      avgTeamSize: 0.0,
    );
  }
}

/// Member statistics model
class MemberStats {
  final int total;
  final int active;
  final int invited;
  final int suspended;

  MemberStats({
    required this.total,
    required this.active,
    required this.invited,
    required this.suspended,
  });

  factory MemberStats.fromJson(Map<String, dynamic> json) {
    return MemberStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      invited: json['invited'] ?? 0,
      suspended: json['suspended'] ?? 0,
    );
  }

  factory MemberStats.empty() {
    return MemberStats(
      total: 0,
      active: 0,
      invited: 0,
      suspended: 0,
    );
  }
}

/// Approval statistics model
class ApprovalStats {
  final int pending;
  final int approved;
  final int rejected;
  final double avgApprovalTime; // in hours

  ApprovalStats({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.avgApprovalTime,
  });

  factory ApprovalStats.fromJson(Map<String, dynamic> json) {
    return ApprovalStats(
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
      avgApprovalTime: (json['avgApprovalTime'] ?? 0).toDouble(),
    );
  }

  factory ApprovalStats.empty() {
    return ApprovalStats(
      pending: 0,
      approved: 0,
      rejected: 0,
      avgApprovalTime: 0.0,
    );
  }
}

/// Financial summary model
class FinancialSummary {
  final double totalValue;
  final double approvedValue;
  final double pendingValue;
  final double avgListingValue;

  FinancialSummary({
    required this.totalValue,
    required this.approvedValue,
    required this.pendingValue,
    required this.avgListingValue,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      approvedValue: (json['approvedValue'] ?? 0).toDouble(),
      pendingValue: (json['pendingValue'] ?? 0).toDouble(),
      avgListingValue: (json['avgListingValue'] ?? 0).toDouble(),
    );
  }

  factory FinancialSummary.empty() {
    return FinancialSummary(
      totalValue: 0.0,
      approvedValue: 0.0,
      pendingValue: 0.0,
      avgListingValue: 0.0,
    );
  }

  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }
}

/// Analytics scope helper
class AnalyticsScope {
  /// Get scope description for display
  static String getScopeDescription(PermissionContext context) {
    switch (context.roleType) {
      case RoleType.admin:
        return 'Company-wide Analytics';
      case RoleType.manager:
        return 'Department Analytics';
      case RoleType.lead:
        return 'Team Analytics';
      case RoleType.member:
        return 'Personal Analytics';
    }
  }

  /// Check if user can view company-wide analytics
  static bool canViewCompanyAnalytics(PermissionContext context) {
    return context.roleType == RoleType.admin;
  }

  /// Check if user can view department analytics
  static bool canViewDepartmentAnalytics(PermissionContext context) {
    return context.roleType == RoleType.admin ||
        context.roleType == RoleType.manager;
  }

  /// Check if user can view team analytics
  static bool canViewTeamAnalytics(PermissionContext context) {
    return context.roleType == RoleType.admin ||
        context.roleType == RoleType.manager ||
        context.roleType == RoleType.lead;
  }

  /// Check if user can export analytics
  static bool canExportAnalytics(PermissionContext context) {
    return context.roleType == RoleType.admin ||
        context.roleType == RoleType.manager;
  }
}


