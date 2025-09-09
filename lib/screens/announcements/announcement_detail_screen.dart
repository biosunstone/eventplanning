import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Event event;
  final Announcement announcement;
  final bool isOrganizer;

  const AnnouncementDetailScreen({
    super.key,
    required this.event,
    required this.announcement,
    this.isOrganizer = false,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  late Announcement _announcement;
  bool _isLoading = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (!_announcement.isReadBy(_currentUserId)) {
      try {
        await _announcementService.markAsRead(_announcement.id, _currentUserId);
      } catch (e) {
        // Silently handle error
      }
    }
  }

  Future<void> _dismissAnnouncement() async {
    try {
      await _announcementService.markAsDismissed(_announcement.id, _currentUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement dismissed')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dismissing announcement: $e')),
        );
      }
    }
  }

  Future<void> _handleActionButton() async {
    if (_announcement.actionButtonUrl != null) {
      try {
        await _announcementService.incrementClickCount(_announcement.id);
        
        // In a real app, handle different types of URLs/actions
        if (_announcement.actionButtonUrl!.startsWith('http')) {
          // Open external URL
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening: ${_announcement.actionButtonUrl}')),
          );
        } else {
          // Handle internal navigation or actions
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action: ${_announcement.actionButtonUrl}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing action: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        actions: [
          if (widget.isOrganizer)
            PopupMenuButton<String>(
              onSelected: _handleOrganizerAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(_announcement.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                      const SizedBox(width: 8),
                      Text(_announcement.isPinned ? 'Unpin' : 'Pin'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('View Stats'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              onPressed: _dismissAnnouncement,
              icon: const Icon(Icons.close),
              tooltip: 'Dismiss',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnnouncementHeader(),
            const SizedBox(height: 24),
            _buildAnnouncementContent(),
            if (_announcement.imageUrl != null) ...[
              const SizedBox(height: 24),
              _buildAnnouncementImage(),
            ],
            if (_announcement.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildTags(),
            ],
            const SizedBox(height: 24),
            _buildAnnouncementMeta(),
            if (_announcement.actionButtonText != null) ...[
              const SizedBox(height: 24),
              _buildActionButton(),
            ],
            if (widget.isOrganizer) ...[
              const SizedBox(height: 24),
              _buildOrganizerStats(),
            ],
            const SizedBox(height: 32),
            if (!widget.isOrganizer) _buildUserActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _getTypeIcon(_announcement.type),
            const SizedBox(width: 8),
            _getPriorityIcon(_announcement.priority),
            const SizedBox(width: 8),
            _buildStatusChip(_announcement.status),
            const Spacer(),
            if (_announcement.isPinned)
              Icon(
                Icons.push_pin,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _announcement.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getPriorityColor(_announcement.priority).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPriorityColor(_announcement.priority).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        _announcement.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildAnnouncementImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        _announcement.imageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _announcement.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '#$tag',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnnouncementMeta() {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy • HH:mm');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetaRow('Author', _announcement.authorName),
            _buildMetaRow('Published', dateFormat.format(_announcement.createdAt)),
            if (_announcement.scheduledAt != null && _announcement.scheduledAt != _announcement.createdAt)
              _buildMetaRow('Scheduled for', dateFormat.format(_announcement.scheduledAt!)),
            if (_announcement.expiresAt != null)
              _buildMetaRow('Expires', dateFormat.format(_announcement.expiresAt!)),
            _buildMetaRow('Type', _getTypeLabel(_announcement.type)),
            _buildMetaRow('Priority', _getPriorityLabel(_announcement.priority)),
            if (_announcement.targetAudience.isNotEmpty)
              _buildMetaRow('Audience', _announcement.targetAudience.map(_getAudienceLabel).join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
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

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleActionButton,
        icon: const Icon(Icons.open_in_new),
        label: Text(_announcement.actionButtonText!),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizerStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Views',
                    '${_announcement.viewCount}',
                    Icons.visibility,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Reads',
                    '${_announcement.readCount}',
                    Icons.mark_email_read,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Clicks',
                    '${_announcement.clickCount}',
                    Icons.mouse,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Dismissed',
                    '${_announcement.dismissedCount}',
                    Icons.close,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _dismissAnnouncement,
            icon: const Icon(Icons.close),
            label: const Text('Dismiss'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality would be implemented here')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(AnnouncementStatus status) {
    Color color;
    String label;

    switch (status) {
      case AnnouncementStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
      case AnnouncementStatus.scheduled:
        color = Colors.orange;
        label = 'Scheduled';
        break;
      case AnnouncementStatus.active:
        color = Colors.green;
        label = 'Active';
        break;
      case AnnouncementStatus.expired:
        color = Colors.red;
        label = 'Expired';
        break;
      case AnnouncementStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Icon _getTypeIcon(AnnouncementType type) {
    IconData iconData;
    Color color = Colors.grey[600]!;

    switch (type) {
      case AnnouncementType.general:
        iconData = Icons.info;
        break;
      case AnnouncementType.urgent:
        iconData = Icons.warning;
        color = Colors.red;
        break;
      case AnnouncementType.schedule_change:
        iconData = Icons.schedule;
        color = Colors.orange;
        break;
      case AnnouncementType.weather:
        iconData = Icons.wb_cloudy;
        color = Colors.blue;
        break;
      case AnnouncementType.emergency:
        iconData = Icons.emergency;
        color = Colors.red;
        break;
      case AnnouncementType.networking:
        iconData = Icons.people;
        color = Colors.green;
        break;
      case AnnouncementType.meal:
        iconData = Icons.restaurant;
        color = Colors.brown;
        break;
      case AnnouncementType.transport:
        iconData = Icons.directions_bus;
        color = Colors.purple;
        break;
      case AnnouncementType.technical:
        iconData = Icons.build;
        color = Colors.indigo;
        break;
      case AnnouncementType.social:
        iconData = Icons.celebration;
        color = Colors.pink;
        break;
    }

    return Icon(iconData, size: 20, color: color);
  }

  String _getTypeLabel(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.general:
        return 'General';
      case AnnouncementType.urgent:
        return 'Urgent';
      case AnnouncementType.schedule_change:
        return 'Schedule Change';
      case AnnouncementType.weather:
        return 'Weather Update';
      case AnnouncementType.emergency:
        return 'Emergency';
      case AnnouncementType.networking:
        return 'Networking';
      case AnnouncementType.meal:
        return 'Meal/Food';
      case AnnouncementType.transport:
        return 'Transportation';
      case AnnouncementType.technical:
        return 'Technical';
      case AnnouncementType.social:
        return 'Social Event';
    }
  }

  Icon _getPriorityIcon(AnnouncementPriority priority) {
    IconData iconData;
    Color color;

    switch (priority) {
      case AnnouncementPriority.low:
        iconData = Icons.keyboard_arrow_down;
        color = Colors.grey;
        break;
      case AnnouncementPriority.normal:
        iconData = Icons.remove;
        color = Colors.blue;
        break;
      case AnnouncementPriority.high:
        iconData = Icons.keyboard_arrow_up;
        color = Colors.orange;
        break;
      case AnnouncementPriority.urgent:
        iconData = Icons.priority_high;
        color = Colors.red;
        break;
      case AnnouncementPriority.critical:
        iconData = Icons.report_problem;
        color = Colors.red;
        break;
    }

    return Icon(iconData, size: 20, color: color);
  }

  String _getPriorityLabel(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return 'Low Priority';
      case AnnouncementPriority.normal:
        return 'Normal Priority';
      case AnnouncementPriority.high:
        return 'High Priority';
      case AnnouncementPriority.urgent:
        return 'Urgent';
      case AnnouncementPriority.critical:
        return 'Critical';
    }
  }

  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return Colors.grey;
      case AnnouncementPriority.normal:
        return Colors.blue;
      case AnnouncementPriority.high:
        return Colors.orange;
      case AnnouncementPriority.urgent:
        return Colors.red;
      case AnnouncementPriority.critical:
        return Colors.red;
    }
  }

  String _getAudienceLabel(String audience) {
    switch (audience) {
      case 'all':
        return 'All Users';
      case 'attendees':
        return 'Attendees';
      case 'speakers':
        return 'Speakers';
      case 'sponsors':
        return 'Sponsors';
      case 'organizers':
        return 'Organizers';
      case 'vip':
        return 'VIP';
      default:
        return audience;
    }
  }

  void _handleOrganizerAction(String action) async {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'pin':
        try {
          await _announcementService.pinAnnouncement(_announcement.id, !_announcement.isPinned);
          setState(() {
            _announcement = _announcement.copyWith(isPinned: !_announcement.isPinned);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_announcement.isPinned 
                    ? 'Announcement pinned' 
                    : 'Announcement unpinned'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating announcement: $e')),
            );
          }
        }
        break;
      case 'stats':
        _showDetailedStats();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDetailedStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Views', '${_announcement.viewCount}'),
            _buildStatRow('Total Reads', '${_announcement.readCount}'),
            _buildStatRow('Action Clicks', '${_announcement.clickCount}'),
            _buildStatRow('Dismissed', '${_announcement.dismissedCount}'),
            const Divider(),
            _buildStatRow('Read Rate', 
              _announcement.viewCount > 0 
                  ? '${(_announcement.readCount / _announcement.viewCount * 100).toStringAsFixed(1)}%'
                  : '0%'),
            _buildStatRow('Click Rate', 
              _announcement.viewCount > 0 
                  ? '${(_announcement.clickCount / _announcement.viewCount * 100).toStringAsFixed(1)}%'
                  : '0%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${_announcement.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              try {
                await _announcementService.deleteAnnouncement(_announcement.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Return to announcements
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting announcement: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}