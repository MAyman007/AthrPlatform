import 'package:flutter/foundation.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/models/admin/admin_organization.dart';
import '../../../core/models/admin/admin_user.dart';

class AdminUsersViewModel extends ChangeNotifier {
  final AdminApiService _adminApiService = locator<AdminApiService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- State for Data ---
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  List<Map<String, dynamic>> get users => _filteredUsers;

  // --- State for Filtering ---
  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  String? _selectedStatus;
  String? get selectedStatus => _selectedStatus;

  String? _searchQuery;
  String? get searchQuery => _searchQuery;

  // --- State for Sorting ---
  int _sortColumnIndex = 0; // Default to full name
  int get sortColumnIndex => _sortColumnIndex;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  List<AdminOrganization> _organizations = [];

  /// Fetches all users from all organizations and applies initial filters/sorting.
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch organizations first
      _organizations = await _adminApiService.getOrganizations();

      // Fetch users for each organization
      final allUsersList = <Map<String, dynamic>>[];
      for (final org in _organizations) {
        try {
          final users = await _adminApiService.getUsersForOrg(org.orgId);
          for (final user in users) {
            allUsersList.add({'user': user, 'orgName': org.name});
          }
        } catch (e) {
          print('Error fetching users for org ${org.orgId}: $e');
        }
      }

      _allUsers = allUsersList;
      _applyFiltersAndSorting();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the search query and reapplies filters.
  void setSearchQuery(String? query) {
    _searchQuery = query;
    _applyFiltersAndSorting();
  }

  /// Updates the role filter and reapplies filters.
  void setRoleFilter(String? role) {
    _selectedRole = role;
    _applyFiltersAndSorting();
  }

  /// Updates the status filter and reapplies filters.
  void setStatusFilter(String? status) {
    _selectedStatus = status;
    _applyFiltersAndSorting();
  }

  /// Updates the sorting parameters and re-sorts the data.
  void setSort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _applyFiltersAndSorting();
  }

  /// The core logic to filter and sort the user list.
  void _applyFiltersAndSorting() {
    _filteredUsers = _allUsers.where((userWithOrg) {
      final user = userWithOrg['user'] as AdminUser;
      final orgName = userWithOrg['orgName'] as String;

      final roleMatch = _selectedRole == null || user.role == _selectedRole;
      final statusMatch =
          _selectedStatus == null || user.accountStatus == _selectedStatus;
      final query = _searchQuery?.toLowerCase() ?? '';
      final queryMatch =
          query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          orgName.toLowerCase().contains(query);

      return roleMatch && statusMatch && queryMatch;
    }).toList();

    // Sorting logic
    _filteredUsers.sort((a, b) {
      final userA = a['user'] as AdminUser;
      final userB = b['user'] as AdminUser;
      final orgA = a['orgName'] as String;
      final orgB = b['orgName'] as String;

      int comparison;
      switch (_sortColumnIndex) {
        case 0: // Full Name
          comparison = userA.fullName.compareTo(userB.fullName);
          break;
        case 1: // Email
          comparison = userA.email.compareTo(userB.email);
          break;
        case 2: // Organization
          comparison = orgA.compareTo(orgB);
          break;
        case 3: // Role
          comparison = userA.role.compareTo(userB.role);
          break;
        case 4: // Account Status
          comparison = userA.accountStatus.compareTo(userB.accountStatus);
          break;
        case 5: // Login Count
          comparison = userA.loginCount.compareTo(userB.loginCount);
          break;
        case 6: // Created At
          comparison = DateTime.parse(
            userA.createdAt,
          ).compareTo(DateTime.parse(userB.createdAt));
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  /// Get unique roles for filter dropdown
  List<String> get availableRoles {
    final roles = _allUsers
        .map((u) => (u['user'] as AdminUser).role)
        .toSet()
        .toList();
    roles.sort();
    return roles;
  }

  /// Get unique statuses for filter dropdown
  List<String> get availableStatuses {
    final statuses = _allUsers
        .map((u) => (u['user'] as AdminUser).accountStatus)
        .toSet()
        .toList();
    statuses.sort();
    return statuses;
  }
}
