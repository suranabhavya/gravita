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
      if (people != null) 'people': people!.toJson(),
      if (teams != null) 'teams': teams!.toJson(),
      if (departments != null) 'departments': departments!.toJson(),
      if (listings != null) 'listings': listings!.toJson(),
      if (analytics != null) 'analytics': analytics!.toJson(),
      if (settings != null) 'settings': settings!.toJson(),
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
      if (viewMembers != null) 'view_members': viewMembers,
      if (inviteMembers != null) 'invite_members': inviteMembers,
      if (editMembers != null) 'edit_members': editMembers,
      if (removeMembers != null) 'remove_members': removeMembers,
      if (viewAllProfiles != null) 'view_all_profiles': viewAllProfiles,
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
      if (viewTeams != null) 'view_teams': viewTeams,
      if (createTeams != null) 'create_teams': createTeams,
      if (editTeams != null) 'edit_teams': editTeams,
      if (deleteTeams != null) 'delete_teams': deleteTeams,
      if (manageTeamMembers != null) 'manage_team_members': manageTeamMembers,
      if (assignTeamLeads != null) 'assign_team_leads': assignTeamLeads,
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
      if (viewDepartments != null) 'view_departments': viewDepartments,
      if (createDepartments != null) 'create_departments': createDepartments,
      if (editDepartments != null) 'edit_departments': editDepartments,
      if (deleteDepartments != null) 'delete_departments': deleteDepartments,
      if (moveDepartments != null) 'move_departments': moveDepartments,
      if (assignTeamToDepartment != null) 'assign_team_to_department': assignTeamToDepartment,
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
      if (create != null) 'create': create,
      if (editOwn != null) 'edit_own': editOwn,
      if (editAny != null) 'edit_any': editAny,
      if (delete != null) 'delete': delete,
      if (approve != null) 'approve': approve,
      if (viewAll != null) 'view_all': viewAll,
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
      if (viewOwn != null) 'view_own': viewOwn,
      if (viewOwnTeam != null) 'view_own_team': viewOwnTeam,
      if (viewDepartment != null) 'view_department': viewDepartment,
      if (viewCompany != null) 'view_company': viewCompany,
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
      if (viewSettings != null) 'view_settings': viewSettings,
      if (manageCompany != null) 'manage_company': manageCompany,
      if (manageRoles != null) 'manage_roles': manageRoles,
      if (managePermissions != null) 'manage_permissions': managePermissions,
    };
  }
}

