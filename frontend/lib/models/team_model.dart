class Team {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? teamLeadId;
  final TeamLead? teamLead;
  final List<TeamMember> members;
  final TeamStats? stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.teamLeadId,
    this.teamLead,
    required this.members,
    this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      teamLeadId: json['teamLeadId'],
      teamLead: json['teamLead'] != null ? TeamLead.fromJson(json['teamLead']) : null,
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => TeamMember.fromJson(m))
              .toList() ??
          [],
      stats: json['stats'] != null ? TeamStats.fromJson(json['stats']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'teamLeadId': teamLeadId,
      'teamLead': teamLead?.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'stats': stats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TeamLead {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  TeamLead({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory TeamLead.fromJson(Map<String, dynamic> json) {
    return TeamLead(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime joinedAt;

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

class TeamStats {
  final int memberCount;
  final int activeListingsCount;
  final double totalValue;

  TeamStats({
    required this.memberCount,
    required this.activeListingsCount,
    required this.totalValue,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    return TeamStats(
      memberCount: json['memberCount'] ?? 0,
      activeListingsCount: json['activeListingsCount'] ?? 0,
      totalValue: (json['totalValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberCount': memberCount,
      'activeListingsCount': activeListingsCount,
      'totalValue': totalValue,
    };
  }
}

class TeamListItem {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? teamLeadId;
  final String? teamLeadName;
  final String? teamLeadEmail;
  final int memberCount;
  final int activeListingsCount;
  final DateTime createdAt;

  TeamListItem({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.teamLeadId,
    this.teamLeadName,
    this.teamLeadEmail,
    required this.memberCount,
    required this.activeListingsCount,
    required this.createdAt,
  });

  factory TeamListItem.fromJson(Map<String, dynamic> json) {
    return TeamListItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      teamLeadId: json['teamLeadId'],
      teamLeadName: json['teamLeadName'],
      teamLeadEmail: json['teamLeadEmail'],
      memberCount: json['memberCount'] ?? 0,
      activeListingsCount: json['activeListingsCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

