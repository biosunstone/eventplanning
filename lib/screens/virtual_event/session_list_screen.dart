import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/virtual_event.dart';
import '../../services/virtual_event_service.dart';
import 'live_stream_screen.dart';

class SessionListScreen extends StatefulWidget {
  final Event event;

  const SessionListScreen({super.key, required this.event});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen>
    with SingleTickerProviderStateMixin {
  final VirtualEventService _virtualEventService = VirtualEventService();
  
  List<VirtualSession> _allSessions = [];
  List<VirtualSession> _filteredSessions = [];
  bool _isLoading = false;
  late TabController _tabController;
  String _selectedType = 'all';
  
  final List<Map<String, dynamic>> _sessionTypes = [
    {'key': 'all', 'label': 'All Sessions', 'icon': Icons.list},
    {'key': 'keynote', 'label': 'Keynotes', 'icon': Icons.campaign},
    {'key': 'workshop', 'label': 'Workshops', 'icon': Icons.build},
    {'key': 'panel', 'label': 'Panels', 'icon': Icons.people},
    {'key': 'networking', 'label': 'Networking', 'icon': Icons.connect_without_contact},
    {'key': 'qa_session', 'label': 'Q&A', 'icon': Icons.help_outline},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    try {
      _allSessions = await _virtualEventService.getEventSessions(widget.event.id);
      _filterSessions();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _filterSessions() {
    if (_selectedType == 'all') {
      _filteredSessions = List.from(_allSessions);
    } else {
      final type = StreamType.values.firstWhere((t) => t.name == _selectedType);
      _filteredSessions = _allSessions.where((session) => session.type == type).toList();
    }
    
    // Sort by scheduled start time
    _filteredSessions.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
  }

  List<VirtualSession> _getSessionsByStatus(StreamStatus status) {
    return _filteredSessions.where((session) => session.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Virtual Sessions'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Live',
              icon: const Icon(Icons.play_circle),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle),
                  const SizedBox(width: 4),
                  Text('Live (${_getSessionsByStatus(StreamStatus.live).length})'),
                ],
              ),
            ),
            Tab(
              text: 'Upcoming',
              icon: const Icon(Icons.schedule),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 4),
                  Text('Upcoming (${_getSessionsByStatus(StreamStatus.scheduled).length})'),
                ],
              ),
            ),
            Tab(
              text: 'Ended',
              icon: const Icon(Icons.video_library),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library),
                  const SizedBox(width: 4),
                  Text('Ended (${_getSessionsByStatus(StreamStatus.ended).length})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (type) {
              setState(() => _selectedType = type);
              _filterSessions();
              setState(() {});
            },
            itemBuilder: (context) => _sessionTypes.map((type) {
              return PopupMenuItem<String>(
                value: type['key'],
                child: Row(
                  children: [
                    Icon(type['icon'], size: 20),
                    const SizedBox(width: 12),
                    Text(type['label']),
                    if (_selectedType == type['key']) ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Colors.green),
                    ],
                  ],
                ),
              );
            }).toList(),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by type',
          ),
          IconButton(
            onPressed: _loadSessions,
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
                _buildSessionsList(_getSessionsByStatus(StreamStatus.live)),
                _buildSessionsList(_getSessionsByStatus(StreamStatus.scheduled)),
                _buildSessionsList(_getSessionsByStatus(StreamStatus.ended)),
              ],
            ),
    );
  }

  Widget _buildSessionsList(List<VirtualSession> sessions) {
    if (sessions.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;
      
      if (_tabController.index == 0) {
        emptyMessage = 'No live sessions at the moment';
        emptyIcon = Icons.tv_off;
      } else if (_tabController.index == 1) {
        emptyMessage = 'No upcoming sessions';
        emptyIcon = Icons.schedule;
      } else {
        emptyMessage = 'No recorded sessions available';
        emptyIcon = Icons.video_library;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedType != 'all' 
                    ? 'Try changing the filter to see more sessions'
                    : 'Check back later for new sessions',
                style: const TextStyle(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSessionCard(sessions[index]),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(VirtualSession session) {
    final isLive = session.status == StreamStatus.live;
    final isEnded = session.status == StreamStatus.ended;
    final timeFormat = DateFormat('MMM dd, HH:mm');
    
    return Card(
      elevation: isLive ? 8 : 2,
      child: InkWell(
        onTap: () => _handleSessionTap(session),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
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
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(session.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(session.status),
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(session.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${session.duration.inMinutes} min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                if (isLive)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${session.currentViewers}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTypeColor(session.type).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(session.type),
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTypeLabel(session.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLive && !isEnded)
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                if (isEnded && session.recordingUrl != null)
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat.format(session.scheduledStart),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (session.tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: session.tags.take(2).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(session),
                      ),
                      const SizedBox(width: 12),
                      _buildSecondaryButton(session),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(VirtualSession session) {
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    bool isEnabled = true;

    switch (session.status) {
      case StreamStatus.live:
        buttonText = 'Join Live';
        buttonIcon = Icons.play_arrow;
        buttonColor = Colors.red;
        break;
      case StreamStatus.scheduled:
        buttonText = 'Set Reminder';
        buttonIcon = Icons.notifications;
        buttonColor = Colors.blue;
        break;
      case StreamStatus.ended:
        if (session.recordingUrl != null) {
          buttonText = 'Watch Recording';
          buttonIcon = Icons.play_circle;
          buttonColor = Colors.green;
        } else {
          buttonText = 'Recording Unavailable';
          buttonIcon = Icons.video_library_outlined;
          buttonColor = Colors.grey;
          isEnabled = false;
        }
        break;
      default:
        buttonText = 'Unavailable';
        buttonIcon = Icons.block;
        buttonColor = Colors.grey;
        isEnabled = false;
    }

    return ElevatedButton.icon(
      onPressed: isEnabled ? () => _handleActionButton(session) : null,
      icon: Icon(buttonIcon, size: 16),
      label: Text(buttonText, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? buttonColor : Colors.grey[300],
        foregroundColor: isEnabled ? Colors.white : Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _buildSecondaryButton(VirtualSession session) {
    return OutlinedButton(
      onPressed: () => _showSessionDetails(session),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: const Text('Details', style: TextStyle(fontSize: 12)),
    );
  }

  Color _getStatusColor(StreamStatus status) {
    switch (status) {
      case StreamStatus.live:
        return Colors.red;
      case StreamStatus.scheduled:
        return Colors.blue;
      case StreamStatus.ended:
        return Colors.green;
      case StreamStatus.cancelled:
        return Colors.orange;
      case StreamStatus.technical_difficulties:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(StreamStatus status) {
    switch (status) {
      case StreamStatus.live:
        return Icons.circle;
      case StreamStatus.scheduled:
        return Icons.schedule;
      case StreamStatus.ended:
        return Icons.check_circle;
      case StreamStatus.cancelled:
        return Icons.cancel;
      case StreamStatus.technical_difficulties:
        return Icons.warning;
    }
  }

  String _getStatusLabel(StreamStatus status) {
    switch (status) {
      case StreamStatus.live:
        return 'LIVE';
      case StreamStatus.scheduled:
        return 'SCHEDULED';
      case StreamStatus.ended:
        return 'ENDED';
      case StreamStatus.cancelled:
        return 'CANCELLED';
      case StreamStatus.technical_difficulties:
        return 'TECHNICAL ISSUES';
    }
  }

  Color _getTypeColor(StreamType type) {
    switch (type) {
      case StreamType.keynote:
        return Colors.purple;
      case StreamType.workshop:
        return Colors.orange;
      case StreamType.panel:
        return Colors.blue;
      case StreamType.networking:
        return Colors.green;
      case StreamType.qa_session:
        return Colors.teal;
      case StreamType.breakout:
        return Colors.indigo;
      case StreamType.entertainment:
        return Colors.pink;
      case StreamType.exhibition:
        return Colors.brown;
    }
  }

  IconData _getTypeIcon(StreamType type) {
    switch (type) {
      case StreamType.keynote:
        return Icons.campaign;
      case StreamType.workshop:
        return Icons.build;
      case StreamType.panel:
        return Icons.people;
      case StreamType.networking:
        return Icons.connect_without_contact;
      case StreamType.qa_session:
        return Icons.help_outline;
      case StreamType.breakout:
        return Icons.groups;
      case StreamType.entertainment:
        return Icons.celebration;
      case StreamType.exhibition:
        return Icons.store;
    }
  }

  String _getTypeLabel(StreamType type) {
    switch (type) {
      case StreamType.keynote:
        return 'Keynote';
      case StreamType.workshop:
        return 'Workshop';
      case StreamType.panel:
        return 'Panel';
      case StreamType.networking:
        return 'Networking';
      case StreamType.qa_session:
        return 'Q&A';
      case StreamType.breakout:
        return 'Breakout';
      case StreamType.entertainment:
        return 'Entertainment';
      case StreamType.exhibition:
        return 'Exhibition';
    }
  }

  void _handleSessionTap(VirtualSession session) {
    if (session.status == StreamStatus.live) {
      _joinSession(session);
    } else {
      _showSessionDetails(session);
    }
  }

  void _handleActionButton(VirtualSession session) {
    switch (session.status) {
      case StreamStatus.live:
        _joinSession(session);
        break;
      case StreamStatus.scheduled:
        _setReminder(session);
        break;
      case StreamStatus.ended:
        if (session.recordingUrl != null) {
          _watchRecording(session);
        }
        break;
      default:
        break;
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

  void _setReminder(VirtualSession session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for "${session.title}"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _watchRecording(VirtualSession session) {
    // In a real app, this would open a video player for the recording
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening recording for "${session.title}"'),
      ),
    );
  }

  void _showSessionDetails(VirtualSession session) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(session.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(session.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  session.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Type', _getTypeLabel(session.type)),
                _buildDetailRow('Start Time', DateFormat('MMM dd, yyyy • HH:mm').format(session.scheduledStart)),
                _buildDetailRow('Duration', '${session.duration.inMinutes} minutes'),
                if (session.status == StreamStatus.live)
                  _buildDetailRow('Current Viewers', '${session.currentViewers}'),
                if (session.maxAttendees > 0)
                  _buildDetailRow('Max Attendees', '${session.maxAttendees}'),
                if (session.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: session.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(session),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}