import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/analytics.dart';
import '../../services/analytics_service.dart';

class DetailedAnalyticsScreen extends StatefulWidget {
  final Event event;

  const DetailedAnalyticsScreen({super.key, required this.event});

  @override
  State<DetailedAnalyticsScreen> createState() => _DetailedAnalyticsScreenState();
}

class _DetailedAnalyticsScreenState extends State<DetailedAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  EventAnalytics? _analytics;
  Map<String, dynamic> _featureUsage = {};
  Map<String, dynamic> _userBehavior = {};
  Map<String, dynamic> _sessionAnalytics = {};
  List<TimeSeriesData> _timeSeriesData = [];
  bool _isLoading = false;
  
  late TabController _tabController;
  TimeRange _selectedTimeRange = TimeRange.daily;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDetailedAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetailedAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.generateEventAnalytics(widget.event.id),
        _analyticsService.getFeatureUsageAnalytics(widget.event.id),
        _analyticsService.getUserBehaviorAnalytics(widget.event.id),
        _analyticsService.getSessionAnalytics(widget.event.id),
        _analyticsService.getEngagementTimeSeries(widget.event.id, _selectedTimeRange),
      ]);

      _analytics = results[0] as EventAnalytics;
      _featureUsage = results[1] as Map<String, dynamic>;
      _userBehavior = results[2] as Map<String, dynamic>;
      _sessionAnalytics = results[3] as Map<String, dynamic>;
      _timeSeriesData = results[4] as List<TimeSeriesData>;

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateTimeRange(TimeRange newRange) async {
    setState(() => _selectedTimeRange = newRange);
    
    try {
      _timeSeriesData = await _analyticsService.getEngagementTimeSeries(
        widget.event.id, 
        newRange,
      );
      if (mounted) setState(() {});
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detailed Analytics'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Features', icon: Icon(Icons.apps)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Sessions', icon: Icon(Icons.event)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFeaturesTab(),
                _buildUsersTab(),
                _buildSessionsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_analytics == null) return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRangeSelector(),
          const SizedBox(height: 24),
          _buildEngagementTimeSeriesChart(),
          const SizedBox(height: 24),
          _buildMetricsComparison(),
          const SizedBox(height: 24),
          _buildTrendAnalysis(),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureUsageOverview(),
          const SizedBox(height: 24),
          _buildFeatureBreakdown(),
          const SizedBox(height: 24),
          _buildFeatureAdoptionChart(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserOverview(),
          const SizedBox(height: 24),
          _buildUserBehaviorCharts(),
          const SizedBox(height: 24),
          _buildDemographics(),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionOverview(),
          const SizedBox(height: 24),
          _buildSessionPerformance(),
          const SizedBox(height: 24),
          _buildAttendanceAnalysis(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TimeRange.values.map((range) {
                  final isSelected = _selectedTimeRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getTimeRangeLabel(range)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) _updateTimeRange(range);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementTimeSeriesChart() {
    if (_timeSeriesData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Over Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _timeSeriesData.length) {
                            return Text(
                              _formatTimeLabel(_timeSeriesData[index].timestamp),
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
                      spots: _timeSeriesData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
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
    );
  }

  Widget _buildMetricsComparison() {
    if (_analytics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _analytics!.keyMetrics.map((m) => m.value).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _analytics!.keyMetrics.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _analytics!.keyMetrics[index].name.split(' ')[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _analytics!.keyMetrics.asMap().entries.map((entry) {
                    final metric = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: metric.value,
                          color: Theme.of(context).primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    if (_analytics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._analytics!.keyMetrics.take(4).map((metric) {
              return _buildTrendItem(metric);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(AnalyticsMetric metric) {
    final changePercentage = metric.changePercentage ?? 0.0;
    final isPositive = changePercentage > 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              metric.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              '${metric.value.toStringAsFixed(0)}${metric.unit}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${changePercentage.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureUsageOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Usage Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildFeatureCard('Community', _featureUsage['community_board'] ?? {}, Icons.forum),
                _buildFeatureCard('Photos', _featureUsage['photo_gallery'] ?? {}, Icons.photo_library),
                _buildFeatureCard('Announcements', _featureUsage['announcements'] ?? {}, Icons.campaign),
                _buildFeatureCard('Messaging', {'total_messages': 150}, Icons.message),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, Map<String, dynamic> data, IconData icon) {
    final primaryValue = data.values.isNotEmpty ? data.values.first.toString() : '0';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const Spacer(),
              Text(
                primaryValue,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildFeatureBreakdown() {
    if (_analytics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Usage Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._analytics!.engagement.featureUsage.entries.map((entry) {
              final total = _analytics!.engagement.featureUsage.values.fold(0, (sum, value) => sum + value);
              final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_getFeatureLabel(entry.key)),
                        Text('${entry.value} (${percentage.toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
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

  Widget _buildFeatureAdoptionChart() {
    if (_analytics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Adoption',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: _analytics!.engagement.featureUsage.entries.take(6).map((entry) {
                    final total = _analytics!.engagement.featureUsage.values.fold(0, (sum, value) => sum + value);
                    final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
                    return PieChartSectionData(
                      color: _getFeatureColor(entry.key),
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStatCard('Total Users', '${_userBehavior['total_users'] ?? 0}', Icons.people),
                _buildStatCard('Profile Completion', '${((_userBehavior['profile_completion_rate'] ?? 0.0) * 100).toStringAsFixed(1)}%', Icons.person),
                _buildStatCard('Networking Enabled', '${_userBehavior['networking_enabled'] ?? 0}', Icons.connect_without_contact),
                _buildStatCard('Messaging Active', '${_userBehavior['messaging_enabled'] ?? 0}', Icons.message),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBehaviorCharts() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Behavior Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'User behavior charts would be displayed here',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographics() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demographics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Demographic charts would be displayed here',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStatCard('Total Sessions', '${_sessionAnalytics['total_sessions'] ?? 0}', Icons.event),
                _buildStatCard('Total Registrations', '${_sessionAnalytics['total_registrations'] ?? 0}', Icons.how_to_reg),
                _buildStatCard('Avg Attendance', '${(_sessionAnalytics['average_attendance_per_session'] ?? 0.0).toStringAsFixed(1)}', Icons.people),
                _buildStatCard('Capacity Used', '${((_sessionAnalytics['capacity_utilization'] ?? 0.0) * 100).toStringAsFixed(1)}%', Icons.event_seat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionPerformance() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Session performance charts would be displayed here',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceAnalysis() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Attendance analysis charts would be displayed here',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeRangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.hourly:
        return 'Hourly';
      case TimeRange.daily:
        return 'Daily';
      case TimeRange.weekly:
        return 'Weekly';
      case TimeRange.monthly:
        return 'Monthly';
      case TimeRange.custom:
        return 'Custom';
    }
  }

  String _formatTimeLabel(DateTime timestamp) {
    switch (_selectedTimeRange) {
      case TimeRange.hourly:
        return DateFormat('HH:mm').format(timestamp);
      case TimeRange.daily:
        return DateFormat('MMM dd').format(timestamp);
      case TimeRange.weekly:
        return DateFormat('MMM dd').format(timestamp);
      case TimeRange.monthly:
        return DateFormat('MMM').format(timestamp);
      case TimeRange.custom:
        return DateFormat('MMM dd').format(timestamp);
    }
  }

  String _getFeatureLabel(String feature) {
    switch (feature) {
      case 'community_posts':
        return 'Community';
      case 'photo_uploads':
        return 'Photos';
      case 'messages_sent':
        return 'Messages';
      case 'announcements_read':
        return 'Announcements';
      case 'polls_participated':
        return 'Polls';
      case 'sessions_attended':
        return 'Sessions';
      case 'check_ins':
        return 'Check-ins';
      case 'profile_updates':
        return 'Profiles';
      default:
        return feature.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  Color _getFeatureColor(String feature) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    final index = feature.hashCode % colors.length;
    return colors[index.abs()];
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'export':
        try {
          final exportData = await _analyticsService.exportAnalyticsData(widget.event.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Analytics data exported successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error exporting data: $e')),
            );
          }
        }
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share functionality would be implemented here')),
        );
        break;
    }
  }
}