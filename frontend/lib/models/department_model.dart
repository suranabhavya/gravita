class Department {
  final String id;
  final String name;
  final String? description;
  final String? parentDepartmentId;
  final int level;
  final String? managerId;
  final DepartmentManager? manager;
  final List<DepartmentTeam> teams;
  final int teamCount;
  final int memberCount;
  final DateTime createdAt;

  Department({
    required this.id,
    required this.name,
    this.description,
    this.parentDepartmentId,
    required this.level,
    this.managerId,
    this.manager,
    required this.teams,
    required this.teamCount,
    required this.memberCount,
    required this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      parentDepartmentId: json['parentDepartmentId'],
      level: json['level'],
      managerId: json['managerId'],
      manager: json['manager'] != null ? DepartmentManager.fromJson(json['manager']) : null,
      teams: (json['teams'] as List<dynamic>?)
              ?.map((t) => DepartmentTeam.fromJson(t))
              .toList() ??
          [],
      teamCount: json['teamCount'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentDepartmentId': parentDepartmentId,
      'level': level,
      'managerId': managerId,
      'manager': manager?.toJson(),
      'teams': teams.map((t) => t.toJson()).toList(),
      'teamCount': teamCount,
      'memberCount': memberCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class DepartmentManager {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  DepartmentManager({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory DepartmentManager.fromJson(Map<String, dynamic> json) {
    return DepartmentManager(
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

class DepartmentTeam {
  final String id;
  final String name;
  final String? location;
  final int memberCount;

  DepartmentTeam({
    required this.id,
    required this.name,
    this.location,
    required this.memberCount,
  });

  factory DepartmentTeam.fromJson(Map<String, dynamic> json) {
    return DepartmentTeam(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      memberCount: json['memberCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'memberCount': memberCount,
    };
  }
}

class DepartmentTree {
  final String id;
  final String name;
  final String? description;
  final String? parentDepartmentId;
  final int level;
  final String? managerName;
  final String? managerEmail;
  final int teamCount;
  final int memberCount;
  final List<DepartmentTree> children;
  final DateTime createdAt;

  DepartmentTree({
    required this.id,
    required this.name,
    this.description,
    this.parentDepartmentId,
    required this.level,
    this.managerName,
    this.managerEmail,
    required this.teamCount,
    required this.memberCount,
    required this.children,
    required this.createdAt,
  });

  factory DepartmentTree.fromJson(Map<String, dynamic> json) {
    return DepartmentTree(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      parentDepartmentId: json['parentDepartmentId'],
      level: json['level'],
      managerName: json['managerName'],
      managerEmail: json['managerEmail'],
      teamCount: json['teamCount'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => DepartmentTree.fromJson(c))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

