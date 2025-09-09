import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../sessions/session_agenda_screen.dart';
import '../networking/networking_screen.dart';
import '../community/community_board_screen.dart';
import '../gallery/photo_gallery_screen.dart';
import '../announcements/announcements_screen.dart';
import '../polls/live_polling_screen.dart';
import '../checkin/checkin_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info)),
            Tab(text: 'Sessions', icon: Icon(Icons.schedule)),
            Tab(text: 'Community', icon: Icon(Icons.people)),
            Tab(text: 'Features', icon: Icon(Icons.apps)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSessionsTab(),
          _buildCommunityTab(),
          _buildFeaturesTab(),
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
          // Event Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(widget.event.dateTime),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.event.location,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Event Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Attendees',
                          '${widget.event.currentAttendees}',
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Sessions',
                          '8', // Demo value
                          Icons.schedule,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return SessionAgendaScreen(event: widget.event);
  }

  Widget _buildCommunityTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommunityBoardScreen(event: widget.event),
                      ),
                    );
                  },
                  icon: const Icon(Icons.forum),
                  label: const Text('Discussion Board'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PhotoGalleryScreen(event: widget.event),
                      ),
                    );
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Photo Gallery'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: NetworkingScreen(event: widget.event),
        ),
      ],
    );
  }

  Widget _buildFeaturesTab() {
    final features = [
      {
        'title': 'Live Polling',
        'subtitle': 'Interactive polls and Q&A',
        'icon': Icons.poll,
        'color': Colors.orange,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LivePollingScreen(event: widget.event),
          ),
        ),
      },
      {
        'title': 'Check-in',
        'subtitle': 'QR code attendance tracking',
        'icon': Icons.qr_code_scanner,
        'color': Colors.purple,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CheckInScreen(event: widget.event),
          ),
        ),
      },
      {
        'title': 'Announcements',
        'subtitle': 'Important event updates',
        'icon': Icons.campaign,
        'color': Colors.red,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnnouncementsScreen(event: widget.event),
          ),
        ),
      },
      {
        'title': 'Networking',
        'subtitle': 'Connect with attendees',
        'icon': Icons.people,
        'color': Colors.green,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NetworkingScreen(event: widget.event),
          ),
        ),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (feature['color'] as Color).withOpacity(0.1),
              child: Icon(
                feature['icon'] as IconData,
                color: feature['color'] as Color,
              ),
            ),
            title: Text(feature['title'] as String),
            subtitle: Text(feature['subtitle'] as String),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: feature['onTap'] as VoidCallback,
          ),
        );
      },
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}