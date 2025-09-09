import 'package:flutter/material.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() => _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen>
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
        title: const Text('Content Moderation'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Posts', icon: Icon(Icons.post_add)),
            Tab(text: 'Photos', icon: Icon(Icons.photo)),
            Tab(text: 'Announcements', icon: Icon(Icons.announcement)),
            Tab(text: 'Reports', icon: Icon(Icons.report)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostModerationTab(),
          _buildPhotoModerationTab(),
          _buildAnnouncementTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildPostModerationTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Demo data
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text('U${index + 1}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User Name ${index + 1}', 
                               style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('2 hours ago', 
                               style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('PENDING', 
                           style: TextStyle(color: Colors.orange, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('This is a sample community post that needs moderation approval. It contains user-generated content that should be reviewed.'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _rejectContent('post', index),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveContent('post', index),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoModerationTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: 6, // Demo data
      itemBuilder: (context, index) {
        return Card(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Icon(Icons.photo, size: 50, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text('Photo ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('By User ${index + 1}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _rejectContent('photo', index),
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _approveContent('photo', index),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Demo data
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      [Icons.info, Icons.warning, Icons.celebration][index % 3],
                      color: [Colors.blue, Colors.orange, Colors.green][index % 3],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Announcement ${index + 1}', 
                           style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('SCHEDULED', 
                           style: TextStyle(color: Colors.blue, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('This is a scheduled announcement that will be sent to all attendees. Review content and timing.'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('Scheduled for tomorrow at 10:00 AM', 
                         style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editAnnouncement(index),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _sendAnnouncement(index),
                      icon: const Icon(Icons.send),
                      label: const Text('Send Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4, // Demo data
      itemBuilder: (context, index) {
        final reportTypes = ['Spam', 'Inappropriate Content', 'Copyright', 'Other'];
        final severities = [Colors.red, Colors.orange, Colors.yellow, Colors.grey];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severities[index % 4].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reportTypes[index % 4],
                        style: TextStyle(
                          color: severities[index % 4],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${index + 1} hour${index == 0 ? '' : 's'} ago',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Report #${1000 + index}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('User reported inappropriate content in community post. Review required for policy compliance.'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Reported by: '),
                    Text('User ${index + 10}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    const Text('Content by: '),
                    Text('User ${index + 5}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _dismissReport(index),
                      icon: const Icon(Icons.close),
                      label: const Text('Dismiss'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _reviewReport(index),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Review'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _approveContent(String type, int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${type.capitalizeFirst()} approved successfully')),
    );
  }

  void _rejectContent(String type, int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${type.capitalizeFirst()} rejected')),
    );
  }

  void _editAnnouncement(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening announcement editor...')),
    );
  }

  void _sendAnnouncement(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement sent to all attendees')),
    );
  }

  void _reviewReport(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening detailed report review...')),
    );
  }

  void _dismissReport(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report dismissed')),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}