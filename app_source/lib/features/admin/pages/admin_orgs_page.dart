import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/admin/admin_organization.dart';
import '../viewmodels/admin_orgs_viewmodel.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';

class AdminOrgsPage extends StatelessWidget {
  const AdminOrgsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminOrgsViewModel()..loadOrganizations(),
      child: const _AdminOrgsView(),
    );
  }
}

class _AdminOrgsView extends StatefulWidget {
  const _AdminOrgsView();

  @override
  State<_AdminOrgsView> createState() => _AdminOrgsViewState();
}

class _AdminOrgsViewState extends State<_AdminOrgsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOrganizationDetailsDialog(
    BuildContext context,
    AdminOrganization org,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading organization details...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch users for this organization
      final viewModel = AdminDashboardViewModel();
      final users = await viewModel.fetchUsersForOrg(org.orgId);

      if (!context.mounted) return;
      // Close loading dialog
      Navigator.of(context).pop();

      // Show details dialog
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(org.name),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailSection(context, 'Organization Information', [
                      _buildDetailRow('Organization ID', org.orgId),
                      _buildDetailRow('Plan', org.plan),
                      _buildDetailRow('Created At', _formatDate(org.createdAt)),
                      _buildDetailRow('Total Users', org.userCount.toString()),
                      _buildDetailRow(
                        'Total Incidents',
                        org.incidentCount.toString(),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      context,
                      'Domains',
                      org.domains.isEmpty
                          ? [const Text('No domains configured')]
                          : org.domains
                                .map(
                                  (d) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.domain,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(d),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      context,
                      'IP Ranges',
                      org.ipRanges.isEmpty
                          ? [const Text('No IP ranges configured')]
                          : org.ipRanges
                                .map(
                                  (ip) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.router,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(ip),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      context,
                      'Keywords',
                      org.keywords.isEmpty
                          ? [const Text('No keywords configured')]
                          : [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: org.keywords
                                    .map(
                                      (keyword) => Chip(
                                        label: Text(keyword),
                                        backgroundColor: Colors.purple
                                            .withOpacity(0.1),
                                        labelStyle: const TextStyle(
                                          color: Colors.purple,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      context,
                      'Users (${users.length})',
                      users.isEmpty
                          ? [const Text('No users in this organization')]
                          : users
                                .map(
                                  (user) => Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: ListTile(
                                      leading: const Icon(Icons.person),
                                      title: Text(user.fullName),
                                      subtitle: Text(user.email),
                                      trailing: Chip(
                                        label: Text(user.role),
                                        backgroundColor: _getRoleColor(
                                          user.role,
                                        ).withOpacity(0.1),
                                        labelStyle: TextStyle(
                                          color: _getRoleColor(user.role),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              OutlinedButton.icon(
                icon: const Icon(Icons.block, color: Colors.red),
                label: const Text(
                  'Suspend Org',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showConfirmDialog(
                    context,
                    'Suspend Organization',
                    'Are you sure you want to suspend ${org.name}? Users will lose access.',
                  );
                },
              ),
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load organization details: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMMd().add_jm().format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'enterprise':
        return Colors.purple;
      case 'professional':
        return Colors.blue;
      case 'basic':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showConfirmDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Action would be performed here')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminOrgsViewModel>();
    final textTheme = Theme.of(context).textTheme;
    double screenWidth = MediaQuery.of(context).size.width;
    double tableWidth = screenWidth / 1.5;
    double paddingWidth = tableWidth / 8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Management'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          final orgSource = _OrganizationDataSource(
            organizations: viewModel.organizations,
            context: context,
            onRowTap: (org) => _showOrganizationDetailsDialog(context, org),
            getPlanColor: _getPlanColor,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  'Filter & Search Organizations',
                  style: textTheme.titleLarge,
                ),
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
                      padding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: paddingWidth,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: tableWidth),
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
                                'All Organizations (${viewModel.organizations.length})',
                              ),
                            ),
                            columns: _buildDataColumns(context, viewModel),
                            source: orgSource,
                            sortColumnIndex: viewModel.sortColumnIndex,
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
    AdminOrgsViewModel viewModel,
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
              labelText: 'Search by name, ID, or domain',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.setSearchQuery(null);
                      },
                    )
                  : null,
            ),
            onChanged: (value) => viewModel.setSearchQuery(value),
          ),
        ),
        // Plan Dropdown
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            value: viewModel.selectedPlan,
            decoration: const InputDecoration(
              labelText: 'Plan',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Plans')),
              ...viewModel.availablePlans.map(
                (plan) => DropdownMenuItem(
                  value: plan,
                  child: Text(
                    plan,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
            onChanged: (value) => viewModel.setPlanFilter(value),
          ),
        ),
      ],
    );
  }

  List<DataColumn> _buildDataColumns(
    BuildContext context,
    AdminOrgsViewModel viewModel,
  ) {
    return [
      DataColumn(
        label: const Text('Organization'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Plan'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Users'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Incidents'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Created'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Domains'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
    ];
  }
}

/// Data source for the PaginatedDataTable.
class _OrganizationDataSource extends DataTableSource {
  final List<AdminOrganization> organizations;
  final BuildContext context;
  final void Function(AdminOrganization) onRowTap;
  final Color Function(String) getPlanColor;

  _OrganizationDataSource({
    required this.organizations,
    required this.context,
    required this.onRowTap,
    required this.getPlanColor,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= organizations.length) return null;
    final org = organizations[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          Text(org.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        DataCell(
          Chip(
            label: Text(org.plan),
            backgroundColor: getPlanColor(org.plan).withOpacity(0.1),
            labelStyle: TextStyle(
              color: getPlanColor(org.plan),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(Text(org.userCount.toString())),
        DataCell(Text(org.incidentCount.toString())),
        DataCell(Text(DateFormat.yMd().format(DateTime.parse(org.createdAt)))),
        DataCell(
          Text(
            org.domains.isEmpty ? 'None' : '${org.domains.length} domain(s)',
          ),
        ),
      ],
      onSelectChanged: (selected) {
        if (selected ?? false) onRowTap(org);
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => organizations.length;

  @override
  int get selectedRowCount => 0;
}
