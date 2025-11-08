class AdminIncident {
  final int incidentId;
  final String orgId;
  final String source;
  final String severity;
  final String category;
  final String collectedAt;
  final int leakedEmailCount;
  final int compromisedMachineCount;

  AdminIncident({
    required this.incidentId,
    required this.orgId,
    required this.source,
    required this.severity,
    required this.category,
    required this.collectedAt,
    required this.leakedEmailCount,
    required this.compromisedMachineCount,
  });

  factory AdminIncident.fromJson(Map<String, dynamic> json) {
    return AdminIncident(
      incidentId: json['incident_id'] as int,
      orgId: json['org_id'] as String,
      source: json['source'] as String,
      severity: json['severity'] as String,
      category: json['category'] as String,
      collectedAt: json['collected_at'] as String,
      leakedEmailCount: json['leaked_email_count'] as int,
      compromisedMachineCount: json['compromised_machine_count'] as int,
    );
  }

  DateTime? get collectedAtDate {
    try {
      return DateTime.parse(collectedAt);
    } catch (e) {
      return null;
    }
  }

  String get severityLevel {
    return severity.toLowerCase();
  }
}
