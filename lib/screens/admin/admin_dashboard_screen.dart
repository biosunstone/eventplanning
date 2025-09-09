import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'admin_login_screen.dart';
import 'user_management_screen.dart';
import 'event_management_screen.dart';
import 'content_moderation_screen.dart';
import 'admin_analytics_screen.dart';
import 'system_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  
  Map<String, dynamic> _dashboardStats = {};
  Map<String, dynamic> _systemHealth = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await _adminService.getDashboardStats();
      final health = await _adminService.getSystemHealth();
      
      setState(() {
        _dashboardStats = stats;
        _systemHealth = health;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  void _signOut() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.signOut();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    adminProvider.currentAdmin?.name.substring(0, 1) ?? 'A',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(adminProvider.currentAdmin?.name ?? 'Admin'),
                      subtitle: Text(adminProvider.currentAdmin?.roleDisplayName ?? ''),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    onTap: _signOut,
                    child: const ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Sign Out'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsOverview(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildSystemHealth(),
                    const SizedBox(height: 24),
                    _buildRevenueChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Users',
              '${_dashboardStats['totalUsers'] ?? 0}',
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Active Events',
              '${_dashboardStats['activeEvents'] ?? 0}',
              Icons.event,
              Colors.green,
            ),
            _buildStatCard(
              'Total Revenue',
              '\$${(_dashboardStats['totalRevenue'] ?? 0).toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.purple,
            ),
            _buildStatCard(
              'Registrations',
              '${_dashboardStats['totalRegistrations'] ?? 0}',
              Icons.confirmation_number,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final isOwner = adminProvider.isOwnerAdmin;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
              children: [
                _buildActionButton(
                  'User Management',
                  Icons.people_alt,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  )),
                ),
                _buildActionButton(
                  'Event Management',
                  Icons.event,
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const EventManagementScreen(),
                  )),
                ),
                _buildActionButton(
                  'Content Moderation',
                  Icons.shield_outlined,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ContentModerationScreen(),
                  )),
                ),
                _buildActionButton(
                  'Analytics',
                  Icons.analytics,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AdminAnalyticsScreen(),
                  )),
                ),
                if (isOwner) ...[
                  _buildActionButton(
                    'System Settings',
                    Icons.settings,
                    Colors.red,
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const SystemSettingsScreen(),
                    )),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    if (_systemHealth.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Health',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overall Health', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Healthy',
                            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildHealthItem('Database', _systemHealth['database'])),
                    Expanded(child: _buildHealthItem('Storage', _systemHealth['storage'])),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildHealthItem('Memory', _systemHealth['memory'])),
                    Expanded(child: _buildHealthItem('CPU', _systemHealth['cpu'])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthItem(String name, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox();
    
    final status = data['status'] as String;
    final isHealthy = status == 'healthy';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12)),
                if (data.containsKey('usage'))
                  Text(
                    data['usage'],
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('This Month', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '\$${(_dashboardStats['monthlyRevenue'] ?? 0).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('+12%', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 3),
                            const FlSpot(1, 1),
                            const FlSpot(2, 4),
                            const FlSpot(3, 2),
                            const FlSpot(4, 5),
                            const FlSpot(5, 3),
                            const FlSpot(6, 6),
                          ],
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}