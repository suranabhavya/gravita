class PermissionContext {
  final String userId;
  final String companyId;
  final RoleType roleType;
  final Permissions permissions;
  final ScopeType scopeType;
  final String? scopeId;
  final double maxApprovalAmount;

  PermissionContext({
    required this.userId,
    required this.companyId,
    required this.roleType,
    required this.permissions,
    required this.scopeType,
    this.scopeId,
    required this.maxApprovalAmount,
  });

  factory PermissionContext.fromJson(Map<String, dynamic> json) {
    return PermissionContext(
      userId: json['userId'] as String,
      companyId: json['companyId'] as String,
      roleType: RoleType.values.byName(json['roleType'] as String),
      permissions: Permissions.fromJson(json['permissions'] as Map<String, dynamic>),
      scopeType: ScopeType.values.byName(json['scopeType'] as String),
      scopeId: json['scopeId'] as String?,
      maxApprovalAmount: (json['maxApprovalAmount'] is int)
          ? (json['maxApprovalAmount'] as int).toDouble()
          : (json['maxApprovalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'companyId': companyId,
      'roleType': roleType.name,
      'permissions': permissions.toJson(),
      'scopeType': scopeType.name,
      'scopeId': scopeId,
      'maxApprovalAmount': maxApprovalAmount,
    };
  }

  bool get isAdmin => roleType == RoleType.admin;
  bool get isManager => roleType == RoleType.manager;
  bool get isLead => roleType == RoleType.lead;
  bool get isMember => roleType == RoleType.member;

  bool get hasCompanyScope => scopeType == ScopeType.company && scopeId == null;
  bool get hasDepartmentScope => scopeType == ScopeType.department;
  bool get hasTeamScope => scopeType == ScopeType.team;

  bool canApprove(double amount) {
    return permissions.canApproveListings && amount <= maxApprovalAmount;
  }
}

enum RoleType { admin, manager, lead, member }

enum ScopeType { company, department, team }

class Permissions {
  final bool canManageStructure;
  final bool canApproveListings;
  final bool canAccessSettings;

  Permissions({
    required this.canManageStructure,
    required this.canApproveListings,
    required this.canAccessSettings,
  });

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      canManageStructure: json['canManageStructure'] as bool? ?? false,
      canApproveListings: json['canApproveListings'] as bool? ?? false,
      canAccessSettings: json['canAccessSettings'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canManageStructure': canManageStructure,
      'canApproveListings': canApproveListings,
      'canAccessSettings': canAccessSettings,
    };
  }
}


