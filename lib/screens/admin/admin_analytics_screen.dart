import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '7 days';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Events', icon: Icon(Icons.event)),
            Tab(text: 'Revenue', icon: Icon(Icons.attach_money)),
            Tab(text: 'Engagement', icon: Icon(Icons.trending_up)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedTimeRange = value ?? _selectedTimeRange),
            itemBuilder: (context) => const [
              PopupMenuItem(value: '24 hours', child: Text('Last 24 Hours')),
              PopupMenuItem(value: '7 days', child: Text('Last 7 Days')),
              PopupMenuItem(value: '30 days', child: Text('Last 30 Days')),
              PopupMenuItem(value: '90 days', child: Text('Last 90 Days')),
            ],
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedTimeRange, style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildEventsTab(),
          _buildRevenueTab(),
          _buildEngagementTab(),
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
          _buildMetricsGrid(),
          const SizedBox(height: 24),
          _buildQuickStatsChart(),
          const SizedBox(height: 24),
          _buildTopPerformers(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard('Total Users', '12,485', '+8.2%', Icons.people, Colors.blue),
        _buildMetricCard('Active Events', '23', '+12.5%', Icons.event, Colors.green),
        _buildMetricCard('Total Revenue', '\$45,670', '+15.3%', Icons.attach_money, Colors.purple),
        _buildMetricCard('Avg. Rating', '4.8/5', '+0.2', Icons.star, Colors.orange),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String change, IconData icon, Color color) {
    final isPositive = change.startsWith('+');
    
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
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                        change,
                        style: TextStyle(
                          fontSize: 10,
                          color: isPositive ? Colors.green : Colors.red,
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
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Growth',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 8000),
                        FlSpot(1, 8500),
                        FlSpot(2, 9200),
                        FlSpot(3, 9800),
                        FlSpot(4, 10500),
                        FlSpot(5, 11200),
                        FlSpot(6, 12485),
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
    );
  }

  Widget _buildTopPerformers() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performing Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final eventNames = [
                'Tech Conference 2024',
                'Design Workshop',
                'Startup Meetup',
                'AI Summit',
                'Marketing Seminar'
              ];
              final attendees = [1250, 890, 650, 480, 320];
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventNames[index],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${attendees[index]} attendees',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(100 - index * 15)}% full',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUserDemographicsChart(),
          const SizedBox(height: 24),
          _buildUserActivityChart(),
        ],
      ),
    );
  }

  Widget _buildUserDemographicsChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Demographics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      title: '25-34\n40%',
                      color: Colors.blue,
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: 30,
                      title: '35-44\n30%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '18-24\n20%',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: 10,
                      title: '45+\n10%',
                      color: Colors.purple,
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActivityChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Active Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (800 + index * 100 + (index % 2) * 200).toDouble(),
                          color: Theme.of(context).primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Event Analytics'),
          SizedBox(height: 8),
          Text(
            'Detailed event performance metrics and insights',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Revenue Analytics'),
          SizedBox(height: 8),
          Text(
            'Financial performance and revenue tracking',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Engagement Analytics'),
          SizedBox(height: 8),
          Text(
            'User engagement and interaction metrics',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}