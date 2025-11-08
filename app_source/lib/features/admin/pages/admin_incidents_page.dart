import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:athr/core/models/admin/admin_incident.dart';
import 'package:athr/features/admin/viewmodels/admin_incidents_viewmodel.dart';

class AdminIncidentsPage extends StatelessWidget {
  const AdminIncidentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminIncidentsViewModel()..loadIncidents(),
      child: const _AdminIncidentsView(),
    );
  }
}

class _AdminIncidentsView extends StatefulWidget {
  const _AdminIncidentsView();

  @override
  State<_AdminIncidentsView> createState() => _AdminIncidentsViewState();
}

class _AdminIncidentsViewState extends State<_AdminIncidentsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showIncidentDetailsDialog(
    BuildContext context,
    AdminIncident incident,
    String orgName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Incident #${incident.incidentId}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('Organization', orgName),
                _buildDetailRow('Source', incident.source),
                _buildDetailRow('Severity', incident.severity.toUpperCase()),
                _buildDetailRow('Category', incident.category),
                _buildDetailRow(
                  'Collected At',
                  incident.collectedAtDate != null
                      ? DateFormat.yMMMd().add_jm().format(
                          incident.collectedAtDate!,
                        )
                      : incident.collectedAt,
                ),
                _buildDetailRow(
                  'Leaked Emails',
                  incident.leakedEmailCount.toString(),
                ),
                _buildDetailRow(
                  'Compromised Machines',
                  incident.compromisedMachineCount.toString(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: SelectableText(value ?? 'N/A')),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const double tableWidth = 1200.0;
    const double paddingWidth = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Consumer<AdminIncidentsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${viewModel.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadIncidents(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final incidentSource = _IncidentsDataSource(
            incidents: viewModel.filteredIncidents,
            onRowTap: (incident, orgName) =>
                _showIncidentDetailsDialog(context, incident, orgName),
            getSeverityColor: _getSeverityColor,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text('Filter & Search Incidents', style: textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildFilterControls(context, viewModel),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: paddingWidth,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: tableWidth),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            cardTheme: const CardThemeData(
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                          child: PaginatedDataTable(
                            header: Center(
                              child: Text(
                                'All Incidents (${viewModel.filteredIncidents.length})',
                              ),
                            ),
                            columns: _buildDataColumns(context, viewModel),
                            source: incidentSource,
                            sortColumnIndex: _getSortColumnIndex(
                              viewModel.sortColumn,
                            ),
                            sortAscending: viewModel.sortAscending,
                            rowsPerPage: 10,
                            showCheckboxColumn: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterControls(
    BuildContext context,
    AdminIncidentsViewModel viewModel,
  ) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: [
        // Search Field
        SizedBox(
          width: 370,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by source, category, or organization',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.search('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => viewModel.search(value),
          ),
        ),
        // Severity Dropdown
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            value: viewModel.severityFilter,
            decoration: const InputDecoration(
              labelText: 'Severity',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Severities'),
              ),
              ...viewModel.availableSeverities.map((severity) {
                return DropdownMenuItem(
                  value: severity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getSeverityColor(severity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          severity.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) => viewModel.filterBySeverity(value),
          ),
        ),
        if (viewModel.searchQuery.isNotEmpty ||
            viewModel.severityFilter != null)
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              viewModel.clearFilters();
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
          ),
      ],
    );
  }

  List<DataColumn> _buildDataColumns(
    BuildContext context,
    AdminIncidentsViewModel viewModel,
  ) {
    return [
      DataColumn(
        label: const Text('Severity'),
        onSort: (columnIndex, ascending) {
          viewModel.sort('severity', ascending);
        },
      ),
      DataColumn(
        label: const Text('Date'),
        onSort: (columnIndex, ascending) {
          viewModel.sort('collectedAt', ascending);
        },
      ),
      DataColumn(
        label: const Text('Organization'),
        onSort: (columnIndex, ascending) {
          viewModel.sort('organization', ascending);
        },
      ),
      DataColumn(
        label: const Text('Category'),
        onSort: (columnIndex, ascending) {
          viewModel.sort('category', ascending);
        },
      ),
      DataColumn(
        label: const Text('Source'),
        onSort: (columnIndex, ascending) {
          viewModel.sort('source', ascending);
        },
      ),
      DataColumn(
        label: const Text('Leaked Emails'),
        onSort: (columnIndex, ascending) {
          viewModel.sort('emailCount', ascending);
        },
        numeric: true,
      ),
      DataColumn(
        label: const Text('Machines'),
        onSort: (columnIndex, ascending) {
          viewModel.sort('machineCount', ascending);
        },
        numeric: true,
      ),
    ];
  }

  int _getSortColumnIndex(String columnName) {
    switch (columnName) {
      case 'severity':
        return 0;
      case 'collectedAt':
        return 1;
      case 'organization':
        return 2;
      case 'category':
        return 3;
      case 'source':
        return 4;
      case 'emailCount':
        return 5;
      case 'machineCount':
        return 6;
      default:
        return 1;
    }
  }
}

class _IncidentsDataSource extends DataTableSource {
  final List<Map<String, dynamic>> incidents;
  final Function(AdminIncident, String) onRowTap;
  final Color Function(String) getSeverityColor;

  _IncidentsDataSource({
    required this.incidents,
    required this.onRowTap,
    required this.getSeverityColor,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= incidents.length) return null;
    final incidentWithOrg = incidents[index];
    final incident = incidentWithOrg['incident'] as AdminIncident;
    final orgName = incidentWithOrg['orgName'] as String;

    return DataRow(
      onSelectChanged: (_) => onRowTap(incident, orgName),
      cells: [
        // Severity
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: getSeverityColor(incident.severity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: getSeverityColor(incident.severity).withOpacity(0.3),
              ),
            ),
            child: Text(
              incident.severity.toUpperCase(),
              style: TextStyle(
                color: getSeverityColor(incident.severity),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        // Date
        DataCell(
          Text(
            incident.collectedAtDate != null
                ? DateFormat(
                    'MMM dd, yyyy HH:mm',
                  ).format(incident.collectedAtDate!)
                : incident.collectedAt,
          ),
        ),
        // Organization
        DataCell(
          Text(orgName, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        // Category
        DataCell(Text(incident.category)),
        // Source
        DataCell(Text(incident.source)),
        // Leaked Emails
        DataCell(Text(incident.leakedEmailCount.toString())),
        // Machines
        DataCell(Text(incident.compromisedMachineCount.toString())),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => incidents.length;

  @override
  int get selectedRowCount => 0;
}
