import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/analytics.dart';
import '../../services/analytics_service.dart';
import '../../widgets/custom_fab.dart';
import 'detailed_analytics_screen.dart';
import 'realtime_analytics_screen.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final Event event;

  const AnalyticsDashboardScreen({super.key, required this.event});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  EventAnalytics? _analytics;
  Map<String, dynamic> _realtimeStats = {};
  List<TimeSeriesData> _engagementData = [];
  bool _isLoading = false;
  bool _showRealtime = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _loadRealtimeStats();
    _loadEngagementTimeSeries();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      _analytics = await _analyticsService.generateEventAnalytics(widget.event.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadRealtimeStats() async {
    try {
      _realtimeStats = await _analyticsService.getRealtimeStats(widget.event.id);
      if (mounted) setState(() {});
    } catch (e) {
      // Silently handle error for real-time stats
    }
  }

  Future<void> _loadEngagementTimeSeries() async {
    try {
      _engagementData = await _analyticsService.getEngagementTimeSeries(
        widget.event.id, 
        TimeRange.daily,
      );
      if (mounted) setState(() {});
    } catch (e) {
      // Silently handle error for time series data
    }
  }

  void _navigateToDetailedAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailedAnalyticsScreen(event: widget.event),
      ),
    );
  }

  void _navigateToRealtimeAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealtimeAnalyticsScreen(event: widget.event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analytics Dashboard'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Switch(
            value: _showRealtime,
            onChanged: (value) => setState(() => _showRealtime = value),
          ),
          IconButton(
            onPressed: _navigateToRealtimeAnalytics,
            icon: const Icon(Icons.show_chart),
            tooltip: 'Real-time Analytics',
          ),
          IconButton(
            onPressed: () => _loadAnalytics(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showRealtime) ...[
                      _buildRealtimeOverview(),
                      const SizedBox(height: 24),
                    ],
                    _buildKeyMetricsOverview(),
                    const SizedBox(height: 24),
                    _buildEngagementChart(),
                    const SizedBox(height: 24),
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildFeatureBreakdown(),
                  ],
                ),
              ),
            ),
      floatingActionButton: CustomFAB(
        onPressed: _navigateToDetailedAnalytics,
        icon: Icons.analytics,
        label: 'Detailed View',
      ),
    );
  }

  Widget _buildRealtimeOverview() {
    if (_realtimeStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_checked, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Live Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated now',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRealtimeMetric(
                    'Active Users',
                    '${_realtimeStats['current_active_users'] ?? 0}',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildRealtimeMetric(
                    'This Hour',
                    '${_realtimeStats['check_ins_this_hour'] ?? 0} check-ins',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsOverview() {
    if (_analytics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _analytics!.keyMetrics.length.clamp(0, 4),
              itemBuilder: (context, index) {
                final metric = _analytics!.keyMetrics[index];
                return _buildMetricCard(metric);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(AnalyticsMetric metric) {
    final changePercentage = metric.changePercentage;
    final isPositive = changePercentage != null && changePercentage > 0;
    
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
              _getMetricIcon(metric.type),
              const Spacer(),
              if (changePercentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${changePercentage.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            '${metric.value.toStringAsFixed(metric.unit == '%' ? 1 : 0)}${metric.unit}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementChart() {
    if (_engagementData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Trend (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
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
                          if (index >= 0 && index < _engagementData.length) {
                            return Text(
                              DateFormat('MMM dd').format(_engagementData[index].timestamp),
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
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _engagementData.asMap().entries.map((entry) {
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

  Widget _buildQuickStats() {
    if (_analytics == null) return const SizedBox.shrink();

    final engagement = _analytics!.engagement;
    final networking = _analytics!.networking;
    final sessions = _analytics!.sessions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatItem(
                    'Total Users',
                    '${engagement.totalUsers}',
                    'Active: ${engagement.activeUsers}',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildQuickStatItem(
                    'Sessions',
                    '${sessions.totalSessions}',
                    '${sessions.totalAttendees} attendees',
                    Icons.event,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatItem(
                    'Connections',
                    '${networking.totalConnections}',
                    '${networking.totalMessages} messages',
                    Icons.connect_without_contact,
                  ),
                ),
                Expanded(
                  child: _buildQuickStatItem(
                    'Engagement',
                    '${(engagement.engagementRate * 100).toStringAsFixed(1)}%',
                    '${engagement.totalPageViews} views',
                    Icons.favorite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBreakdown() {
    if (_analytics == null) return const SizedBox.shrink();

    final featureUsage = _analytics!.engagement.featureUsage;
    final totalUsage = featureUsage.values.fold(0, (sum, value) => sum + value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Usage',
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
                  sections: featureUsage.entries.take(6).map((entry) {
                    final percentage = totalUsage > 0 ? (entry.value / totalUsage) * 100 : 0;
                    return PieChartSectionData(
                      color: _getFeatureColor(entry.key),
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 60,
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: featureUsage.entries.take(6).map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getFeatureColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getFeatureLabel(entry.key),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getMetricIcon(MetricType type) {
    IconData iconData;
    Color color = Theme.of(context).primaryColor;

    switch (type) {
      case MetricType.attendance:
        iconData = Icons.people;
        break;
      case MetricType.engagement:
        iconData = Icons.favorite;
        break;
      case MetricType.networking:
        iconData = Icons.connect_without_contact;
        break;
      case MetricType.polls:
        iconData = Icons.poll;
        break;
      case MetricType.checkins:
        iconData = Icons.check_circle;
        break;
      case MetricType.photos:
        iconData = Icons.photo_library;
        break;
      case MetricType.messages:
        iconData = Icons.message;
        break;
      case MetricType.announcements:
        iconData = Icons.campaign;
        break;
      case MetricType.sessions:
        iconData = Icons.event;
        break;
      case MetricType.community:
        iconData = Icons.forum;
        break;
    }

    return Icon(iconData, size: 20, color: color);
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
}