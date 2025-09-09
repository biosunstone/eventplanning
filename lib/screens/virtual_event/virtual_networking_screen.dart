import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/virtual_event.dart';
import '../../services/virtual_event_service.dart';

class VirtualNetworkingScreen extends StatefulWidget {
  final Event event;

  const VirtualNetworkingScreen({super.key, required this.event});

  @override
  State<VirtualNetworkingScreen> createState() => _VirtualNetworkingScreenState();
}

class _VirtualNetworkingScreenState extends State<VirtualNetworkingScreen>
    with SingleTickerProviderStateMixin {
  final VirtualEventService _virtualEventService = VirtualEventService();
  
  List<BreakoutRoom> _breakoutRooms = [];
  bool _isLoading = false;
  late TabController _tabController;
  
  String _currentUserId = 'user1'; // Get from auth provider in real app
  
  final List<Map<String, dynamic>> _networkingTopics = [
    {'title': 'Tech Startups', 'icon': Icons.rocket_launch, 'color': Colors.blue, 'participants': 12},
    {'title': 'AI & Machine Learning', 'icon': Icons.psychology, 'color': Colors.purple, 'participants': 18},
    {'title': 'Web Development', 'icon': Icons.web, 'color': Colors.green, 'participants': 15},
    {'title': 'Mobile Apps', 'icon': Icons.phone_android, 'color': Colors.orange, 'participants': 9},
    {'title': 'Data Science', 'icon': Icons.analytics, 'color': Colors.teal, 'participants': 14},
    {'title': 'Blockchain', 'icon': Icons.link, 'color': Colors.amber, 'participants': 7},
    {'title': 'UX/UI Design', 'icon': Icons.design_services, 'color': Colors.pink, 'participants': 11},
    {'title': 'DevOps', 'icon': Icons.settings, 'color': Colors.indigo, 'participants': 8},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNetworkingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNetworkingData() async {
    setState(() => _isLoading = true);

    try {
      // Create a demo networking session for breakout rooms
      final networkingSessions = await _virtualEventService.getSessionsByType(
        widget.event.id,
        StreamType.networking,
      );
      
      if (networkingSessions.isNotEmpty) {
        _breakoutRooms = await _virtualEventService.getBreakoutRooms(networkingSessions.first.id);
        
        // Generate demo breakout rooms if none exist
        if (_breakoutRooms.isEmpty) {
          await _generateDemoBreakoutRooms(networkingSessions.first.id);
          _breakoutRooms = await _virtualEventService.getBreakoutRooms(networkingSessions.first.id);
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading networking data: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generateDemoBreakoutRooms(String sessionId) async {
    for (int i = 0; i < _networkingTopics.length; i++) {
      final topic = _networkingTopics[i];
      final room = BreakoutRoom(
        id: 'room_${i + 1}',
        sessionId: sessionId,
        name: topic['title'],
        description: 'Connect with others interested in ${topic['title']}',
        maxParticipants: 10,
        participantIds: List.generate((topic['participants'] as int).clamp(0, 10), (index) => 'user_${i}_${index + 1}'),
        createdAt: DateTime.now(),
      );
      await _virtualEventService.createBreakoutRoom(room);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Virtual Networking'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Breakout Rooms', icon: Icon(Icons.groups)),
            Tab(text: 'Speed Networking', icon: Icon(Icons.flash_on)),
            Tab(text: 'Open Chat', icon: Icon(Icons.chat)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadNetworkingData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBreakoutRoomsTab(),
                _buildSpeedNetworkingTab(),
                _buildOpenChatTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _createBreakoutRoom,
              icon: const Icon(Icons.add),
              label: const Text('Create Room'),
            )
          : null,
    );
  }

  Widget _buildBreakoutRoomsTab() {
    return RefreshIndicator(
      onRefresh: _loadNetworkingData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNetworkingOverview(),
            const SizedBox(height: 24),
            _buildTopicRooms(),
            if (_breakoutRooms.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildCustomRooms(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkingOverview() {
    final totalParticipants = _networkingTopics.fold(0, (sum, topic) => sum + (topic['participants'] as int));
    final activeRooms = _networkingTopics.where((topic) => (topic['participants'] as int) > 0).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Networking Hub',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect with fellow attendees in topic-based breakout rooms or through speed networking sessions.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Active Rooms',
                    '$activeRooms',
                    Icons.groups,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildOverviewStat(
                    'Participants',
                    '$totalParticipants',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildOverviewStat(
                    'Topics',
                    '${_networkingTopics.length}',
                    Icons.topic,
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

  Widget _buildOverviewStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
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
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTopicRooms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topic-Based Rooms',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _networkingTopics.length,
          itemBuilder: (context, index) {
            final topic = _networkingTopics[index];
            return _buildTopicRoomCard(topic);
          },
        ),
      ],
    );
  }

  Widget _buildTopicRoomCard(Map<String, dynamic> topic) {
    final participants = topic['participants'] as int;
    final isActive = participants > 0;
    final color = topic['color'] as Color;

    return Card(
      elevation: isActive ? 4 : 1,
      child: InkWell(
        onTap: isActive ? () => _joinTopicRoom(topic) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color.withOpacity(0.3) : Colors.grey[300]!,
              width: 2,
            ),
            color: isActive ? color.withOpacity(0.05) : Colors.grey[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    topic['icon'],
                    color: isActive ? color : Colors.grey,
                    size: 24,
                  ),
                  const Spacer(),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                topic['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isActive ? Colors.black87 : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: isActive ? color : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$participants',
                    style: TextStyle(
                      color: isActive ? color : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'active' : 'waiting',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRooms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Custom Rooms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _createBreakoutRoom,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._breakoutRooms.map((room) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCustomRoomCard(room),
        )),
      ],
    );
  }

  Widget _buildCustomRoomCard(BreakoutRoom room) {
    final isJoined = room.participantIds.contains(_currentUserId);
    final isFull = room.isFull;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isJoined ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
          child: Icon(
            isJoined ? Icons.check : Icons.groups,
            color: isJoined ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          room.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${room.currentParticipants}/${room.maxParticipants}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                if (isFull && !isJoined)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FULL',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: isJoined
            ? TextButton(
                onPressed: () => _leaveRoom(room),
                child: const Text('Leave'),
              )
            : ElevatedButton(
                onPressed: isFull ? null : () => _joinRoom(room),
                child: const Text('Join'),
              ),
        onTap: () => _showRoomDetails(room),
      ),
    );
  }

  Widget _buildSpeedNetworkingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.flash_on,
                    size: 64,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Speed Networking',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quick 5-minute one-on-one conversations with random attendees. Perfect for making new connections!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _startSpeedNetworking,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Speed Networking'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSpeedNetworkingStats(),
        ],
      ),
    );
  }

  Widget _buildSpeedNetworkingStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Speed Networking Stats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Active Sessions',
                    '12',
                    Icons.timer,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Waiting Queue',
                    '8',
                    Icons.queue,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg Rating',
                    '4.7',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Connections Made',
                    '156',
                    Icons.link,
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
            label,
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

  Widget _buildOpenChatTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Open Chat Lounge',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join the general networking chat where everyone can participate in group conversations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _joinOpenChat,
                    icon: const Icon(Icons.forum),
                    label: const Text('Join Open Chat'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chat Guidelines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGuidelineItem('Be respectful and professional'),
                  _buildGuidelineItem('Share your expertise and interests'),
                  _buildGuidelineItem('Ask questions and engage with others'),
                  _buildGuidelineItem('Keep conversations relevant to the event'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _joinTopicRoom(Map<String, dynamic> topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${topic['title']} Room'),
        content: Text('Connect with ${topic['participants']} others interested in ${topic['title']}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined ${topic['title']} room!')),
              );
            },
            child: const Text('Join Room'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom(BreakoutRoom room) async {
    try {
      await _virtualEventService.joinBreakoutRoom(room.id, _currentUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${room.name}" room!')),
      );
      _loadNetworkingData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining room: $e')),
      );
    }
  }

  Future<void> _leaveRoom(BreakoutRoom room) async {
    try {
      await _virtualEventService.leaveBreakoutRoom(room.id, _currentUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Left "${room.name}" room')),
      );
      _loadNetworkingData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving room: $e')),
      );
    }
  }

  void _showRoomDetails(BreakoutRoom room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.description),
            const SizedBox(height: 16),
            Text('Participants: ${room.currentParticipants}/${room.maxParticipants}'),
            const SizedBox(height: 8),
            Text('Created: ${room.createdAt.day}/${room.createdAt.month}/${room.createdAt.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!room.participantIds.contains(_currentUserId) && !room.isFull)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _joinRoom(room);
              },
              child: const Text('Join'),
            ),
        ],
      ),
    );
  }

  void _createBreakoutRoom() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    int maxParticipants = 8;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Breakout Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter room name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What will you discuss?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Max Participants: '),
                const Spacer(),
                DropdownButton<int>(
                  value: maxParticipants,
                  items: [4, 6, 8, 10, 12].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      maxParticipants = value;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                
                // Create the room (this would need a networking session)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created room "${nameController.text.trim()}"')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _startSpeedNetworking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Speed Networking'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on, size: 48, color: Colors.amber),
            SizedBox(height: 16),
            Text('You\'ll be matched with another attendee for a 5-minute conversation. Ready to start?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Looking for a match... This may take a moment.')),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _joinOpenChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening networking chat...')),
    );
  }
}