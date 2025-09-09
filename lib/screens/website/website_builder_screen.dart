import 'package:flutter/material.dart' hide BorderRadius;
import 'package:flutter/material.dart' as material;
import '../../models/event.dart';
import '../../models/website.dart';
import '../../services/website_service.dart';
import 'template_selector_screen.dart';
import 'website_editor_screen.dart';
import 'website_preview_screen.dart';

class WebsiteBuilderScreen extends StatefulWidget {
  final Event event;

  const WebsiteBuilderScreen({super.key, required this.event});

  @override
  State<WebsiteBuilderScreen> createState() => _WebsiteBuilderScreenState();
}

class _WebsiteBuilderScreenState extends State<WebsiteBuilderScreen>
    with SingleTickerProviderStateMixin {
  final WebsiteService _websiteService = WebsiteService();
  
  EventWebsite? _website;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWebsite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWebsite() async {
    setState(() => _isLoading = true);

    try {
      // Generate demo templates if needed
      final templates = await _websiteService.getTemplates();
      if (templates.isEmpty) {
        await _websiteService.generateDemoTemplates();
      }

      _website = await _websiteService.getEventWebsite(widget.event.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading website: $e')),
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
            const Text('Website Builder'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (_website != null) ...[
            IconButton(
              onPressed: _previewWebsite,
              icon: const Icon(Icons.preview),
              tooltip: 'Preview Website',
            ),
            IconButton(
              onPressed: _website!.isPublished ? _unpublishWebsite : _publishWebsite,
              icon: Icon(_website!.isPublished ? Icons.visibility_off : Icons.visibility),
              tooltip: _website!.isPublished ? 'Unpublish' : 'Publish',
            ),
          ],
          IconButton(
            onPressed: _loadWebsite,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _website == null
              ? _buildWebsiteSetup()
              : _buildWebsiteManager(),
    );
  }

  Widget _buildWebsiteSetup() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.web,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create Your Event Website',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Build a beautiful website for your event with our drag-and-drop builder.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createWebsite,
              icon: const Icon(Icons.add),
              label: const Text('Create Website'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showTemplateSelector,
              icon: const Icon(Icons.web),
              label: const Text('Choose Template'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebsiteManager() {
    return Column(
      children: [
        _buildWebsiteHeader(),
        _buildTabSection(),
      ],
    );
  }

  Widget _buildWebsiteHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _website!.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _website!.fullDomain,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _website!.isPublished ? Colors.green : Colors.orange,
                  borderRadius: material.BorderRadius.circular(16),
                ),
                child: Text(
                  _website!.isPublished ? 'Published' : 'Draft',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _website!.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Edit Website',
            Icons.edit,
            Colors.blue,
            () => _editWebsite(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Preview',
            Icons.preview,
            Colors.green,
            () => _previewWebsite(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            _website!.isPublished ? 'Unpublish' : 'Publish',
            _website!.isPublished ? Icons.visibility_off : Icons.visibility,
            _website!.isPublished ? Colors.orange : Colors.purple,
            () => _website!.isPublished ? _unpublishWebsite() : _publishWebsite(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: material.BorderRadius.circular(8),
        ),
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
              Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
              Tab(text: 'Pages', icon: Icon(Icons.pages)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
              Tab(text: 'Settings', icon: Icon(Icons.settings)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPagesTab(),
                _buildAnalyticsTab(),
                _buildSettingsTab(),
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
          _buildWebsiteStats(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
          const SizedBox(height: 24),
          _buildQuickTasks(),
        ],
      ),
    );
  }

  Widget _buildWebsiteStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Website Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Page Views',
                    '1,250',
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Visitors',
                    '890',
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bounce Rate',
                    '35%',
                    Icons.exit_to_app,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avg. Time',
                    '3:20',
                    Icons.timer,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: material.BorderRadius.circular(12),
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

  Widget _buildRecentActivity() {
    final activities = [
      {'action': 'Published website', 'time': '2 hours ago', 'icon': Icons.publish},
      {'action': 'Updated homepage', 'time': '1 day ago', 'icon': Icons.edit},
      {'action': 'Added speakers page', 'time': '2 days ago', 'icon': Icons.add_box},
      {'action': 'Changed theme colors', 'time': '3 days ago', 'icon': Icons.palette},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...activities.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  activity['icon'] as IconData,
                  color: Colors.blue,
                ),
                title: Text(activity['action'] as String),
                subtitle: Text(activity['time'] as String),
                dense: true,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTasks() {
    final tasks = [
      {
        'title': 'Add SEO meta tags',
        'description': 'Improve search engine visibility',
        'icon': Icons.search,
        'color': Colors.green,
        'onTap': () => _tabController.animateTo(3),
      },
      {
        'title': 'Connect custom domain',
        'description': 'Use your own domain name',
        'icon': Icons.link,
        'color': Colors.blue,
        'onTap': () => _showCustomDomainDialog(),
      },
      {
        'title': 'Set up analytics',
        'description': 'Track website performance',
        'icon': Icons.analytics,
        'color': Colors.purple,
        'onTap': () => _tabController.animateTo(2),
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...tasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (task['color'] as Color).withOpacity(0.1),
                    borderRadius: material.BorderRadius.circular(8),
                  ),
                  child: Icon(
                    task['icon'] as IconData,
                    color: task['color'] as Color,
                    size: 20,
                  ),
                ),
                title: Text(task['title'] as String),
                subtitle: Text(task['description'] as String),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: task['onTap'] as VoidCallback,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesTab() {
    return FutureBuilder<List<WebsitePage>>(
      future: _websiteService.getWebsitePages(_website!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading pages: ${snapshot.error}'),
          );
        }

        final pages = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pages.length + 1,
          itemBuilder: (context, index) {
            if (index == pages.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: _createPage,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Page'),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPageCard(pages[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildPageCard(WebsitePage page) {
    return Card(
      child: ListTile(
        leading: Icon(
          _getPageTypeIcon(page.type),
          color: Colors.blue,
        ),
        title: Text(page.title),
        subtitle: Text('/${page.slug}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: page.isPublished ? Colors.green : Colors.grey,
                borderRadius: material.BorderRadius.circular(8),
              ),
              child: Text(
                page.isPublished ? 'Published' : 'Draft',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 20),
          ],
        ),
        onTap: () => _editPage(page),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _websiteService.getWebsiteAnalytics(_website!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final analytics = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalyticsOverview(analytics),
              const SizedBox(height: 24),
              _buildTopPages(analytics['topPages'] ?? []),
              const SizedBox(height: 24),
              _buildTrafficSources(analytics['trafficSources'] ?? {}),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsOverview(Map<String, dynamic> analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Page Views',
                    '${analytics['pageViews'] ?? 0}',
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Unique Visitors',
                    '${analytics['uniqueVisitors'] ?? 0}',
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bounce Rate',
                    '${((analytics['bounceRate'] ?? 0) * 100).toStringAsFixed(0)}%',
                    Icons.exit_to_app,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avg. Time',
                    '${(analytics['averageTimeOnSite'] ?? 0) ~/ 60}:${((analytics['averageTimeOnSite'] ?? 0) % 60).toString().padLeft(2, '0')}',
                    Icons.timer,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPages(List<dynamic> topPages) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Pages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topPages.map((page) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(page['path']),
                  ),
                  Text(
                    '${page['views']} views',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficSources(Map<String, dynamic> trafficSources) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Traffic Sources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...trafficSources.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key.toString().toUpperCase()),
                  ),
                  Text(
                    '${((entry.value as double) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralSettings(),
          const SizedBox(height: 24),
          _buildSEOSettings(),
          const SizedBox(height: 24),
          _buildDomainSettings(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.title),
              title: const Text('Website Title'),
              subtitle: Text(_website!.title),
              trailing: const Icon(Icons.edit),
              onTap: _editWebsiteTitle,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Description'),
              subtitle: Text(_website!.description),
              trailing: const Icon(Icons.edit),
              onTap: _editWebsiteDescription,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme'),
              subtitle: Text(_website!.theme.name),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _changeTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSEOSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEO Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Meta Title'),
              subtitle: Text(_website!.seo.title.isEmpty ? 'Not set' : _website!.seo.title),
              trailing: const Icon(Icons.edit),
              onTap: _editMetaTitle,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Meta Description'),
              subtitle: Text(_website!.seo.description.isEmpty ? 'Not set' : _website!.seo.description),
              trailing: const Icon(Icons.edit),
              onTap: _editMetaDescription,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('Keywords'),
              subtitle: Text(_website!.seo.keywords.isEmpty ? 'Not set' : _website!.seo.keywords.join(', ')),
              trailing: const Icon(Icons.edit),
              onTap: _editKeywords,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Domain Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Current Domain'),
              subtitle: Text(_website!.fullDomain),
              trailing: const Icon(Icons.copy),
              onTap: _copyDomain,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Custom Domain'),
              subtitle: Text(_website!.hasCustomDomain ? _website!.customDomain! : 'Not connected'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showCustomDomainDialog,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPageTypeIcon(PageType type) {
    switch (type) {
      case PageType.homepage:
        return Icons.home;
      case PageType.about:
        return Icons.info;
      case PageType.agenda:
        return Icons.schedule;
      case PageType.speakers:
        return Icons.person;
      case PageType.sponsors:
        return Icons.business;
      case PageType.venue:
        return Icons.location_on;
      case PageType.registration:
        return Icons.app_registration;
      case PageType.contact:
        return Icons.contact_mail;
      case PageType.custom:
        return Icons.pages;
    }
  }

  void _createWebsite() {
    _showTemplateSelector();
  }

  void _showTemplateSelector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplateSelectorScreen(event: widget.event),
      ),
    ).then((_) => _loadWebsite());
  }

  void _editWebsite() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebsiteEditorScreen(
          event: widget.event,
          website: _website!,
        ),
      ),
    ).then((_) => _loadWebsite());
  }

  void _previewWebsite() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebsitePreviewScreen(
          event: widget.event,
          website: _website!,
        ),
      ),
    );
  }

  Future<void> _publishWebsite() async {
    try {
      await _websiteService.publishWebsite(_website!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website published successfully!')),
      );
      _loadWebsite();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error publishing website: $e')),
      );
    }
  }

  Future<void> _unpublishWebsite() async {
    try {
      await _websiteService.unpublishWebsite(_website!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website unpublished')),
      );
      _loadWebsite();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unpublishing website: $e')),
      );
    }
  }

  void _createPage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create page feature would be implemented here')),
    );
  }

  void _editPage(WebsitePage page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit page "${page.title}" feature would be implemented here')),
    );
  }

  void _editWebsiteTitle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit website title feature would be implemented here')),
    );
  }

  void _editWebsiteDescription() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit website description feature would be implemented here')),
    );
  }

  void _changeTheme() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change theme feature would be implemented here')),
    );
  }

  void _editMetaTitle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit meta title feature would be implemented here')),
    );
  }

  void _editMetaDescription() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit meta description feature would be implemented here')),
    );
  }

  void _editKeywords() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit keywords feature would be implemented here')),
    );
  }

  void _copyDomain() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${_website!.fullDomain} to clipboard')),
    );
  }

  void _showCustomDomainDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Domain'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect your own domain to your event website.'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Domain name',
                hintText: 'events.yourcompany.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom domain setup would be implemented here')),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}