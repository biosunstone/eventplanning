import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/sponsor.dart';
import '../../services/sponsor_service.dart';

class BoothDetailScreen extends StatefulWidget {
  final Event event;
  final ExhibitorBooth booth;

  const BoothDetailScreen({
    super.key,
    required this.event,
    required this.booth,
  });

  @override
  State<BoothDetailScreen> createState() => _BoothDetailScreenState();
}

class _BoothDetailScreenState extends State<BoothDetailScreen>
    with SingleTickerProviderStateMixin {
  final SponsorService _sponsorService = SponsorService();
  
  Sponsor? _sponsor;
  List<SponsorLead> _leads = [];
  bool _isLoading = false;
  late TabController _tabController;

  final String _currentUserId = 'user1'; // Get from auth in real app

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBoothData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBoothData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _sponsorService.getSponsor(widget.booth.sponsorId),
        _sponsorService.getBoothLeads(widget.booth.id),
      ]);

      _sponsor = results[0] as Sponsor?;
      _leads = results[1] as List<SponsorLead>;
      
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booth data: $e')),
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
            Text(widget.booth.name),
            if (_sponsor != null)
              Text(
                _sponsor!.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showBoothActions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBoothHeader(),
                _buildTabSection(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startChat,
        icon: const Icon(Icons.chat),
        label: const Text('Contact Staff'),
      ),
    );
  }

  Widget _buildBoothHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getBoothTypeColor(widget.booth.type).withOpacity(0.1),
            _getBoothTypeColor(widget.booth.type).withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getBoothTypeColor(widget.booth.type),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getBoothTypeIcon(widget.booth.type),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.booth.typeDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: widget.booth.isActive ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.booth.isActive ? 'Open' : 'Closed',
                style: TextStyle(
                  color: widget.booth.isActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.booth.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              height: 1.4,
            ),
          ),
          if (widget.booth.location != null) ...[ 
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  widget.booth.location!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Visitors',
            '${widget.booth.totalVisitors}',
            Icons.people,
            Colors.blue,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Staff',
            '${widget.booth.staffCount}',
            Icons.badge,
            Colors.green,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Resources',
            '${_getTotalResources()}',
            Icons.folder,
            Colors.orange,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Leads',
            '${_leads.length}',
            Icons.contact_mail,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.info)),
              Tab(text: 'Resources', icon: Icon(Icons.folder)),
              Tab(text: 'Staff', icon: Icon(Icons.people)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildResourcesTab(),
                _buildStaffTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
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
          if (_sponsor != null) ...[ 
            _buildSponsorInfo(),
            const SizedBox(height: 24),
          ],
          _buildBoothFeatures(),
          const SizedBox(height: 24),
          _buildVisitActions(),
        ],
      ),
    );
  }

  Widget _buildSponsorInfo() {
    if (_sponsor == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About the Sponsor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    image: DecorationImage(
                      image: NetworkImage(_sponsor!.logoUrl),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {},
                    ),
                    color: Colors.grey[200],
                  ),
                  child: _sponsor!.logoUrl.isEmpty
                      ? Icon(Icons.business, color: Colors.grey[500])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sponsor!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sponsor!.tierDisplayName,
                        style: TextStyle(
                          color: _getTierColor(_sponsor!.tier),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _viewSponsorProfile(),
                  child: const Text('View Profile'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _sponsor!.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoothFeatures() {
    final features = [
      if (widget.booth.isVirtual) 'Virtual Experience',
      if (widget.booth.isPhysical) 'Physical Location',
      if (widget.booth.hasResources) 'Digital Resources',
      'Live Chat Support',
      'Lead Collection',
      if (widget.booth.virtualRoomUrl != null) 'Video Conferencing',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booth Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(feature),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get Started',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat with Staff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestDemo,
                    icon: const Icon(Icons.play_circle),
                    label: const Text('Request Demo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _shareContact,
                icon: const Icon(Icons.contacts),
                label: const Text('Share My Contact Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    if (!widget.booth.hasResources) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No resources available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'This booth doesn\'t have digital resources to share',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...widget.booth.resources.entries.map((entry) {
          final category = entry.key;
          final resources = entry.value as List<dynamic>;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildResourceCategory(category, resources),
          );
        }),
      ],
    );
  }

  Widget _buildResourceCategory(String category, List<dynamic> resources) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getResourceIcon(category),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${resources.length}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...resources.map((resource) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildResourceItem(resource.toString()),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(String resource) {
    return ListTile(
      leading: const Icon(Icons.description, color: Colors.blue),
      title: Text(resource),
      trailing: const Icon(Icons.download),
      onTap: () => _downloadResource(resource),
      dense: true,
    );
  }

  Widget _buildStaffTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Staff',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (widget.booth.staffIds.isEmpty)
                  const Text(
                    'No staff information available',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...widget.booth.staffIds.map((staffId) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildStaffItem(staffId),
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffItem(String staffId) {
    // In a real app, you'd fetch staff details from a user service
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text('Staff Member $staffId'),
      subtitle: const Text('Booth Representative'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _chatWithStaff(staffId),
            icon: const Icon(Icons.chat, color: Colors.blue),
            tooltip: 'Chat',
          ),
          IconButton(
            onPressed: () => _scheduleCall(staffId),
            icon: const Icon(Icons.videocam, color: Colors.green),
            tooltip: 'Schedule Call',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final analytics = widget.booth.analytics;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booth Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (analytics.isEmpty)
                  const Text(
                    'No analytics data available',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...analytics.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAnalyticsItem(entry.key, entry.value),
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsItem(String key, dynamic value) {
    final displayKey = key.replaceAll('_', ' ').split(' ').map((word) => 
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
    ).join(' ');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          displayKey,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getBoothTypeColor(BoothType type) {
    switch (type) {
      case BoothType.virtual:
        return Colors.blue;
      case BoothType.physical:
        return Colors.green;
      case BoothType.hybrid:
        return Colors.purple;
    }
  }

  IconData _getBoothTypeIcon(BoothType type) {
    switch (type) {
      case BoothType.virtual:
        return Icons.computer;
      case BoothType.physical:
        return Icons.location_on;
      case BoothType.hybrid:
        return Icons.device_hub;
    }
  }

  Color _getTierColor(SponsorTier tier) {
    switch (tier) {
      case SponsorTier.platinum:
        return const Color(0xFF9CA3AF);
      case SponsorTier.gold:
        return const Color(0xFFD97706);
      case SponsorTier.silver:
        return const Color(0xFF6B7280);
      case SponsorTier.bronze:
        return const Color(0xFFA16207);
      case SponsorTier.startup:
        return Colors.purple;
      case SponsorTier.community:
        return Colors.green;
    }
  }

  IconData _getResourceIcon(String category) {
    switch (category.toLowerCase()) {
      case 'brochures':
        return Icons.description;
      case 'videos':
        return Icons.play_circle;
      case 'whitepapers':
        return Icons.article;
      case 'demos':
        return Icons.play_arrow;
      case 'research':
        return Icons.science;
      case 'guides':
        return Icons.help;
      default:
        return Icons.folder;
    }
  }

  int _getTotalResources() {
    return widget.booth.resources.values.fold(0, (sum, resources) => 
      sum + (resources as List).length);
  }

  void _startChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting chat with booth staff...')),
    );
  }

  void _requestDemo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Demo'),
        content: const Text('Would you like to schedule a product demonstration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo request sent!')),
              );
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _shareContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Contact Info'),
        content: const Text('Share your contact information with this exhibitor for follow-up?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact info shared!')),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _downloadResource(String resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading $resource...')),
    );
  }

  void _chatWithStaff(String staffId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting chat with $staffId...')),
    );
  }

  void _scheduleCall(String staffId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scheduling call with $staffId...')),
    );
  }

  void _viewSponsorProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening sponsor profile...')),
    );
  }

  void _showBoothActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Booth Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Save Booth'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Booth'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Issue'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}