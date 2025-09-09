import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_fab.dart';
import 'create_announcement_screen.dart';
import 'announcement_detail_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  final Event event;
  final bool isOrganizer;

  const AnnouncementsScreen({
    super.key,
    required this.event,
    this.isOrganizer = false,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  final AnnouncementService _announcementService = AnnouncementService();
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<Announcement> _allAnnouncements = [];
  List<Announcement> _filteredAnnouncements = [];
  List<Announcement> _unreadAnnouncements = [];
  List<Announcement> _pinnedAnnouncements = [];
  AnnouncementType? _selectedType;
  AnnouncementPriority? _selectedPriority;
  bool _isLoading = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isOrganizer ? 4 : 3, vsync: this);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);

    try {
      _allAnnouncements = await _announcementService.getAnnouncementsForUser(
        widget.event.id,
        _currentUserId,
      );
      _filteredAnnouncements = List.from(_allAnnouncements);
      _unreadAnnouncements = await _announcementService.getUnreadAnnouncements(
        widget.event.id,
        _currentUserId,
      );
      _pinnedAnnouncements = await _announcementService.getPinnedAnnouncements(widget.event.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading announcements: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _filterAnnouncements({
    String? query,
    AnnouncementType? type,
    AnnouncementPriority? priority,
  }) {
    setState(() {
      _selectedType = type;
      _selectedPriority = priority;
      
      List<Announcement> announcements = _allAnnouncements;

      // Filter by type
      if (type != null) {
        announcements = announcements.where((a) => a.type == type).toList();
      }

      // Filter by priority
      if (priority != null) {
        announcements = announcements.where((a) => a.priority == priority).toList();
      }

      // Filter by search query
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        announcements = announcements.where((announcement) {
          return announcement.title.toLowerCase().contains(lowercaseQuery) ||
                 announcement.content.toLowerCase().contains(lowercaseQuery) ||
                 announcement.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
        }).toList();
      }

      _filteredAnnouncements = announcements;
    });
  }

  void _navigateToCreateAnnouncement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateAnnouncementScreen(event: widget.event),
      ),
    ).then((_) => _loadAnnouncements());
  }

  void _navigateToAnnouncementDetail(Announcement announcement) async {
    // Mark as read when opening
    if (!announcement.isReadBy(_currentUserId)) {
      await _announcementService.markAsRead(announcement.id, _currentUserId);
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AnnouncementDetailScreen(
            event: widget.event,
            announcement: announcement,
            isOrganizer: widget.isOrganizer,
          ),
        ),
      ).then((_) => _loadAnnouncements());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Announcements'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (widget.isOrganizer)
            IconButton(
              onPressed: _navigateToCreateAnnouncement,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create Announcement',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'All (${_allAnnouncements.length})',
              icon: const Icon(Icons.campaign),
            ),
            Tab(
              text: 'Unread (${_unreadAnnouncements.length})',
              icon: const Icon(Icons.mark_email_unread),
            ),
            Tab(
              text: 'Pinned (${_pinnedAnnouncements.length})',
              icon: const Icon(Icons.push_pin),
            ),
            if (widget.isOrganizer)
              const Tab(
                text: 'Manage',
                icon: Icon(Icons.settings),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllAnnouncementsTab(),
                      _buildUnreadAnnouncementsTab(),
                      _buildPinnedAnnouncementsTab(),
                      if (widget.isOrganizer) _buildManageTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.isOrganizer
          ? CustomFAB(
              onPressed: _navigateToCreateAnnouncement,
              icon: Icons.campaign,
              label: 'New Announcement',
            )
          : null,
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomTextField(
            controller: _searchController,
            labelText: 'Search announcements...',
            prefixIcon: Icons.search,
            onChanged: (query) => _filterAnnouncements(
              query: query,
              type: _selectedType,
              priority: _selectedPriority,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilter(),
                const SizedBox(width: 16),
                _buildPriorityFilter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return PopupMenuButton<AnnouncementType?>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _selectedType != null ? _getTypeLabel(_selectedType!) : 'All Types',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
      onSelected: (type) => _filterAnnouncements(
        query: _searchController.text,
        type: type,
        priority: _selectedPriority,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('All Types'),
        ),
        ...AnnouncementType.values.map((type) => PopupMenuItem(
          value: type,
          child: Row(
            children: [
              _getTypeIcon(type),
              const SizedBox(width: 8),
              Text(_getTypeLabel(type)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPriorityFilter() {
    return PopupMenuButton<AnnouncementPriority?>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.priority_high, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _selectedPriority != null 
                  ? _getPriorityLabel(_selectedPriority!) 
                  : 'All Priorities',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
      onSelected: (priority) => _filterAnnouncements(
        query: _searchController.text,
        type: _selectedType,
        priority: priority,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('All Priorities'),
        ),
        ...AnnouncementPriority.values.map((priority) => PopupMenuItem(
          value: priority,
          child: Row(
            children: [
              _getPriorityIcon(priority),
              const SizedBox(width: 8),
              Text(_getPriorityLabel(priority)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildAllAnnouncementsTab() {
    if (_filteredAnnouncements.isEmpty) {
      return _buildEmptyState(
        'No announcements found',
        _searchController.text.isNotEmpty || _selectedType != null || _selectedPriority != null
            ? 'Try adjusting your search or filters'
            : 'No announcements have been posted yet',
        Icons.campaign_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAnnouncements.length,
        itemBuilder: (context, index) {
          return _buildAnnouncementCard(_filteredAnnouncements[index]);
        },
      ),
    );
  }

  Widget _buildUnreadAnnouncementsTab() {
    if (_unreadAnnouncements.isEmpty) {
      return _buildEmptyState(
        'All caught up!',
        'You have no unread announcements',
        Icons.mark_email_read,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unreadAnnouncements.length,
      itemBuilder: (context, index) {
        return _buildAnnouncementCard(_unreadAnnouncements[index], showUnreadIndicator: true);
      },
    );
  }

  Widget _buildPinnedAnnouncementsTab() {
    if (_pinnedAnnouncements.isEmpty) {
      return _buildEmptyState(
        'No pinned announcements',
        'Important announcements will appear here when pinned',
        Icons.push_pin_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pinnedAnnouncements.length,
      itemBuilder: (context, index) {
        return _buildAnnouncementCard(_pinnedAnnouncements[index], showPinIcon: true);
      },
    );
  }

  Widget _buildManageTab() {
    return FutureBuilder<List<Announcement>>(
      future: _announcementService.getEventAnnouncements(widget.event.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allAnnouncements = snapshot.data ?? [];
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allAnnouncements.length,
          itemBuilder: (context, index) {
            return _buildManageAnnouncementCard(allAnnouncements[index]);
          },
        );
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement, {
    bool showUnreadIndicator = false,
    bool showPinIcon = false,
  }) {
    final timeFormat = DateFormat('MMM dd, HH:mm');
    final isRead = announcement.isReadBy(_currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: announcement.priority == AnnouncementPriority.urgent ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: announcement.priority == AnnouncementPriority.urgent
            ? const BorderSide(color: Colors.red, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _navigateToAnnouncementDetail(announcement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _getTypeIcon(announcement.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (showPinIcon || announcement.isPinned)
                        Icon(
                          Icons.push_pin,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      const SizedBox(width: 4),
                      _getPriorityIcon(announcement.priority),
                      if (showUnreadIndicator && !isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isRead ? Colors.grey[600] : Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    child: Text(announcement.authorId.substring(0, 1).toUpperCase()),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    announcement.authorName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(announcement.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (announcement.actionButtonText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        announcement.actionButtonText!,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (announcement.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: announcement.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageAnnouncementCard(Announcement announcement) {
    final timeFormat = DateFormat('MMM dd, HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(announcement.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _getTypeIcon(announcement.type),
                const SizedBox(width: 4),
                Text(
                  _getTypeLabel(announcement.type),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                _getPriorityIcon(announcement.priority),
                const SizedBox(width: 4),
                Text(
                  _getPriorityLabel(announcement.priority),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${announcement.viewCount}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleManageAction(action, announcement),
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
                          Icon(announcement.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                          const SizedBox(width: 8),
                          Text(announcement.isPinned ? 'Unpin' : 'Pin'),
                        ],
                      ),
                    ),
                    if (announcement.status == AnnouncementStatus.draft)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text('Activate'),
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
                ),
              ],
            ),
          ],
        ),
      ),
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

    return Icon(iconData, size: 16, color: color);
  }

  String _getTypeLabel(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.general:
        return 'General';
      case AnnouncementType.urgent:
        return 'Urgent';
      case AnnouncementType.schedule_change:
        return 'Schedule';
      case AnnouncementType.weather:
        return 'Weather';
      case AnnouncementType.emergency:
        return 'Emergency';
      case AnnouncementType.networking:
        return 'Networking';
      case AnnouncementType.meal:
        return 'Meal';
      case AnnouncementType.transport:
        return 'Transport';
      case AnnouncementType.technical:
        return 'Technical';
      case AnnouncementType.social:
        return 'Social';
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

    return Icon(iconData, size: 16, color: color);
  }

  String _getPriorityLabel(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return 'Low';
      case AnnouncementPriority.normal:
        return 'Normal';
      case AnnouncementPriority.high:
        return 'High';
      case AnnouncementPriority.urgent:
        return 'Urgent';
      case AnnouncementPriority.critical:
        return 'Critical';
    }
  }

  void _handleManageAction(String action, Announcement announcement) async {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'pin':
        try {
          await _announcementService.pinAnnouncement(announcement.id, !announcement.isPinned);
          _loadAnnouncements();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating announcement: $e')),
            );
          }
        }
        break;
      case 'activate':
        try {
          await _announcementService.changeAnnouncementStatus(
            announcement.id, 
            AnnouncementStatus.active,
          );
          _loadAnnouncements();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error activating announcement: $e')),
            );
          }
        }
        break;
      case 'delete':
        _showDeleteConfirmation(announcement);
        break;
    }
  }

  void _showDeleteConfirmation(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${announcement.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _announcementService.deleteAnnouncement(announcement.id);
                _loadAnnouncements();
                if (mounted) {
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
          if (widget.isOrganizer) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateAnnouncement,
              icon: const Icon(Icons.campaign),
              label: const Text('Create Announcement'),
            ),
          ],
        ],
      ),
    );
  }
}