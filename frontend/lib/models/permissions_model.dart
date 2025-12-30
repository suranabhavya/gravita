class UserPermissions {
  final PeoplePermissions? people;
  final TeamsPermissions? teams;
  final DepartmentsPermissions? departments;
  final ListingsPermissions? listings;
  final AnalyticsPermissions? analytics;
  final SettingsPermissions? settings;

  UserPermissions({
    this.people,
    this.teams,
    this.departments,
    this.listings,
    this.analytics,
    this.settings,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      people: json['people'] != null ? PeoplePermissions.fromJson(json['people']) : null,
      teams: json['teams'] != null ? TeamsPermissions.fromJson(json['teams']) : null,
      departments: json['departments'] != null ? DepartmentsPermissions.fromJson(json['departments']) : null,
      listings: json['listings'] != null ? ListingsPermissions.fromJson(json['listings']) : null,
      analytics: json['analytics'] != null ? AnalyticsPermissions.fromJson(json['analytics']) : null,
      settings: json['settings'] != null ? SettingsPermissions.fromJson(json['settings']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'people': people?.toJson() ?? PeoplePermissions().toJson(),
      'teams': teams?.toJson() ?? TeamsPermissions().toJson(),
      'departments': departments?.toJson() ?? DepartmentsPermissions().toJson(),
      'listings': listings?.toJson() ?? ListingsPermissions().toJson(),
      'analytics': analytics?.toJson() ?? AnalyticsPermissions().toJson(),
      'settings': settings?.toJson() ?? SettingsPermissions().toJson(),
    };
  }

  UserPermissions copyWith({
    PeoplePermissions? people,
    TeamsPermissions? teams,
    DepartmentsPermissions? departments,
    ListingsPermissions? listings,
    AnalyticsPermissions? analytics,
    SettingsPermissions? settings,
  }) {
    return UserPermissions(
      people: people ?? this.people,
      teams: teams ?? this.teams,
      departments: departments ?? this.departments,
      listings: listings ?? this.listings,
      analytics: analytics ?? this.analytics,
      settings: settings ?? this.settings,
    );
  }
}

class PeoplePermissions {
  final bool? viewMembers;
  final bool? inviteMembers;
  final bool? editMembers;
  final bool? removeMembers;
  final bool? viewAllProfiles;

  PeoplePermissions({
    this.viewMembers,
    this.inviteMembers,
    this.editMembers,
    this.removeMembers,
    this.viewAllProfiles,
  });

  factory PeoplePermissions.fromJson(Map<String, dynamic> json) {
    return PeoplePermissions(
      viewMembers: json['view_members'],
      inviteMembers: json['invite_members'],
      editMembers: json['edit_members'],
      removeMembers: json['remove_members'],
      viewAllProfiles: json['view_all_profiles'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view_members': viewMembers ?? false,
      'invite_members': inviteMembers ?? false,
      'edit_members': editMembers ?? false,
      'remove_members': removeMembers ?? false,
      'view_all_profiles': viewAllProfiles ?? false,
    };
  }
}

class TeamsPermissions {
  final bool? viewTeams;
  final bool? createTeams;
  final bool? editTeams;
  final bool? deleteTeams;
  final bool? manageTeamMembers;
  final bool? assignTeamLeads;

  TeamsPermissions({
    this.viewTeams,
    this.createTeams,
    this.editTeams,
    this.deleteTeams,
    this.manageTeamMembers,
    this.assignTeamLeads,
  });

  factory TeamsPermissions.fromJson(Map<String, dynamic> json) {
    return TeamsPermissions(
      viewTeams: json['view_teams'],
      createTeams: json['create_teams'],
      editTeams: json['edit_teams'],
      deleteTeams: json['delete_teams'],
      manageTeamMembers: json['manage_team_members'],
      assignTeamLeads: json['assign_team_leads'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view_teams': viewTeams ?? false,
      'create_teams': createTeams ?? false,
      'edit_teams': editTeams ?? false,
      'delete_teams': deleteTeams ?? false,
      'manage_team_members': manageTeamMembers ?? false,
      'assign_team_leads': assignTeamLeads ?? false,
    };
  }
}

class DepartmentsPermissions {
  final bool? viewDepartments;
  final bool? createDepartments;
  final bool? editDepartments;
  final bool? deleteDepartments;
  final bool? moveDepartments;
  final bool? assignTeamToDepartment;

  DepartmentsPermissions({
    this.viewDepartments,
    this.createDepartments,
    this.editDepartments,
    this.deleteDepartments,
    this.moveDepartments,
    this.assignTeamToDepartment,
  });

  factory DepartmentsPermissions.fromJson(Map<String, dynamic> json) {
    return DepartmentsPermissions(
      viewDepartments: json['view_departments'],
      createDepartments: json['create_departments'],
      editDepartments: json['edit_departments'],
      deleteDepartments: json['delete_departments'],
      moveDepartments: json['move_departments'],
      assignTeamToDepartment: json['assign_team_to_department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view_departments': viewDepartments ?? false,
      'create_departments': createDepartments ?? false,
      'edit_departments': editDepartments ?? false,
      'delete_departments': deleteDepartments ?? false,
      'move_departments': moveDepartments ?? false,
      'assign_team_to_department': assignTeamToDepartment ?? false,
    };
  }
}

class ListingsPermissions {
  final bool? create;
  final bool? editOwn;
  final bool? editAny;
  final bool? delete;
  final bool? approve;
  final bool? viewAll;
  final double? maxApprovalAmount;

  ListingsPermissions({
    this.create,
    this.editOwn,
    this.editAny,
    this.delete,
    this.approve,
    this.viewAll,
    this.maxApprovalAmount,
  });

  factory ListingsPermissions.fromJson(Map<String, dynamic> json) {
    return ListingsPermissions(
      create: json['create'],
      editOwn: json['edit_own'],
      editAny: json['edit_any'],
      delete: json['delete'],
      approve: json['approve'],
      viewAll: json['view_all'],
      maxApprovalAmount: json['max_approval_amount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'create': create ?? false,
      'edit_own': editOwn ?? false,
      'edit_any': editAny ?? false,
      'delete': delete ?? false,
      'approve': approve ?? false,
      'view_all': viewAll ?? false,
      if (maxApprovalAmount != null) 'max_approval_amount': maxApprovalAmount,
    };
  }
}

class AnalyticsPermissions {
  final bool? viewOwn;
  final bool? viewOwnTeam;
  final bool? viewDepartment;
  final bool? viewCompany;

  AnalyticsPermissions({
    this.viewOwn,
    this.viewOwnTeam,
    this.viewDepartment,
    this.viewCompany,
  });

  factory AnalyticsPermissions.fromJson(Map<String, dynamic> json) {
    return AnalyticsPermissions(
      viewOwn: json['view_own'],
      viewOwnTeam: json['view_own_team'],
      viewDepartment: json['view_department'],
      viewCompany: json['view_company'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view_own': viewOwn ?? false,
      'view_own_team': viewOwnTeam ?? false,
      'view_department': viewDepartment ?? false,
      'view_company': viewCompany ?? false,
    };
  }
}

class SettingsPermissions {
  final bool? viewSettings;
  final bool? manageCompany;
  final bool? manageRoles;
  final bool? managePermissions;

  SettingsPermissions({
    this.viewSettings,
    this.manageCompany,
    this.manageRoles,
    this.managePermissions,
  });

  factory SettingsPermissions.fromJson(Map<String, dynamic> json) {
    return SettingsPermissions(
      viewSettings: json['view_settings'],
      manageCompany: json['manage_company'],
      manageRoles: json['manage_roles'],
      managePermissions: json['manage_permissions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view_settings': viewSettings ?? false,
      'manage_company': manageCompany ?? false,
      'manage_roles': manageRoles ?? false,
      'manage_permissions': managePermissions ?? false,
    };
  }
}

