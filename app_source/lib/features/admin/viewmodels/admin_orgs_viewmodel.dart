import 'package:flutter/foundation.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/models/admin/admin_organization.dart';

class AdminOrgsViewModel extends ChangeNotifier {
  final AdminApiService _adminApiService = locator<AdminApiService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- State for Data ---
  List<AdminOrganization> _allOrganizations = [];
  List<AdminOrganization> _filteredOrganizations = [];

  List<AdminOrganization> get organizations => _filteredOrganizations;

  // --- State for Filtering ---
  String? _selectedPlan;
  String? get selectedPlan => _selectedPlan;

  String? _searchQuery;
  String? get searchQuery => _searchQuery;

  // --- State for Sorting ---
  int _sortColumnIndex = 0; // Default to org name
  int get sortColumnIndex => _sortColumnIndex;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  /// Fetches all organizations and applies initial filters/sorting.
  Future<void> loadOrganizations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allOrganizations = await _adminApiService.getOrganizations();
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

  /// Updates the plan filter and reapplies filters.
  void setPlanFilter(String? plan) {
    _selectedPlan = plan;
    _applyFiltersAndSorting();
  }

  /// Updates the sorting parameters and re-sorts the data.
  void setSort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _applyFiltersAndSorting();
  }

  /// The core logic to filter and sort the organization list.
  void _applyFiltersAndSorting() {
    _filteredOrganizations = _allOrganizations.where((org) {
      final planMatch = _selectedPlan == null || org.plan == _selectedPlan;
      final query = _searchQuery?.toLowerCase() ?? '';
      final queryMatch =
          query.isEmpty ||
          org.name.toLowerCase().contains(query) ||
          org.orgId.toLowerCase().contains(query) ||
          org.domains.any((d) => d.toLowerCase().contains(query));

      return planMatch && queryMatch;
    }).toList();

    // Sorting logic
    _filteredOrganizations.sort((a, b) {
      int comparison;
      switch (_sortColumnIndex) {
        case 0: // Organization Name
          comparison = a.name.compareTo(b.name);
          break;
        case 1: // Plan
          comparison = a.plan.compareTo(b.plan);
          break;
        case 2: // Users
          comparison = a.userCount.compareTo(b.userCount);
          break;
        case 3: // Incidents
          comparison = a.incidentCount.compareTo(b.incidentCount);
          break;
        case 4: // Created At
          comparison = DateTime.parse(
            a.createdAt,
          ).compareTo(DateTime.parse(b.createdAt));
          break;
        case 5: // Domains
          comparison = a.domains.length.compareTo(b.domains.length);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  /// Get unique plans for filter dropdown
  List<String> get availablePlans {
    final plans = _allOrganizations.map((org) => org.plan).toSet().toList();
    plans.sort();
    return plans;
  }
}
