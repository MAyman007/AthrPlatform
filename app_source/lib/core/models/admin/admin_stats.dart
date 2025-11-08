class AdminStats {
  final int totalOrganizations;
  final int totalUsers;
  final int totalIncidents;

  AdminStats({
    required this.totalOrganizations,
    required this.totalUsers,
    required this.totalIncidents,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalOrganizations: json['total_organizations'] as int? ?? 0,
      totalUsers: json['total_users'] as int? ?? 0,
      totalIncidents: json['total_incidents'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_organizations': totalOrganizations,
      'total_users': totalUsers,
      'total_incidents': totalIncidents,
    };
  }
}
