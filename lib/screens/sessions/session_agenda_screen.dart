import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/session.dart';
import '../../services/session_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_fab.dart';

class SessionAgendaScreen extends StatefulWidget {
  final Event event;

  const SessionAgendaScreen({super.key, required this.event});

  @override
  State<SessionAgendaScreen> createState() => _SessionAgendaScreenState();
}

class _SessionAgendaScreenState extends State<SessionAgendaScreen>
    with SingleTickerProviderStateMixin {
  final SessionService _sessionService = SessionService();
  late TabController _tabController;
  
  List<Session> _sessions = [];
  Map<String, List<Session>> _sessionsByDay = {};
  List<Session> _personalizedAgenda = [];
  bool _isLoading = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

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
      _sessions = await _sessionService.getEventSessions(widget.event.id);
      _sessionsByDay = await _sessionService.groupSessionsByDay(widget.event.id);
      _personalizedAgenda = await _sessionService.generatePersonalizedAgenda(
        widget.event.id, 
        _currentUserId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _navigateToCreateSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session creation feature - functionality demonstrated')),
    );
  }

  void _navigateToSessionDetail(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session.description.isNotEmpty) ...[
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(session.description),
                SizedBox(height: 16),
              ],
              Text(
                'Time:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}'),
              SizedBox(height: 16),
              if (session.location != null) ...[
                Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(session.location!),
                SizedBox(height: 16),
              ],
              Text(
                'Format:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(session.format.toString().split('.').last),
              SizedBox(height: 16),
              Text(
                'Attendees:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('${session.attendeeIds.length} registered'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Session registration feature - functionality demonstrated')),
              );
            },
            child: Text('Register'),
          ),
        ],
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
            const Text('Event Agenda'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToCreateSession,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Session',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Agenda', icon: Icon(Icons.bookmark)),
            Tab(text: 'All Sessions', icon: Icon(Icons.event_note)),
            Tab(text: 'By Day', icon: Icon(Icons.calendar_view_day)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalizedAgendaTab(),
                _buildAllSessionsTab(),
                _buildDayViewTab(),
              ],
            ),
      floatingActionButton: CustomFAB(
        onPressed: _navigateToCreateSession,
        icon: Icons.add,
        label: 'Add Session',
      ),
    );
  }

  Widget _buildPersonalizedAgendaTab() {
    if (_personalizedAgenda.isEmpty) {
      return _buildEmptyState(
        'No agenda items',
        'Register for sessions to build your personalized agenda',
        Icons.bookmark_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _personalizedAgenda.length,
      itemBuilder: (context, index) {
        final session = _personalizedAgenda[index];
        return _buildSessionCard(session, showRegistrationStatus: true);
      },
    );
  }

  Widget _buildAllSessionsTab() {
    if (_sessions.isEmpty) {
      return _buildEmptyState(
        'No sessions created',
        'Create your first session to build the event agenda',
        Icons.event_note_outlined,
      );
    }

    return Column(
      children: [
        _buildSessionFilters(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _sessions.length,
            itemBuilder: (context, index) {
              final session = _sessions[index];
              return _buildSessionCard(session);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayViewTab() {
    if (_sessionsByDay.isEmpty) {
      return _buildEmptyState(
        'No sessions scheduled',
        'Add sessions to see them organized by day',
        Icons.calendar_view_day_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessionsByDay.keys.length,
      itemBuilder: (context, index) {
        final dateKey = _sessionsByDay.keys.elementAt(index);
        final daySessions = _sessionsByDay[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
'${_getDayName(date.weekday)}, ${_getMonthName(date.month)} ${date.day}, ${date.year}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            ...daySessions.map((session) => _buildSessionCard(session)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(Session session, {bool showRegistrationStatus = false}) {
    final isRegistered = session.attendeeIds.contains(_currentUserId);
    final conflicts = _sessions.where((s) => 
      s.id != session.id && 
      s.startTime.isBefore(session.endTime) && 
      s.endTime.isAfter(session.startTime) &&
      s.attendeeIds.contains(_currentUserId)
    ).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isRegistered ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRegistered 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _navigateToSessionDetail(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSessionTypeChip(session.type),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.duration.inMinutes} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    session.format == SessionFormat.virtual 
                        ? Icons.video_call 
                        : session.format == SessionFormat.hybrid
                            ? Icons.devices
                            : Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      session.isVirtual 
                          ? 'Virtual Session'
                          : session.location ?? 'Location TBD',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              if (session.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  session.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (conflicts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Schedule conflict',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (session.attendeeIds.isNotEmpty) ...[
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${session.attendeeIds.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (session.maxAttendees > 0) ...[
                      Text(
                        '/${session.maxAttendees}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                  ],
                  if (session.tags.isNotEmpty) ...[
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: session.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (showRegistrationStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isRegistered 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRegistered ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 14,
                            color: isRegistered ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRegistered ? 'Registered' : 'Available',
                            style: TextStyle(
                              color: isRegistered ? Colors.green : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  Widget _buildSessionTypeChip(SessionType type) {
    Color color;
    IconData icon;
    
    switch (type) {
      case SessionType.keynote:
        color = Colors.purple;
        icon = Icons.star;
        break;
      case SessionType.presentation:
        color = Colors.blue;
        icon = Icons.present_to_all;
        break;
      case SessionType.workshop:
        color = Colors.green;
        icon = Icons.build;
        break;
      case SessionType.panel:
        color = Colors.orange;
        icon = Icons.group;
        break;
      case SessionType.networking:
        color = Colors.pink;
        icon = Icons.people;
        break;
      default:
        color = Colors.grey;
        icon = Icons.event;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', true),
            _buildFilterChip('Keynote', false),
            _buildFilterChip('Workshop', false),
            _buildFilterChip('Panel', false),
            _buildFilterChip('Virtual', false),
            _buildFilterChip('In-Person', false),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Implement filtering logic
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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
            onPressed: _navigateToCreateSession,
            icon: const Icon(Icons.add),
            label: const Text('Create Session'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}