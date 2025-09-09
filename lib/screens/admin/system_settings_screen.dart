import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (!adminProvider.isOwnerAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('System Settings')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Access Denied'),
                  SizedBox(height: 8),
                  Text(
                    'Only Owner Admins can access system settings',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('System Settings'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'General', icon: Icon(Icons.settings)),
                Tab(text: 'Security', icon: Icon(Icons.security)),
                Tab(text: 'Backup', icon: Icon(Icons.backup)),
                Tab(text: 'Integrations', icon: Icon(Icons.extension)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralSettingsTab(),
              _buildSecuritySettingsTab(),
              _buildBackupSettingsTab(),
              _buildIntegrationsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneralSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsCard(
          'Application Settings',
          [
            _buildSettingItem(
              'App Name',
              'Event Planning App',
              Icons.title,
              onTap: () => _showEditDialog('App Name', 'Event Planning App'),
            ),
            _buildSettingItem(
              'Default Language',
              'English',
              Icons.language,
              onTap: () => _showLanguageDialog(),
            ),
            _buildSettingItem(
              'Time Zone',
              'UTC-8 (Pacific)',
              Icons.access_time,
              onTap: () => _showTimezoneDialog(),
            ),
            _buildSwitchItem(
              'Enable Registration',
              true,
              Icons.app_registration,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              'Allow Photo Uploads',
              true,
              Icons.photo_camera,
              onChanged: (value) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Event Defaults',
          [
            _buildSettingItem(
              'Default Capacity',
              '100',
              Icons.people,
              onTap: () => _showEditDialog('Default Capacity', '100'),
            ),
            _buildSettingItem(
              'Registration Deadline',
              '24 hours before',
              Icons.schedule,
              onTap: () => _showDeadlineDialog(),
            ),
            _buildSwitchItem(
              'Auto-Approve Events',
              false,
              Icons.auto_awesome,
              onChanged: (value) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Notifications',
          [
            _buildSwitchItem(
              'Email Notifications',
              true,
              Icons.email,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              'Push Notifications',
              true,
              Icons.notifications,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              'SMS Notifications',
              false,
              Icons.sms,
              onChanged: (value) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecuritySettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsCard(
          'Authentication',
          [
            _buildSettingItem(
              'Password Policy',
              'Strong (8+ chars)',
              Icons.password,
              onTap: () => _showPasswordPolicyDialog(),
            ),
            _buildSettingItem(
              'Session Timeout',
              '24 hours',
              Icons.timer,
              onTap: () => _showSessionTimeoutDialog(),
            ),
            _buildSwitchItem(
              'Two-Factor Authentication',
              false,
              Icons.security,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              'Force Password Reset',
              false,
              Icons.key,
              onChanged: (value) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Data Privacy',
          [
            _buildSwitchItem(
              'GDPR Compliance',
              true,
              Icons.privacy_tip,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              'Data Encryption',
              true,
              Icons.enhanced_encryption,
              onChanged: (value) {},
            ),
            _buildSettingItem(
              'Data Retention',
              '7 years',
              Icons.storage,
              onTap: () => _showDataRetentionDialog(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Access Control',
          [
            _buildSwitchItem(
              'Rate Limiting',
              true,
              Icons.speed,
              onChanged: (value) {},
            ),
            _buildSwitchItem(
              'IP Whitelisting',
              false,
              Icons.location_on,
              onChanged: (value) {},
            ),
            _buildSettingItem(
              'Failed Login Attempts',
              '5 attempts',
              Icons.block,
              onTap: () => _showLoginAttemptsDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackupSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsCard(
          'Backup Configuration',
          [
            _buildSwitchItem(
              'Automatic Backups',
              true,
              Icons.backup,
              onChanged: (value) {},
            ),
            _buildSettingItem(
              'Backup Frequency',
              'Daily at 2:00 AM',
              Icons.schedule,
              onTap: () => _showBackupScheduleDialog(),
            ),
            _buildSettingItem(
              'Retention Period',
              '30 days',
              Icons.history,
              onTap: () => _showRetentionDialog(),
            ),
            _buildSettingItem(
              'Storage Location',
              'AWS S3',
              Icons.cloud,
              onTap: () => _showStorageDialog(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Backup Actions',
          [
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.blue),
              title: const Text('Create Backup Now'),
              subtitle: const Text('Create an immediate backup'),
              trailing: ElevatedButton(
                onPressed: () => _createBackupNow(),
                child: const Text('Backup'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.green),
              title: const Text('Restore from Backup'),
              subtitle: const Text('Restore system from previous backup'),
              trailing: ElevatedButton(
                onPressed: () => _showRestoreDialog(),
                child: const Text('Restore'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.orange),
              title: const Text('Export Data'),
              subtitle: const Text('Download system data export'),
              trailing: ElevatedButton(
                onPressed: () => _exportData(),
                child: const Text('Export'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Recent Backups',
          [
            _buildBackupItem('2024-01-15 02:00:00', '2.3 GB', 'Success'),
            _buildBackupItem('2024-01-14 02:00:00', '2.2 GB', 'Success'),
            _buildBackupItem('2024-01-13 02:00:00', '2.1 GB', 'Success'),
            _buildBackupItem('2024-01-12 02:00:00', '2.0 GB', 'Failed'),
          ],
        ),
      ],
    );
  }

  Widget _buildIntegrationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsCard(
          'Payment Gateways',
          [
            _buildIntegrationItem(
              'Stripe',
              'Process payments securely',
              Icons.payment,
              true,
              onToggle: (value) {},
            ),
            _buildIntegrationItem(
              'PayPal',
              'Alternative payment method',
              Icons.account_balance_wallet,
              false,
              onToggle: (value) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Email Services',
          [
            _buildIntegrationItem(
              'SendGrid',
              'Email delivery service',
              Icons.email,
              true,
              onToggle: (value) {},
            ),
            _buildIntegrationItem(
              'Mailchimp',
              'Email marketing campaigns',
              Icons.campaign,
              false,
              onToggle: (value) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Analytics',
          [
            _buildIntegrationItem(
              'Google Analytics',
              'Web analytics and insights',
              Icons.analytics,
              true,
              onToggle: (value) {},
            ),
            _buildIntegrationItem(
              'Mixpanel',
              'Advanced user analytics',
              Icons.trending_up,
              false,
              onToggle: (value) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          'Communication',
          [
            _buildIntegrationItem(
              'Slack',
              'Team notifications',
              Icons.chat,
              false,
              onToggle: (value) {},
            ),
            _buildIntegrationItem(
              'Discord',
              'Community integration',
              Icons.forum,
              false,
              onToggle: (value) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(
    String title,
    bool value,
    IconData icon, {
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildIntegrationItem(
    String title,
    String description,
    IconData icon,
    bool isEnabled, {
    required ValueChanged<bool> onToggle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isEnabled ? Colors.green : Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: Switch(
        value: isEnabled,
        onChanged: onToggle,
      ),
    );
  }

  Widget _buildBackupItem(String date, String size, String status) {
    final isSuccess = status == 'Success';
    
    return ListTile(
      leading: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        color: isSuccess ? Colors.green : Colors.red,
      ),
      title: Text(date),
      subtitle: Text(size),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSuccess ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextFormField(
          initialValue: currentValue,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language selection dialog')),
    );
  }

  void _showTimezoneDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timezone selection dialog')),
    );
  }

  void _showDeadlineDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deadline configuration dialog')),
    );
  }

  void _showPasswordPolicyDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password policy configuration')),
    );
  }

  void _showSessionTimeoutDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session timeout configuration')),
    );
  }

  void _showDataRetentionDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data retention policy configuration')),
    );
  }

  void _showLoginAttemptsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login attempts configuration')),
    );
  }

  void _showBackupScheduleDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup schedule configuration')),
    );
  }

  void _showRetentionDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup retention configuration')),
    );
  }

  void _showStorageDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage location configuration')),
    );
  }

  void _createBackupNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating backup... This may take a few minutes')),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will restore the system to a previous state. All current data will be replaced. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restore process started...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing data export... Download will start shortly')),
    );
  }
}