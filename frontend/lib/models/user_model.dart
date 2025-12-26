class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String status;
  final List<UserTeam> teams;
  final List<String> roles;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    required this.status,
    required this.teams,
    required this.roles,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      phone: json['phone'],
      status: json['status'],
      teams: (json['teams'] as List<dynamic>?)
              ?.map((t) => UserTeam.fromJson(t))
              .toList() ??
          [],
      roles: (json['roles'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'status': status,
      'teams': teams.map((t) => t.toJson()).toList(),
      'roles': roles,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isUnassigned => teams.isEmpty;
  bool isTeamLeadOf(String teamId) {
    return teams.any((t) => t.id == teamId && t.isTeamLead);
  }
}

class UserTeam {
  final String id;
  final String name;
  final bool isTeamLead;

  UserTeam({
    required this.id,
    required this.name,
    required this.isTeamLead,
  });

  factory UserTeam.fromJson(Map<String, dynamic> json) {
    return UserTeam(
      id: json['id'],
      name: json['name'],
      isTeamLead: json['isTeamLead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isTeamLead': isTeamLead,
    };
  }
}

class CompanyMembersResponse {
  final List<User> members;
  final Map<String, List<User>> groupedByTeam;
  final int unassignedCount;

  CompanyMembersResponse({
    required this.members,
    required this.groupedByTeam,
    required this.unassignedCount,
  });

  factory CompanyMembersResponse.fromJson(Map<String, dynamic> json) {
    final members = (json['members'] as List<dynamic>?)
            ?.map((m) => User.fromJson(m))
            .toList() ??
        [];

    final groupedByTeam = <String, List<User>>{};
    if (json['groupedByTeam'] != null) {
      (json['groupedByTeam'] as Map<String, dynamic>).forEach((key, value) {
        groupedByTeam[key] = (value as List<dynamic>)
            .map((m) => User.fromJson(m))
            .toList();
      });
    }

    return CompanyMembersResponse(
      members: members,
      groupedByTeam: groupedByTeam,
      unassignedCount: json['unassignedCount'] ?? 0,
    );
  }
}

