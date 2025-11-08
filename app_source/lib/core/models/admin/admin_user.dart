class AdminUser {
  final String userId;
  final String orgId;
  final String fullName;
  final String email;
  final String role;
  final String createdAt;
  final String? lastLogin;
  final String accountStatus;
  final String? lastLoginIp;
  final String authProvider;
  final String? lastActivityAt;
  final int loginCount;
  final int incidentReportsViewed;
  final bool isBillingContact;

  AdminUser({
    required this.userId,
    required this.orgId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    required this.accountStatus,
    this.lastLoginIp,
    required this.authProvider,
    this.lastActivityAt,
    required this.loginCount,
    required this.incidentReportsViewed,
    required this.isBillingContact,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      userId: json['user_id'] as String? ?? '',
      orgId: json['org_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      lastLogin: json['last_login'] as String?,
      accountStatus: json['account_status'] as String? ?? '',
      lastLoginIp: json['last_login_ip'] as String?,
      authProvider: json['auth_provider'] as String? ?? '',
      lastActivityAt: json['last_activity_at'] as String?,
      loginCount: json['login_count'] as int? ?? 0,
      incidentReportsViewed: json['incident_reports_viewed'] as int? ?? 0,
      isBillingContact: json['is_billing_contact'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'org_id': orgId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'created_at': createdAt,
      'last_login': lastLogin,
      'account_status': accountStatus,
      'last_login_ip': lastLoginIp,
      'auth_provider': authProvider,
      'last_activity_at': lastActivityAt,
      'login_count': loginCount,
      'incident_reports_viewed': incidentReportsViewed,
      'is_billing_contact': isBillingContact,
    };
  }
}
