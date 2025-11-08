import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/admin/admin_user.dart';
import '../viewmodels/admin_users_viewmodel.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminUsersViewModel()..loadUsers(),
      child: const _AdminUsersView(),
    );
  }
}

class _AdminUsersView extends StatefulWidget {
  const _AdminUsersView();

  @override
  State<_AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<_AdminUsersView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetailsDialog(
    BuildContext context,
    AdminUser user,
    String orgName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(user.fullName),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailSection(context, 'User Information', [
                    _buildDetailRow('User ID', user.userId),
                    _buildDetailRow('Full Name', user.fullName),
                    _buildDetailRow('Email', user.email),
                    _buildDetailRow('Organization', orgName),
                    _buildDetailRow('Role', user.role),
                    _buildDetailRow('Account Status', user.accountStatus),
                    _buildDetailRow('Auth Provider', user.authProvider),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailSection(context, 'Activity Information', [
                    _buildDetailRow('Created At', _formatDate(user.createdAt)),
                    _buildDetailRow(
                      'Last Login',
                      user.lastLogin != null
                          ? _formatDate(user.lastLogin!)
                          : 'Never',
                    ),
                    _buildDetailRow('Last Login IP', user.lastLoginIp ?? 'N/A'),
                    _buildDetailRow(
                      'Last Activity',
                      user.lastActivityAt != null
                          ? _formatDate(user.lastActivityAt!)
                          : 'N/A',
                    ),
                    _buildDetailRow('Login Count', user.loginCount.toString()),
                    _buildDetailRow(
                      'Incident Reports Viewed',
                      user.incidentReportsViewed.toString(),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailSection(context, 'Additional Details', [
                    _buildDetailRow(
                      'Billing Contact',
                      user.isBillingContact ? 'Yes' : 'No',
                    ),
                  ]),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            OutlinedButton.icon(
              icon: const Icon(Icons.block, color: Colors.orange),
              label: const Text(
                'Disable User',
                style: TextStyle(color: Colors.orange),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showConfirmDialog(
                  context,
                  'Disable User',
                  'Are you sure you want to disable ${user.fullName}? They will lose access to the system.',
                );
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Delete User',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showConfirmDialog(
                  context,
                  'Delete User',
                  'Are you sure you want to permanently delete ${user.fullName}? This action cannot be undone!',
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
            width: 150,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
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
    final viewModel = context.watch<AdminUsersViewModel>();
    final textTheme = Theme.of(context).textTheme;
    double screenWidth = MediaQuery.of(context).size.width;
    double tableWidth = screenWidth / 1.3;
    double paddingWidth = tableWidth / 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
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

          final userSource = _UserDataSource(
            users: viewModel.users,
            context: context,
            onRowTap: (user, orgName) =>
                _showUserDetailsDialog(context, user, orgName),
            getRoleColor: _getRoleColor,
            getStatusColor: _getStatusColor,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text('Filter & Search Users', style: textTheme.titleLarge),
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
                                'All Users (${viewModel.users.length})',
                              ),
                            ),
                            columns: _buildDataColumns(context, viewModel),
                            source: userSource,
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
    AdminUsersViewModel viewModel,
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
              labelText: 'Search by name, email, or organization',
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
        // Role Dropdown
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String?>(
            value: viewModel.selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Roles')),
              ...viewModel.availableRoles.map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(
                    role,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
            onChanged: (value) => viewModel.setRoleFilter(value),
          ),
        ),
        // Status Dropdown
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            value: viewModel.selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Statuses')),
              ...viewModel.availableStatuses.map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(
                    status,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
            onChanged: (value) => viewModel.setStatusFilter(value),
          ),
        ),
      ],
    );
  }

  List<DataColumn> _buildDataColumns(
    BuildContext context,
    AdminUsersViewModel viewModel,
  ) {
    return [
      DataColumn(
        label: const Text('Full Name'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Email'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Organization'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Role'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Status'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Logins'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Created'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
    ];
  }
}

/// Data source for the PaginatedDataTable.
class _UserDataSource extends DataTableSource {
  final List<Map<String, dynamic>> users;
  final BuildContext context;
  final void Function(AdminUser, String) onRowTap;
  final Color Function(String) getRoleColor;
  final Color Function(String) getStatusColor;

  _UserDataSource({
    required this.users,
    required this.context,
    required this.onRowTap,
    required this.getRoleColor,
    required this.getStatusColor,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;
    final userWithOrg = users[index];
    final user = userWithOrg['user'] as AdminUser;
    final orgName = userWithOrg['orgName'] as String;

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          Text(
            user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(user.email)),
        DataCell(Text(orgName)),
        DataCell(
          Chip(
            label: Text(user.role),
            backgroundColor: getRoleColor(user.role).withOpacity(0.1),
            labelStyle: TextStyle(
              color: getRoleColor(user.role),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Chip(
            label: Text(user.accountStatus),
            backgroundColor: getStatusColor(
              user.accountStatus,
            ).withOpacity(0.1),
            labelStyle: TextStyle(
              color: getStatusColor(user.accountStatus),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(Text(user.loginCount.toString())),
        DataCell(Text(DateFormat.yMd().format(DateTime.parse(user.createdAt)))),
      ],
      onSelectChanged: (selected) {
        if (selected ?? false) onRowTap(user, orgName);
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}
