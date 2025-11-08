import 'package:flutter/material.dart';
import 'package:athr/core/services/admin_api_service.dart';
import 'package:athr/core/models/admin/admin_incident.dart';
import 'package:athr/core/locator.dart';

class AdminIncidentsViewModel extends ChangeNotifier {
  final _adminApiService = locator<AdminApiService>();

  List<Map<String, dynamic>> _allIncidents = [];
  List<Map<String, dynamic>> _filteredIncidents = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _severityFilter;
  String? _organizationFilter;
  String _sortColumn = 'collectedAt';
  bool _sortAscending = false;

  List<Map<String, dynamic>> get filteredIncidents => _filteredIncidents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get severityFilter => _severityFilter;
  String? get organizationFilter => _organizationFilter;
  String get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  Future<void> loadIncidents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all organizations first
      final organizations = await _adminApiService.getOrganizations();

      // Fetch incidents for each organization
      final allIncidentsList = <Map<String, dynamic>>[];
      for (final org in organizations) {
        try {
          final incidents = await _adminApiService.getIncidentsForOrg(
            org.orgId,
          );
          for (final incident in incidents) {
            allIncidentsList.add({'incident': incident, 'orgName': org.name});
          }
        } catch (e) {
          print('Error fetching incidents for org ${org.orgId}: $e');
        }
      }

      _allIncidents = allIncidentsList;
      _applyFiltersAndSort();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void filterBySeverity(String? severity) {
    _severityFilter = severity;
    _applyFiltersAndSort();
  }

  void filterByOrganization(String? orgName) {
    _organizationFilter = orgName;
    _applyFiltersAndSort();
  }

  void sort(String column, bool ascending) {
    _sortColumn = column;
    _sortAscending = ascending;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredIncidents = _allIncidents.where((incidentWithOrg) {
      final incident = incidentWithOrg['incident'] as AdminIncident;
      final orgName = incidentWithOrg['orgName'] as String;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchableText =
            '''
          ${incident.source}
          ${incident.category}
          $orgName
        '''
                .toLowerCase();
        if (!searchableText.contains(_searchQuery)) {
          return false;
        }
      }

      // Severity filter
      if (_severityFilter != null &&
          incident.severity.toLowerCase() != _severityFilter!.toLowerCase()) {
        return false;
      }

      // Organization filter
      if (_organizationFilter != null && orgName != _organizationFilter) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    _filteredIncidents.sort((a, b) {
      final incidentA = a['incident'] as AdminIncident;
      final incidentB = b['incident'] as AdminIncident;
      final orgA = a['orgName'] as String;
      final orgB = b['orgName'] as String;

      int comparison = 0;
      switch (_sortColumn) {
        case 'severity':
          comparison = _compareSeverity(incidentA.severity, incidentB.severity);
          break;
        case 'collectedAt':
          final dateA = incidentA.collectedAtDate ?? DateTime.now();
          final dateB = incidentB.collectedAtDate ?? DateTime.now();
          comparison = dateA.compareTo(dateB);
          break;
        case 'category':
          comparison = incidentA.category.compareTo(incidentB.category);
          break;
        case 'source':
          comparison = incidentA.source.compareTo(incidentB.source);
          break;
        case 'organization':
          comparison = orgA.compareTo(orgB);
          break;
        case 'emailCount':
          comparison = incidentA.leakedEmailCount.compareTo(
            incidentB.leakedEmailCount,
          );
          break;
        case 'machineCount':
          comparison = incidentA.compromisedMachineCount.compareTo(
            incidentB.compromisedMachineCount,
          );
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  int _compareSeverity(String severityA, String severityB) {
    const severityOrder = {
      'critical': 0,
      'high': 1,
      'medium': 2,
      'low': 3,
      'unknown': 4,
    };

    final orderA = severityOrder[severityA.toLowerCase()] ?? 4;
    final orderB = severityOrder[severityB.toLowerCase()] ?? 4;

    return orderA.compareTo(orderB);
  }

  void clearFilters() {
    _searchQuery = '';
    _severityFilter = null;
    _organizationFilter = null;
    _applyFiltersAndSort();
  }

  /// Get unique severities for filter dropdown
  List<String> get availableSeverities {
    final severities = _allIncidents
        .map((i) => (i['incident'] as AdminIncident).severity)
        .toSet()
        .toList();
    severities.sort((a, b) => _compareSeverity(a, b));
    return severities;
  }

  /// Get unique organizations for filter dropdown
  List<String> get availableOrganizations {
    final orgs = _allIncidents
        .map((i) => i['orgName'] as String)
        .toSet()
        .toList();
    orgs.sort();
    return orgs;
  }
}
