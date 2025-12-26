class Company {
  final String id;
  final String name;
  final String companyType;
  final String? industry;
  final String? size;
  final String status;
  final CompanyStats? stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.companyType,
    this.industry,
    this.size,
    required this.status,
    this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      companyType: json['companyType'],
      industry: json['industry'],
      size: json['size'],
      status: json['status'],
      stats: json['stats'] != null ? CompanyStats.fromJson(json['stats']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'companyType': companyType,
      'industry': industry,
      'size': size,
      'status': status,
      'stats': stats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CompanyStats {
  final int totalMembers;
  final int unassignedMembers;
  final int totalTeams;
  final int totalDepartments;

  CompanyStats({
    required this.totalMembers,
    required this.unassignedMembers,
    required this.totalTeams,
    required this.totalDepartments,
  });

  factory CompanyStats.fromJson(Map<String, dynamic> json) {
    return CompanyStats(
      totalMembers: json['totalMembers'] ?? 0,
      unassignedMembers: json['unassignedMembers'] ?? 0,
      totalTeams: json['totalTeams'] ?? 0,
      totalDepartments: json['totalDepartments'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMembers': totalMembers,
      'unassignedMembers': unassignedMembers,
      'totalTeams': totalTeams,
      'totalDepartments': totalDepartments,
    };
  }
}

