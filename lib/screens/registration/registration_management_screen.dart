import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/registration_service.dart';
import 'registration_detail_screen.dart';
import 'ticket_type_setup_screen.dart';
import 'discount_code_screen.dart';

class RegistrationManagementScreen extends StatefulWidget {
  final Event event;

  const RegistrationManagementScreen({super.key, required this.event});

  @override
  State<RegistrationManagementScreen> createState() => _RegistrationManagementScreenState();
}

class _RegistrationManagementScreenState extends State<RegistrationManagementScreen>
    with SingleTickerProviderStateMixin {
  final RegistrationService _registrationService = RegistrationService();
  
  late TabController _tabController;
  List<Registration> _registrations = [];
  List<TicketTypeConfig> _ticketTypes = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Generate demo data if needed
      final existingTicketTypes = await _registrationService.getTicketTypes(widget.event.id);
      if (existingTicketTypes.isEmpty) {
        await _registrationService.generateDemoData(widget.event.id);
      }

      final results = await Future.wait([
        _registrationService.getEventRegistrations(widget.event.id),
        _registrationService.getTicketTypes(widget.event.id),
        _registrationService.getRegistrationAnalytics(widget.event.id),
      ]);

      _registrations = results[0] as List<Registration>;
      _ticketTypes = results[1] as List<TicketTypeConfig>;
      _analytics = results[2] as Map<String, dynamic>;

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registration Management'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Registrations', icon: Icon(Icons.people)),
            Tab(text: 'Tickets', icon: Icon(Icons.confirmation_number)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRegistrationsTab(),
                _buildTicketsTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentRegistrations(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registration Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Registrations',
                    '${_analytics['totalRegistrations'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Checked In',
                    '${_analytics['checkedInCount'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    '\$${((_analytics['totalRevenue'] ?? 0.0) as double).toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avg. Order',
                    '\$${((_analytics['averageOrderValue'] ?? 0.0) as double).toStringAsFixed(0)}',
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRegistrations() {
    final recentRegistrations = _registrations.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Registrations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentRegistrations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No registrations yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...recentRegistrations.map((registration) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      registration.firstName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(registration.fullName),
                  subtitle: Text(registration.email),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(registration.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(registration.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${registration.finalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _viewRegistrationDetail(registration),
                  dense: true,
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Create Ticket Type',
                    Icons.add_box,
                    Colors.blue,
                    _createTicketType,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Add Discount Code',
                    Icons.local_offer,
                    Colors.green,
                    _createDiscountCode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Export Data',
                    Icons.download,
                    Colors.purple,
                    _exportData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Send Update',
                    Icons.email,
                    Colors.orange,
                    _sendUpdate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(title, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildRegistrationsTab() {
    return Column(
      children: [
        _buildRegistrationFilters(),
        Expanded(
          child: _registrations.isEmpty
              ? const Center(
                  child: Text(
                    'No registrations found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _registrations.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRegistrationCard(_registrations[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRegistrationFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search registrations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _filterRegistrations,
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<RegistrationStatus?>(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Filter Status'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Statuses'),
              ),
              ...RegistrationStatus.values.map((status) => PopupMenuItem(
                value: status,
                child: Text(_getStatusText(status)),
              )),
            ],
            onSelected: _filterByStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(Registration registration) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(registration.status),
          child: Text(
            registration.firstName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(registration.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(registration.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(registration.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(registration.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (registration.isPaid)
                  const Icon(Icons.payment, color: Colors.green, size: 16),
                if (registration.isCheckedIn)
                  const Icon(Icons.check_circle, color: Colors.blue, size: 16),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${registration.finalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${registration.totalTickets} tickets',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () => _viewRegistrationDetail(registration),
      ),
    );
  }

  Widget _buildTicketsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ticket Types',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _createTicketType,
                icon: const Icon(Icons.add),
                label: const Text('Add Ticket Type'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ticketTypes.isEmpty
              ? const Center(
                  child: Text(
                    'No ticket types created yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _ticketTypes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTicketTypeCard(_ticketTypes[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTicketTypeCard(TicketTypeConfig ticketType) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticketType.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticketType.description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${ticketType.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ticketType.isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticketType.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sold: ${ticketType.sold} / ${ticketType.totalAvailable}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: ticketType.soldPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ticketType.soldPercentage > 80 ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${ticketType.soldPercentage.toStringAsFixed(0)}% sold',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (ticketType.includedFeatures.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Included Features:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...ticketType.includedFeatures.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRegistrationTrendChart(),
          const SizedBox(height: 24),
          _buildStatusBreakdown(),
          const SizedBox(height: 24),
          _buildTicketTypeSales(),
        ],
      ),
    );
  }

  Widget _buildRegistrationTrendChart() {
    final trendData = (_analytics['registrationTrend'] as List<Map<String, dynamic>>?) ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registration Trend (Last 30 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < trendData.length) {
                            return Text(
                              trendData[index]['date'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trendData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['registrations'] as int).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    final statusBreakdown = (_analytics['statusBreakdown'] as Map<String, int>?) ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registration Status Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...statusBreakdown.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getStatusColor(_getStatusFromName(entry.key)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_getStatusText(_getStatusFromName(entry.key))),
                  ),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeSales() {
    final ticketTypeSales = (_analytics['ticketTypeSales'] as Map<String, Map<String, dynamic>>?) ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Type Sales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...ticketTypeSales.entries.map((entry) {
              final data = entry.value;
              final sold = data['sold'] as int;
              final available = data['available'] as int;
              final revenue = data['revenue'] as double;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '\$${revenue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: available > 0 ? sold / available : 0,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$sold / $available',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return Colors.green;
      case RegistrationStatus.pending:
        return Colors.orange;
      case RegistrationStatus.rejected:
        return Colors.red;
      case RegistrationStatus.cancelled:
        return Colors.grey;
      case RegistrationStatus.checked_in:
        return Colors.blue;
      case RegistrationStatus.waitlisted:
        return Colors.purple;
      case RegistrationStatus.draft:
        return Colors.grey[400]!;
    }
  }

  String _getStatusText(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return 'Approved';
      case RegistrationStatus.pending:
        return 'Pending';
      case RegistrationStatus.rejected:
        return 'Rejected';
      case RegistrationStatus.cancelled:
        return 'Cancelled';
      case RegistrationStatus.checked_in:
        return 'Checked In';
      case RegistrationStatus.waitlisted:
        return 'Waitlisted';
      case RegistrationStatus.draft:
        return 'Draft';
    }
  }

  RegistrationStatus _getStatusFromName(String name) {
    return RegistrationStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => RegistrationStatus.pending,
    );
  }

  void _filterRegistrations(String query) {
    // Implementation would filter _registrations based on search query
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search functionality would be implemented here')),
    );
  }

  void _filterByStatus(RegistrationStatus? status) {
    // Implementation would filter _registrations by status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filter by ${status?.name ?? 'all'} would be implemented here')),
    );
  }

  void _viewRegistrationDetail(Registration registration) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegistrationDetailScreen(
          registration: registration,
          event: widget.event,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _createTicketType() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketTypeSetupScreen(event: widget.event),
      ),
    ).then((_) => _loadData());
  }

  void _createDiscountCode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiscountCodeScreen(event: widget.event),
      ),
    ).then((_) => _loadData());
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export data functionality would be implemented here')),
    );
  }

  void _sendUpdate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send update functionality would be implemented here')),
    );
  }
}