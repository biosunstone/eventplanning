import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/analytics.dart';
import '../../services/analytics_service.dart';

class RealtimeAnalyticsScreen extends StatefulWidget {
  final Event event;

  const RealtimeAnalyticsScreen({super.key, required this.event});

  @override
  State<RealtimeAnalyticsScreen> createState() => _RealtimeAnalyticsScreenState();
}

class _RealtimeAnalyticsScreenState extends State<RealtimeAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  Map<String, dynamic> _realtimeStats = {};
  List<TimeSeriesData> _realtimeData = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  bool _isPaused = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _loadRealtimeData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isPaused) {
        _loadRealtimeData();
      }
    });
  }

  Future<void> _loadRealtimeData() async {
    if (_isPaused) return;
    
    setState(() => _isLoading = true);

    try {
      final stats = await _analyticsService.getRealtimeStats(widget.event.id);
      final timeSeries = await _analyticsService.getEngagementTimeSeries(
        widget.event.id,
        TimeRange.hourly,
        startDate: DateTime.now().subtract(const Duration(hours: 24)),
        endDate: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _realtimeStats = stats;
          _realtimeData = timeSeries.take(24).toList(); // Last 24 hours
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading real-time data: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _pulseController.stop();
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Real-time Analytics'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPaused ? 1.0 : _pulseAnimation.value,
                child: IconButton(
                  onPressed: _togglePause,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: _isPaused ? Colors.grey : Colors.green,
                  ),
                  tooltip: _isPaused ? 'Resume' : 'Pause',
                ),
              );
            },
          ),
          IconButton(
            onPressed: _loadRealtimeData,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusIndicator(),
            const SizedBox(height: 24),
            _buildLiveMetrics(),
            const SizedBox(height: 24),
            _buildRealtimeChart(),
            const SizedBox(height: 24),
            _buildActivityFeed(),
            const SizedBox(height: 24),
            _buildCurrentSessions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isPaused ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isPaused ? Colors.grey : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              _isPaused ? 'Updates Paused' : 'Live Updates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isPaused ? Colors.grey : Colors.green,
              ),
            ),
            const Spacer(),
            Text(
              'Last updated: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Metrics',
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
                _buildLiveMetricCard(
                  'Active Users',
                  '${_realtimeStats['current_active_users'] ?? 0}',
                  Icons.people,
                  Colors.green,
                  _realtimeStats['current_active_users'] != null,
                ),
                _buildLiveMetricCard(
                  'This Hour',
                  '${_realtimeStats['sessions_this_hour'] ?? 0} sessions',
                  Icons.access_time,
                  Colors.blue,
                  _realtimeStats['sessions_this_hour'] != null,
                ),
                _buildLiveMetricCard(
                  'New Messages',
                  '${_realtimeStats['messages_this_hour'] ?? 0}',
                  Icons.message,
                  Colors.orange,
                  _realtimeStats['messages_this_hour'] != null,
                ),
                _buildLiveMetricCard(
                  'Check-ins',
                  '${_realtimeStats['check_ins_this_hour'] ?? 0}',
                  Icons.check_circle,
                  Colors.purple,
                  _realtimeStats['check_ins_this_hour'] != null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetricCard(
    String title, 
    String value, 
    IconData icon, 
    Color color, 
    bool hasData,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasData ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasData ? color.withOpacity(0.3) : Colors.grey[200]!,
          width: hasData ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: hasData ? color : Colors.grey),
              const Spacer(),
              if (hasData && !_isPaused)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasData ? Colors.black87 : Colors.grey,
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

  Widget _buildRealtimeChart() {
    if (_realtimeData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Over Last 24 Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                  ),
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
                        interval: (_realtimeData.length / 6).ceil().toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _realtimeData.length) {
                            return Text(
                              DateFormat('HH:mm').format(_realtimeData[index].timestamp),
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
                      spots: _realtimeData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (index == _realtimeData.length - 1) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.red,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 2,
                            color: Theme.of(context).primaryColor,
                          );
                        },
                      ),
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

  Widget _buildActivityFeed() {
    final activities = _generateMockActivities();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Live Activity Feed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isPaused)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: const Icon(
                          Icons.fiber_manual_record,
                          size: 12,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _buildActivityItem(activity);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: activity['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['text'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSessions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCurrentSessionItem(
              'Opening Keynote',
              'Main Auditorium',
              245,
              300,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildCurrentSessionItem(
              'AI Workshop',
              'Room B',
              48,
              50,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildCurrentSessionItem(
              'Networking Break',
              'Lobby',
              120,
              200,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSessionItem(
    String title,
    String location,
    int current,
    int capacity,
    Color color,
  ) {
    final percentage = capacity > 0 ? (current / capacity) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$current/$capacity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateMockActivities() {
    final now = DateTime.now();
    return [
      {
        'text': 'John Doe joined the networking session',
        'time': DateFormat('HH:mm').format(now.subtract(const Duration(minutes: 1))),
        'color': Colors.green,
      },
      {
        'text': 'New poll created: "What\'s your favorite session?"',
        'time': DateFormat('HH:mm').format(now.subtract(const Duration(minutes: 3))),
        'color': Colors.blue,
      },
      {
        'text': '15 people checked into the AI Workshop',
        'time': DateFormat('HH:mm').format(now.subtract(const Duration(minutes: 5))),
        'color': Colors.orange,
      },
      {
        'text': 'Photo uploaded to the event gallery',
        'time': DateFormat('HH:mm').format(now.subtract(const Duration(minutes: 7))),
        'color': Colors.purple,
      },
      {
        'text': 'Announcement: "Coffee break extended by 10 minutes"',
        'time': DateFormat('HH:mm').format(now.subtract(const Duration(minutes: 12))),
        'color': Colors.red,
      },
    ];
  }
}