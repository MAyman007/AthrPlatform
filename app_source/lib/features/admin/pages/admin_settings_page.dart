import 'package:flutter/material.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _autoApproveOrgs = false;
  bool _enableUserRegistration = true;
  bool _requireEmailVerification = true;
  bool _enableMaintenanceMode = false;
  int _maxUsersPerOrg = 100;
  int _dataRetentionDays = 90;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Text(
              'System Configuration',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage system-wide settings and configurations',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // User Management Section
            _buildSection(
              context,
              title: 'User Management',
              icon: Icons.people,
              color: Colors.blue,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Enable User Registration',
                  subtitle: 'Allow new users to register accounts',
                  value: _enableUserRegistration,
                  onChanged: (value) {
                    setState(() => _enableUserRegistration = value);
                  },
                ),
                const Divider(height: 32),
                _buildSwitchTile(
                  context,
                  title: 'Require Email Verification',
                  subtitle: 'Users must verify email before accessing system',
                  value: _requireEmailVerification,
                  onChanged: (value) {
                    setState(() => _requireEmailVerification = value);
                  },
                ),
                const Divider(height: 32),
                _buildActionTile(
                  context,
                  title: 'Bulk User Management',
                  subtitle: 'Disable, delete, or export user accounts',
                  icon: Icons.manage_accounts,
                  onTap: () => _showBulkUserManagement(context),
                ),
                const Divider(height: 32),
                _buildActionTile(
                  context,
                  title: 'User Activity Monitoring',
                  subtitle: 'View and manage active user sessions',
                  icon: Icons.monitor,
                  onTap: () => _showUserActivityMonitoring(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Organization Management Section
            _buildSection(
              context,
              title: 'Organization Management',
              icon: Icons.business,
              color: Colors.orange,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Auto-Approve Organizations',
                  subtitle: 'Automatically approve new organization requests',
                  value: _autoApproveOrgs,
                  onChanged: (value) {
                    setState(() => _autoApproveOrgs = value);
                  },
                ),
                const Divider(height: 32),
                _buildSliderTile(
                  context,
                  title: 'Max Users Per Organization',
                  subtitle: 'Current limit: $_maxUsersPerOrg users',
                  value: _maxUsersPerOrg.toDouble(),
                  min: 10,
                  max: 500,
                  divisions: 49,
                  onChanged: (value) {
                    setState(() => _maxUsersPerOrg = value.toInt());
                  },
                ),
                const Divider(height: 32),
                _buildActionTile(
                  context,
                  title: 'Bulk Organization Management',
                  subtitle: 'Suspend, delete, or upgrade organizations',
                  icon: Icons.corporate_fare,
                  onTap: () => _showBulkOrgManagement(context),
                ),
                const Divider(height: 32),
                _buildActionTile(
                  context,
                  title: 'Pending Approvals',
                  subtitle: 'Review and approve organization requests',
                  icon: Icons.approval,
                  onTap: () => _showPendingApprovals(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System Settings Section
            _buildSection(
              context,
              title: 'System Settings',
              icon: Icons.settings_applications,
              color: Colors.purple,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Maintenance Mode',
                  subtitle:
                      'Disable access for non-admin users during maintenance',
                  value: _enableMaintenanceMode,
                  onChanged: (value) {
                    setState(() => _enableMaintenanceMode = value);
                  },
                ),
                const Divider(height: 32),
                _buildSliderTile(
                  context,
                  title: 'Data Retention Period',
                  subtitle:
                      'Delete incidents older than $_dataRetentionDays days',
                  value: _dataRetentionDays.toDouble(),
                  min: 30,
                  max: 365,
                  divisions: 67,
                  onChanged: (value) {
                    setState(() => _dataRetentionDays = value.toInt());
                  },
                ),
                const Divider(height: 32),
                _buildActionTile(
                  context,
                  title: 'Clear System Cache',
                  subtitle: 'Remove all cached data to free up space',
                  icon: Icons.cleaning_services,
                  onTap: () => _showClearCacheDialog(context),
                ),
                const Divider(height: 32),
                _buildActionTile(
                  context,
                  title: 'Database Backup',
                  subtitle: 'Create a backup of the entire database',
                  icon: Icons.backup,
                  onTap: () => _showDatabaseBackupDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Danger Zone Section
            _buildSection(
              context,
              title: 'Danger Zone',
              icon: Icons.warning,
              color: Colors.red,
              children: [
                _buildActionTile(
                  context,
                  title: 'Delete All Test Data',
                  subtitle: 'Remove all test organizations and users',
                  icon: Icons.delete_forever,
                  color: Colors.red,
                  onTap: () => _showDeleteTestDataDialog(context),
                ),
                const Divider(height: 32),
                _buildActionTile(
                  context,
                  title: 'Reset System',
                  subtitle: 'Reset all settings to default values',
                  icon: Icons.restore,
                  color: Colors.red,
                  onTap: () => _showResetSystemDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => _saveSettings(context),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color ?? Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showBulkUserManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk User Management'),
        content: const Text(
          'This feature allows you to:\n\n'
          '• Disable multiple user accounts\n'
          '• Delete inactive users\n'
          '• Export user data to CSV\n'
          '• Reset passwords in bulk\n\n'
          'Feature coming soon...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUserActivityMonitoring(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Activity Monitoring'),
        content: const Text(
          'This feature allows you to:\n\n'
          '• View active user sessions\n'
          '• Terminate suspicious sessions\n'
          '• Track login attempts\n'
          '• Monitor user activity logs\n\n'
          'Feature coming soon...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBulkOrgManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Organization Management'),
        content: const Text(
          'This feature allows you to:\n\n'
          '• Suspend organizations temporarily\n'
          '• Delete inactive organizations\n'
          '• Upgrade/downgrade plans in bulk\n'
          '• Export organization data\n\n'
          'Feature coming soon...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPendingApprovals(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Approvals'),
        content: const Text(
          'This feature allows you to:\n\n'
          '• Review new organization requests\n'
          '• Approve or reject applications\n'
          '• View organization details\n'
          '• Contact applicants\n\n'
          'Feature coming soon...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear System Cache'),
        content: const Text(
          'This will remove all cached data from the system. '
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('System cache cleared successfully'),
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showDatabaseBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Backup'),
        content: const Text(
          'This will create a complete backup of the database. '
          'The backup will be stored securely and can be used for restoration.\n\n'
          'Estimated time: 5-10 minutes',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database backup started...')),
              );
            },
            child: const Text('Start Backup'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTestDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Test Data'),
        content: const Text(
          'WARNING: This will permanently delete all test organizations and users. '
          'This action cannot be undone!\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test data deletion started...'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete All Test Data'),
          ),
        ],
      ),
    );
  }

  void _showResetSystemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset System'),
        content: const Text(
          'WARNING: This will reset all system settings to their default values. '
          'User data will not be affected.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _autoApproveOrgs = false;
                _enableUserRegistration = true;
                _requireEmailVerification = true;
                _enableMaintenanceMode = false;
                _maxUsersPerOrg = 100;
                _dataRetentionDays = 90;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('System settings reset to defaults'),
                ),
              );
            },
            child: const Text('Reset System'),
          ),
        ],
      ),
    );
  }

  void _saveSettings(BuildContext context) {
    // Placeholder for saving settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
