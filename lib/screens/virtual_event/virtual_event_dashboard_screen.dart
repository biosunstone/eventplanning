import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/virtual_event.dart';
import '../../services/virtual_event_service.dart';
import '../../widgets/custom_fab.dart';
import 'live_stream_screen.dart';
import 'session_list_screen.dart';
import 'virtual_networking_screen.dart';

class VirtualEventDashboardScreen extends StatefulWidget {
  final Event event;

  const VirtualEventDashboardScreen({super.key, required this.event});

  @override
  State<VirtualEventDashboardScreen> createState() => _VirtualEventDashboardScreenState();
}

class _VirtualEventDashboardScreenState extends State<VirtualEventDashboardScreen>
    with SingleTickerProviderStateMixin {
  final VirtualEventService _virtualEventService = VirtualEventService();
  
  List<VirtualSession> _liveSessions = [];
  List<VirtualSession> _upcomingSessions = [];
  Map<String, dynamic> _eventAnalytics = {};
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _loadVirtualEventData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVirtualEventData() async {
    setState(() => _isLoading = true);

    try {
      // Generate demo data if needed
      final existingSessions = await _virtualEventService.getEventSessions(widget.event.id);
      if (existingSessions.isEmpty) {
        await _virtualEventService.generateDemoSessions(widget.event.id);
      }

      final results = await Future.wait([
        _virtualEventService.getLiveSessions(widget.event.id),
        _virtualEventService.getUpcomingSessions(widget.event.id),
        _virtualEventService.getEventAnalytics(widget.event.id),
      ]);

      _liveSessions = results[0] as List<VirtualSession>;
      _upcomingSessions = results[1] as List<VirtualSession>;
      _eventAnalytics = results[2] as Map<String, dynamic>;

      if (mounted) {
        setState(() {});
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading virtual event data: $e')),
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
            const Text('Virtual Event'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showEventAnalytics,
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics',
          ),
          IconButton(
            onPressed: _loadVirtualEventData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVirtualEventData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildLiveStreams(),
                          const SizedBox(height: 24),
                          _buildUpcomingSessions(),
                          const SizedBox(height: 24),
                          _buildEventOverview(),
                          const SizedBox(height: 24),
                          _buildFeaturedContent(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: CustomFAB(
        onPressed: () => _navigateToSessionsList(),
        icon: Icons.list,
        label: 'All Sessions',
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
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Join Live',
                    Icons.play_circle_fill,
                    Colors.red,
                    _liveSessions.isNotEmpty,
                    () => _joinLiveSession(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Schedule',
                    Icons.schedule,
                    Colors.blue,
                    true,
                    () => _navigateToSessionsList(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Networking',
                    Icons.people,
                    Colors.green,
                    true,
                    () => _navigateToNetworking(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Recordings',
                    Icons.video_library,
                    Colors.purple,
                    true,
                    () => _showRecordings(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title, 
    IconData icon, 
    Color color, 
    bool isEnabled, 
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey[400],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isEnabled ? color : Colors.grey[400],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStreams() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_checked, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Live Now',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_liveSessions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_liveSessions.length} live',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_liveSessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.tv_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No live streams at the moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _liveSessions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < _liveSessions.length - 1 ? 16 : 0,
                      ),
                      child: _buildLiveSessionCard(_liveSessions[index]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSessionCard(VirtualSession session) {
    return SizedBox(
      width: 280,
      child: InkWell(
        onTap: () => _joinSession(session),
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 4,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      image: DecorationImage(
                        image: NetworkImage(session.thumbnailUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {},
                      ),
                      color: Colors.grey[300],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getStreamTypeIcon(session.type),
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getStreamTypeLabel(session.type),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${session.currentViewers}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildUpcomingSessions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Coming Up',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _navigateToSessionsList,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_upcomingSessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No upcoming sessions scheduled',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_upcomingSessions.take(3).map((session) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUpcomingSessionCard(session),
                );
              })),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionCard(VirtualSession session) {
    final timeUntil = session.scheduledStart.difference(DateTime.now());
    final timeFormat = DateFormat('HH:mm');
    
    return InkWell(
      onTap: () => _showSessionDetails(session),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(session.thumbnailUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                ),
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getStreamTypeIcon(session.type),
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStreamTypeLabel(session.type),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeFormat.format(session.scheduledStart),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  timeUntil.inHours > 0 
                      ? 'in ${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m'
                      : 'in ${timeUntil.inMinutes}m',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Sessions',
                    '${_eventAnalytics['totalSessions'] ?? 0}',
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Live Now',
                    '${_eventAnalytics['liveSessions'] ?? 0}',
                    Icons.play_circle,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Viewers',
                    '${_eventAnalytics['totalViewers'] ?? 0}',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Engagement',
                    '${(_eventAnalytics['averageEngagement'] ?? 0.0).toStringAsFixed(1)}%',
                    Icons.favorite,
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
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              'Interactive Q&A',
              'Engage with speakers in real-time',
              Icons.help_outline,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Breakout Rooms',
              'Connect in small group discussions',
              Icons.groups,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Live Reactions',
              'Express yourself during sessions',
              Icons.emoji_emotions,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Session Recordings',
              'Catch up on missed content',
              Icons.video_library,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStreamTypeIcon(StreamType type) {
    switch (type) {
      case StreamType.keynote:
        return Icons.campaign;
      case StreamType.breakout:
        return Icons.groups;
      case StreamType.workshop:
        return Icons.build;
      case StreamType.panel:
        return Icons.people;
      case StreamType.networking:
        return Icons.connect_without_contact;
      case StreamType.entertainment:
        return Icons.celebration;
      case StreamType.exhibition:
        return Icons.store;
      case StreamType.qa_session:
        return Icons.help_outline;
    }
  }

  String _getStreamTypeLabel(StreamType type) {
    switch (type) {
      case StreamType.keynote:
        return 'Keynote';
      case StreamType.breakout:
        return 'Breakout';
      case StreamType.workshop:
        return 'Workshop';
      case StreamType.panel:
        return 'Panel';
      case StreamType.networking:
        return 'Networking';
      case StreamType.entertainment:
        return 'Entertainment';
      case StreamType.exhibition:
        return 'Exhibition';
      case StreamType.qa_session:
        return 'Q&A Session';
    }
  }

  void _joinLiveSession() {
    if (_liveSessions.isNotEmpty) {
      _joinSession(_liveSessions.first);
    }
  }

  void _joinSession(VirtualSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveStreamScreen(
          event: widget.event,
          session: session,
        ),
      ),
    );
  }

  void _navigateToSessionsList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionListScreen(event: widget.event),
      ),
    );
  }

  void _navigateToNetworking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VirtualNetworkingScreen(event: widget.event),
      ),
    );
  }

  void _showSessionDetails(VirtualSession session) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                session.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(session.scheduledStart),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Start Time'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${session.duration.inMinutes} min',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Duration'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventAnalytics() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Event Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._eventAnalytics.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key.replaceAll('_', ' ').split(' ').map((word) => 
                        word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
                      ).join(' ')),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recordings feature would be implemented here')),
    );
  }
}