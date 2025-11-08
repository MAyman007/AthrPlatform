import 'dart:convert';

class AdminOrganization {
  final String orgId;
  final String name;
  final String plan;
  final List<String> domains;
  final List<String> ipRanges;
  final List<String> keywords;
  final String createdAt;
  final int userCount;
  final int incidentCount;

  AdminOrganization({
    required this.orgId,
    required this.name,
    required this.plan,
    required this.domains,
    required this.ipRanges,
    required this.keywords,
    required this.createdAt,
    required this.userCount,
    required this.incidentCount,
  });

  factory AdminOrganization.fromJson(Map<String, dynamic> json) {
    return AdminOrganization(
      orgId: json['org_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      plan: json['plan'] as String? ?? '',
      domains: _parseStringList(json['domains']),
      ipRanges: _parseStringList(json['ip_ranges']),
      keywords: _parseStringList(json['keywords']),
      createdAt: json['created_at'] as String? ?? '',
      userCount: json['user_count'] as int? ?? 0,
      incidentCount: json['incident_count'] as int? ?? 0,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      try {
        // Try to parse as JSON array
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // If JSON parsing fails, return empty list
        return [];
      }
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'org_id': orgId,
      'name': name,
      'plan': plan,
      'domains': domains,
      'ip_ranges': ipRanges,
      'keywords': keywords,
      'created_at': createdAt,
      'user_count': userCount,
      'incident_count': incidentCount,
    };
  }
}
