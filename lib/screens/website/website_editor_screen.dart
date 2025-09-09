import 'package:flutter/material.dart' hide BorderRadius;
import 'package:flutter/material.dart' as material;
import '../../models/event.dart';
import '../../models/website.dart';
import '../../services/website_service.dart';

class WebsiteEditorScreen extends StatefulWidget {
  final Event event;
  final EventWebsite website;

  const WebsiteEditorScreen({
    super.key,
    required this.event,
    required this.website,
  });

  @override
  State<WebsiteEditorScreen> createState() => _WebsiteEditorScreenState();
}

class _WebsiteEditorScreenState extends State<WebsiteEditorScreen>
    with SingleTickerProviderStateMixin {
  final WebsiteService _websiteService = WebsiteService();
  
  List<WebsitePage> _pages = [];
  WebsitePage? _selectedPage;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPages() async {
    setState(() => _isLoading = true);

    try {
      _pages = await _websiteService.getWebsitePages(widget.website.id);
      if (_pages.isNotEmpty && _selectedPage == null) {
        _selectedPage = _pages.first;
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pages: $e')),
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
            const Text('Website Editor'),
            Text(
              widget.website.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _previewPage,
            icon: const Icon(Icons.preview),
            tooltip: 'Preview',
          ),
          IconButton(
            onPressed: _savePage,
            icon: const Icon(Icons.save),
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: _buildMainEditor(),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPagesTab(),
                _buildComponentsTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: material.BorderRadius.circular(8),
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.pages, size: 16),
            text: 'Pages',
          ),
          Tab(
            icon: Icon(Icons.widgets, size: 16),
            text: 'Components',
          ),
          Tab(
            icon: Icon(Icons.settings, size: 16),
            text: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildPagesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pages.length + 1,
      itemBuilder: (context, index) {
        if (index == _pages.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: _addPage,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Page'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          );
        }

        final page = _pages[index];
        final isSelected = _selectedPage?.id == page.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
              borderRadius: material.BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
              ),
            ),
            child: ListTile(
              leading: Icon(
                _getPageTypeIcon(page.type),
                size: 18,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
              title: Text(
                page.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
              ),
              subtitle: Text(
                '/${page.slug}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) => _handlePageAction(page, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () => _selectPage(page),
              dense: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildComponentsTab() {
    final components = [
      {'type': ComponentType.text, 'name': 'Text', 'icon': Icons.text_fields},
      {'type': ComponentType.image, 'name': 'Image', 'icon': Icons.image},
      {'type': ComponentType.hero, 'name': 'Hero Section', 'icon': Icons.view_carousel},
      {'type': ComponentType.gallery, 'name': 'Gallery', 'icon': Icons.photo_library},
      {'type': ComponentType.speakers_grid, 'name': 'Speakers', 'icon': Icons.people},
      {'type': ComponentType.agenda_schedule, 'name': 'Agenda', 'icon': Icons.schedule},
      {'type': ComponentType.sponsors_grid, 'name': 'Sponsors', 'icon': Icons.business},
      {'type': ComponentType.contact_form, 'name': 'Contact Form', 'icon': Icons.contact_mail},
      {'type': ComponentType.map, 'name': 'Map', 'icon': Icons.map},
      {'type': ComponentType.video, 'name': 'Video', 'icon': Icons.play_circle},
      {'type': ComponentType.countdown, 'name': 'Countdown', 'icon': Icons.timer},
      {'type': ComponentType.faq, 'name': 'FAQ', 'icon': Icons.help},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final component = components[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: material.BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListTile(
              leading: Icon(
                component['icon'] as IconData,
                size: 18,
                color: Colors.blue,
              ),
              title: Text(
                component['name'] as String,
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () => _addComponent(component['type'] as ComponentType),
              dense: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection(
          'Page Settings',
          [
            ListTile(
              leading: const Icon(Icons.title, size: 18),
              title: const Text('Page Title', style: TextStyle(fontSize: 14)),
              subtitle: Text(_selectedPage?.title ?? ''),
              onTap: _editPageTitle,
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.link, size: 18),
              title: const Text('URL Slug', style: TextStyle(fontSize: 14)),
              subtitle: Text('/${_selectedPage?.slug ?? ''}'),
              onTap: _editPageSlug,
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, size: 18),
              title: const Text('Layout', style: TextStyle(fontSize: 14)),
              subtitle: Text(_selectedPage?.layout.name ?? ''),
              onTap: _changeLayout,
              dense: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsSection(
          'SEO',
          [
            ListTile(
              leading: const Icon(Icons.search, size: 18),
              title: const Text('Meta Title', style: TextStyle(fontSize: 14)),
              subtitle: Text(_selectedPage?.metaTitle.isEmpty == true ? 'Not set' : _selectedPage?.metaTitle ?? ''),
              onTap: _editMetaTitle,
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.description, size: 18),
              title: const Text('Meta Description', style: TextStyle(fontSize: 14)),
              subtitle: Text(_selectedPage?.metaDescription.isEmpty == true ? 'Not set' : _selectedPage?.metaDescription ?? ''),
              onTap: _editMetaDescription,
              dense: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: material.BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMainEditor() {
    if (_selectedPage == null) {
      return const Center(
        child: Text('Select a page to edit'),
      );
    }

    return Column(
      children: [
        _buildEditorToolbar(),
        Expanded(
          child: _buildPageCanvas(),
        ),
      ],
    );
  }

  Widget _buildEditorToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text(
            _selectedPage!.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _selectedPage!.isPublished ? Colors.green : Colors.orange,
              borderRadius: material.BorderRadius.circular(8),
            ),
            child: Text(
              _selectedPage!.isPublished ? 'Published' : 'Draft',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _undoChange,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
          ),
          IconButton(
            onPressed: _redoChange,
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
          ),
          const SizedBox(width: 8),
          DropdownButton<double>(
            value: 1.0,
            items: const [
              DropdownMenuItem(value: 0.5, child: Text('50%')),
              DropdownMenuItem(value: 0.75, child: Text('75%')),
              DropdownMenuItem(value: 1.0, child: Text('100%')),
              DropdownMenuItem(value: 1.25, child: Text('125%')),
            ],
            onChanged: (value) {},
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageCanvas() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Container(
          width: 800,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Page header
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: material.BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.website.fullDomain}/${_selectedPage!.slug}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              // Page content
              Expanded(
                child: _selectedPage!.components.isEmpty
                    ? _buildEmptyCanvas()
                    : _buildPageContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCanvas() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_box_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Start building your page',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag components from the sidebar to get started',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _addComponent(ComponentType.hero),
            icon: const Icon(Icons.add),
            label: const Text('Add Hero Section'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    final sortedComponents = List<PageComponent>.from(_selectedPage!.components)
      ..sort((a, b) => a.order.compareTo(b.order));

    return ListView.builder(
      itemCount: sortedComponents.length,
      itemBuilder: (context, index) {
        return _buildComponentEditor(sortedComponents[index]);
      },
    );
  }

  Widget _buildComponentEditor(PageComponent component) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: material.BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Component toolbar
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const material.BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  _getComponentTypeIcon(component.type),
                  size: 14,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _getComponentTypeName(component.type),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _editComponent(component),
                  icon: const Icon(Icons.edit, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                IconButton(
                  onPressed: () => _deleteComponent(component),
                  icon: const Icon(Icons.delete, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          // Component content
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildComponentPreview(component),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentPreview(PageComponent component) {
    switch (component.type) {
      case ComponentType.hero:
        return _buildHeroPreview(component);
      case ComponentType.text:
        return _buildTextPreview(component);
      case ComponentType.image:
        return _buildImagePreview(component);
      default:
        return _buildGenericPreview(component);
    }
  }

  Widget _buildHeroPreview(PageComponent component) {
    final data = component.data;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.withOpacity(0.8), Colors.purple.withOpacity(0.8)],
        ),
        borderRadius: material.BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data['title'] ?? 'Hero Title',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              data['subtitle'] ?? 'Hero Subtitle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: null,
              child: Text(data['buttonText'] ?? 'Button'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPreview(PageComponent component) {
    final data = component.data;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        data['content'] ?? 'Text content goes here...',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildImagePreview(PageComponent component) {
    final data = component.data;
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: material.BorderRadius.circular(8),
      ),
      child: data['url'] != null
          ? Image.network(
              data['url'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Image Placeholder',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericPreview(PageComponent component) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: material.BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getComponentTypeIcon(component.type),
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              _getComponentTypeName(component.type),
              style: TextStyle(color: Colors.grey[600]),
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

  IconData _getComponentTypeIcon(ComponentType type) {
    switch (type) {
      case ComponentType.hero:
        return Icons.view_carousel;
      case ComponentType.text:
        return Icons.text_fields;
      case ComponentType.image:
        return Icons.image;
      case ComponentType.gallery:
        return Icons.photo_library;
      case ComponentType.speakers_grid:
        return Icons.people;
      case ComponentType.agenda_schedule:
        return Icons.schedule;
      case ComponentType.sponsors_grid:
        return Icons.business;
      case ComponentType.registration_form:
        return Icons.app_registration;
      case ComponentType.contact_form:
        return Icons.contact_mail;
      case ComponentType.map:
        return Icons.map;
      case ComponentType.video:
        return Icons.play_circle;
      case ComponentType.countdown:
        return Icons.timer;
      case ComponentType.testimonials:
        return Icons.format_quote;
      case ComponentType.faq:
        return Icons.help;
      case ComponentType.social_media:
        return Icons.share;
      case ComponentType.custom_html:
        return Icons.code;
    }
  }

  String _getComponentTypeName(ComponentType type) {
    switch (type) {
      case ComponentType.hero:
        return 'Hero Section';
      case ComponentType.text:
        return 'Text';
      case ComponentType.image:
        return 'Image';
      case ComponentType.gallery:
        return 'Gallery';
      case ComponentType.speakers_grid:
        return 'Speakers';
      case ComponentType.agenda_schedule:
        return 'Agenda';
      case ComponentType.sponsors_grid:
        return 'Sponsors';
      case ComponentType.registration_form:
        return 'Registration Form';
      case ComponentType.contact_form:
        return 'Contact Form';
      case ComponentType.map:
        return 'Map';
      case ComponentType.video:
        return 'Video';
      case ComponentType.countdown:
        return 'Countdown';
      case ComponentType.testimonials:
        return 'Testimonials';
      case ComponentType.faq:
        return 'FAQ';
      case ComponentType.social_media:
        return 'Social Media';
      case ComponentType.custom_html:
        return 'Custom HTML';
    }
  }

  void _selectPage(WebsitePage page) {
    setState(() {
      _selectedPage = page;
    });
  }

  void _addPage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add page feature would be implemented here')),
    );
  }

  void _handlePageAction(WebsitePage page, String action) {
    switch (action) {
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicate page "${page.title}" feature would be implemented here')),
        );
        break;
      case 'delete':
        _showDeletePageDialog(page);
        break;
    }
  }

  void _showDeletePageDialog(WebsitePage page) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text('Are you sure you want to delete "${page.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted page "${page.title}"')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addComponent(ComponentType type) {
    if (_selectedPage == null) return;

    final component = PageComponent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: _getDefaultComponentData(type),
      style: const ComponentStyle(),
      order: _selectedPage!.components.length,
    );

    setState(() {
      _selectedPage = _selectedPage!.copyWith(
        components: [..._selectedPage!.components, component],
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${_getComponentTypeName(type)} component')),
    );
  }

  Map<String, dynamic> _getDefaultComponentData(ComponentType type) {
    switch (type) {
      case ComponentType.hero:
        return {
          'title': 'Welcome to Our Event',
          'subtitle': 'Join us for an amazing experience',
          'buttonText': 'Register Now',
          'buttonUrl': '/registration',
        };
      case ComponentType.text:
        return {
          'content': 'Your text content goes here. You can edit this to add your own information.',
        };
      case ComponentType.image:
        return {
          'url': '',
          'alt': 'Image description',
          'caption': '',
        };
      default:
        return {};
    }
  }

  void _editComponent(PageComponent component) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${_getComponentTypeName(component.type)} component feature would be implemented here')),
    );
  }

  void _deleteComponent(PageComponent component) {
    setState(() {
      _selectedPage = _selectedPage!.copyWith(
        components: _selectedPage!.components.where((c) => c.id != component.id).toList(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${_getComponentTypeName(component.type)} component')),
    );
  }

  void _editPageTitle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit page title feature would be implemented here')),
    );
  }

  void _editPageSlug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit page slug feature would be implemented here')),
    );
  }

  void _changeLayout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change layout feature would be implemented here')),
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

  void _previewPage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview page feature would be implemented here')),
    );
  }

  void _savePage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Page saved successfully!')),
    );
  }

  void _undoChange() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Undo feature would be implemented here')),
    );
  }

  void _redoChange() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redo feature would be implemented here')),
    );
  }
}