import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../widgets/custom_button.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late TabController _tabController;
  
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final events = await _eventService.getAllEvents();
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  void _createEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event creation feature - Navigate to detailed form')),
    );
  }

  void _editEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => EventDetailsDialog(event: event),
    );
  }

  void _duplicateEvent(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicating "${event.title}"...')),
    );
  }

  void _deleteEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Event "${event.title}" deleted')),
              );
              _loadEvents();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Events', icon: Icon(Icons.event)),
            Tab(text: 'Active', icon: Icon(Icons.play_circle)),
            Tab(text: 'Draft', icon: Icon(Icons.edit)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _createEvent,
            icon: const Icon(Icons.add),
            tooltip: 'Create Event',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList(_events),
                _buildEventsList(_events.where((e) => e.isActive).toList()),
                _buildEventsList(_events.where((e) => e.status == EventStatus.draft).toList()),
                _buildEventsList(_events.where((e) => e.status == EventStatus.completed).toList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEvent,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No events found'),
            SizedBox(height: 8),
            Text('Create your first event to get started', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getEventStatusColor(event.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getEventStatusIcon(event.status),
                  color: _getEventStatusColor(event.status),
                ),
              ),
              title: Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(event.description.length > 100 
                      ? '${event.description.substring(0, 100)}...'
                      : event.description),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getEventStatusColor(event.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getEventStatusColor(event.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.dateTime),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Event Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildInfoRow('Capacity', '${event.capacity}'),
                      _buildInfoRow('Price', event.price > 0 ? '\$${event.price.toStringAsFixed(2)}' : 'Free'),
                      _buildInfoRow('Category', event.category.name),
                      _buildInfoRow('Format', event.isVirtual ? 'Virtual' : 'In-Person'),
                      if (event.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: event.tags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 10)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton('Edit', Icons.edit, Colors.blue, () => _editEvent(event)),
                          _buildActionButton('Duplicate', Icons.copy, Colors.green, () => _duplicateEvent(event)),
                          _buildActionButton('Delete', Icons.delete, Colors.red, () => _deleteEvent(event)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.active:
        return Colors.green;
      case EventStatus.draft:
        return Colors.orange;
      case EventStatus.completed:
        return Colors.blue;
      case EventStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getEventStatusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.active:
        return Icons.play_circle;
      case EventStatus.draft:
        return Icons.edit;
      case EventStatus.completed:
        return Icons.check_circle;
      case EventStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}

class EventDetailsDialog extends StatelessWidget {
  final Event event;

  const EventDetailsDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${event.title}'),
      content: const SizedBox(
        width: 500,
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Event Editor'),
              SizedBox(height: 8),
              Text(
                'Full event editing interface would be implemented here',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        CustomButton(
          text: 'Save Changes',
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event updated successfully')),
            );
          },
        ),
      ],
    );
  }
}