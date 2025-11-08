import 'package:flutter/foundation.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/models/admin/admin_stats.dart';
import '../../../core/models/admin/admin_organization.dart';
import '../../../core/models/admin/admin_user.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final AdminApiService _adminApiService = locator<AdminApiService>();

  AdminStats? _stats;
  List<AdminOrganization> _organizations = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminStats? get stats => _stats;
  List<AdminOrganization> get organizations => _organizations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed properties for graphs
  Map<String, int> get organizationsByPlan {
    final planCounts = <String, int>{};
    for (final org in _organizations) {
      planCounts[org.plan] = (planCounts[org.plan] ?? 0) + 1;
    }
    return planCounts;
  }

  Map<String, int> get topOrganizationsByUsers {
    final sorted = List<AdminOrganization>.from(_organizations)
      ..sort((a, b) => b.userCount.compareTo(a.userCount));
    final top10 = sorted.take(10);
    return {for (var org in top10) org.name: org.userCount};
  }

  Map<String, int> get topOrganizationsByIncidents {
    final sorted = List<AdminOrganization>.from(_organizations)
      ..sort((a, b) => b.incidentCount.compareTo(a.incidentCount));
    final top10 = sorted.take(10);
    return {for (var org in top10) org.name: org.incidentCount};
  }

  double get averageUsersPerOrg {
    if (_organizations.isEmpty) return 0;
    final totalUsers = _organizations.fold<int>(
      0,
      (sum, org) => sum + org.userCount,
    );
    return totalUsers / _organizations.length;
  }

  double get averageIncidentsPerOrg {
    if (_organizations.isEmpty) return 0;
    final totalIncidents = _organizations.fold<int>(
      0,
      (sum, org) => sum + org.incidentCount,
    );
    return totalIncidents / _organizations.length;
  }

  // Store all users for login activity
  List<AdminUser> _allUsers = [];
  List<AdminUser> get allUsers => _allUsers;

  /// Get login activity grouped by date (last 30 days)
  Map<DateTime, int> get loginActivityByDate {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final loginCounts = <DateTime, int>{};

    for (final user in _allUsers) {
      if (user.lastLogin != null && user.lastLogin!.isNotEmpty) {
        try {
          final loginDate = DateTime.parse(user.lastLogin!);
          // Only include logins from the last 30 days
          if (loginDate.isAfter(thirtyDaysAgo)) {
            // Normalize to start of day
            final dateOnly = DateTime(
              loginDate.year,
              loginDate.month,
              loginDate.day,
            );
            loginCounts[dateOnly] = (loginCounts[dateOnly] ?? 0) + 1;
          }
        } catch (e) {
          // Skip invalid dates
          continue;
        }
      }
    }

    // Fill in missing days with 0
    for (var i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      loginCounts.putIfAbsent(date, () => 0);
    }

    // Sort by date
    final sortedEntries = loginCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  Future<void> fetchStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch both stats and organizations in parallel
      final results = await Future.wait([
        _adminApiService.getAdminStats(),
        _adminApiService.getOrganizations(),
      ]);

      _stats = results[0] as AdminStats;
      _organizations = results[1] as List<AdminOrganization>;

      // Fetch all users from all organizations
      final allUsersData = await fetchAllUsers();
      _allUsers = allUsersData
          .map((data) => data['user'] as AdminUser)
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load statistics: $e';
      notifyListeners();
    }
  }

  void refresh() {
    fetchStats();
  }

  /// Fetch all users from all organizations
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final allUsers = <Map<String, dynamic>>[];

    // Fetch users for each organization in parallel
    final usersFutures = _organizations.map((org) async {
      try {
        final users = await _adminApiService.getUsersForOrg(org.orgId);
        return users.map((user) {
          return {'user': user, 'orgName': org.name};
        }).toList();
      } catch (e) {
        print('Error fetching users for org ${org.orgId}: $e');
        return <Map<String, dynamic>>[];
      }
    });

    final results = await Future.wait(usersFutures);

    // Flatten the results
    for (final userList in results) {
      allUsers.addAll(userList);
    }

    // Sort by organization name, then by user name
    allUsers.sort((a, b) {
      final orgCompare = (a['orgName'] as String).compareTo(
        b['orgName'] as String,
      );
      if (orgCompare != 0) return orgCompare;
      return (a['user'] as AdminUser).fullName.compareTo(
        (b['user'] as AdminUser).fullName,
      );
    });

    return allUsers;
  }

  /// Fetch users for a specific organization
  Future<List<AdminUser>> fetchUsersForOrg(String orgId) async {
    try {
      return await _adminApiService.getUsersForOrg(orgId);
    } catch (e) {
      print('Error fetching users for org $orgId: $e');
      rethrow;
    }
  }
}
