import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../events/event_detail_screen.dart';
import '../networking/networking_screen.dart';
import '../polls/live_polling_screen.dart';
import '../checkin/checkin_screen.dart';
import '../registration/registration_management_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';
import '../gamification/gamification_dashboard_screen.dart';
import '../virtual_event/virtual_event_dashboard_screen.dart';
import '../sponsors/sponsor_directory_screen.dart';
import '../website/website_builder_screen.dart';
import '../community/community_board_screen.dart';
import '../messaging/conversations_screen.dart';
import '../gallery/photo_gallery_screen.dart';
import '../announcements/announcements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late TabController _tabController;
  
  List<Event> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      // Generate demo events if none exist
      final existingEvents = await _eventService.getEvents();
      if (existingEvents.isEmpty) {
        await _eventService.generateDemoEvents();
      }
      
      _events = await _eventService.getEvents();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Planning App'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Events', icon: Icon(Icons.event)),
            Tab(text: 'Features', icon: Icon(Icons.apps)),
            Tab(text: 'Management', icon: Icon(Icons.admin_panel_settings)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventsTab(),
                _buildFeaturesTab(),
                _buildManagementTab(),
              ],
            ),
    );
  }

  Widget _buildEventsTab() {
    if (_events.isEmpty) {
      return _buildEmptyState(
        'No Events Yet',
        'Events will appear here once they are created',
        Icons.event_note,
        () => _loadEvents(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade600,
                child: const Icon(Icons.event, color: Colors.white),
              ),
              title: Text(event.title),
              subtitle: Text('${event.description}\n${_formatDate(event.dateTime)}'),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _navigateToEventDetail(event),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturesTab() {
    if (_events.isEmpty) {
      return _buildEmptyState(
        'Create an Event First',
        'Features will be available once you have events',
        Icons.apps,
        () => _loadEvents(),
      );
    }

    final features = [
      {
        'title': 'Networking',
        'subtitle': 'Smart attendee matching',
        'icon': Icons.people,
        'color': Colors.green,
        'onTap': () => _navigateToFeature('networking'),
      },
      {
        'title': 'Live Polling',
        'subtitle': 'Real-time audience engagement',
        'icon': Icons.poll,
        'color': Colors.orange,
        'onTap': () => _navigateToFeature('polling'),
      },
      {
        'title': 'Check-in',
        'subtitle': 'QR code attendance tracking',
        'icon': Icons.qr_code_scanner,
        'color': Colors.purple,
        'onTap': () => _navigateToFeature('checkin'),
      },
      {
        'title': 'Community',
        'subtitle': 'Social interaction board',
        'icon': Icons.forum,
        'color': Colors.teal,
        'onTap': () => _navigateToFeature('community'),
      },
      {
        'title': 'Photo Gallery',
        'subtitle': 'Event photo sharing',
        'icon': Icons.photo_library,
        'color': Colors.pink,
        'onTap': () => _navigateToFeature('gallery'),
      },
      {
        'title': 'Messaging',
        'subtitle': 'Direct communication',
        'icon': Icons.message,
        'color': Colors.indigo,
        'onTap': () => _navigateToFeature('messaging'),
      },
      {
        'title': 'Announcements',
        'subtitle': 'Event notifications',
        'icon': Icons.campaign,
        'color': Colors.red,
        'onTap': () => _navigateToFeature('announcements'),
      },
      {
        'title': 'Gamification',
        'subtitle': 'Points and achievements',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'onTap': () => _navigateToFeature('gamification'),
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          child: InkWell(
            onTap: feature['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: 40,
                    color: feature['color'] as Color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feature['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildManagementTab() {
    if (_events.isEmpty) {
      return _buildEmptyState(
        'Management Tools',
        'Create an event to access management features',
        Icons.admin_panel_settings,
        () => _loadEvents(),
      );
    }

    final managementFeatures = [
      {
        'title': 'Registration',
        'subtitle': 'Ticket sales & attendee management',
        'icon': Icons.confirmation_number,
        'color': Colors.blue,
        'onTap': () => _navigateToManagement('registration'),
      },
      {
        'title': 'Analytics',
        'subtitle': 'Event insights & reporting',
        'icon': Icons.analytics,
        'color': Colors.green,
        'onTap': () => _navigateToManagement('analytics'),
      },
      {
        'title': 'Virtual Events',
        'subtitle': 'Live streaming platform',
        'icon': Icons.video_call,
        'color': Colors.red,
        'onTap': () => _navigateToManagement('virtual'),
      },
      {
        'title': 'Sponsors',
        'subtitle': 'Sponsor & exhibitor management',
        'icon': Icons.business,
        'color': Colors.orange,
        'onTap': () => _navigateToManagement('sponsors'),
      },
      {
        'title': 'Website Builder',
        'subtitle': 'Create event websites',
        'icon': Icons.web,
        'color': Colors.purple,
        'onTap': () => _navigateToManagement('website'),
      },
      {
        'title': 'Admin Panel',
        'subtitle': 'System administration',
        'icon': Icons.admin_panel_settings,
        'color': Colors.indigo,
        'onTap': () => Navigator.pushNamed(context, '/admin'),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: managementFeatures.length,
      itemBuilder: (context, index) {
        final feature = managementFeatures[index];
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon, VoidCallback onRefresh) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  void _navigateToFeature(String featureType) {
    if (_events.isEmpty) return;
    
    final event = _events.first;
    
    switch (featureType) {
      case 'networking':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NetworkingScreen(event: event),
          ),
        );
        break;
      case 'polling':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LivePollingScreen(event: event),
          ),
        );
        break;
      case 'checkin':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CheckInScreen(event: event),
          ),
        );
        break;
      case 'community':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CommunityBoardScreen(event: event),
          ),
        );
        break;
      case 'gallery':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoGalleryScreen(event: event),
          ),
        );
        break;
      case 'messaging':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ConversationsScreen(),
          ),
        );
        break;
      case 'announcements':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnnouncementsScreen(event: event),
          ),
        );
        break;
      case 'gamification':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GamificationDashboardScreen(
              event: event,
            ),
          ),
        );
        break;
    }
  }

  void _navigateToManagement(String managementType) {
    if (_events.isEmpty) return;
    
    final event = _events.first;
    
    switch (managementType) {
      case 'registration':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RegistrationManagementScreen(event: event),
          ),
        );
        break;
      case 'analytics':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnalyticsDashboardScreen(event: event),
          ),
        );
        break;
      case 'virtual':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VirtualEventDashboardScreen(event: event),
          ),
        );
        break;
      case 'sponsors':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SponsorDirectoryScreen(event: event),
          ),
        );
        break;
      case 'website':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WebsiteBuilderScreen(event: event),
          ),
        );
        break;
    }
  }
}