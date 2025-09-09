import 'package:flutter/material.dart' hide BorderRadius;
import 'package:flutter/material.dart' as material;
import '../../models/event.dart';
import '../../models/website.dart';
import '../../services/website_service.dart';

class WebsitePreviewScreen extends StatefulWidget {
  final Event event;
  final EventWebsite website;

  const WebsitePreviewScreen({
    super.key,
    required this.event,
    required this.website,
  });

  @override
  State<WebsitePreviewScreen> createState() => _WebsitePreviewScreenState();
}

class _WebsitePreviewScreenState extends State<WebsitePreviewScreen>
    with SingleTickerProviderStateMixin {
  final WebsiteService _websiteService = WebsiteService();
  
  List<WebsitePage> _pages = [];
  WebsitePage? _currentPage;
  bool _isLoading = false;
  late TabController _tabController;
  String _selectedDevice = 'desktop';

  final Map<String, Map<String, double>> _deviceSizes = {
    'mobile': {'width': 375, 'height': 812},
    'tablet': {'width': 768, 'height': 1024},
    'desktop': {'width': 1200, 'height': 800},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      if (_pages.isNotEmpty) {
        _currentPage = _pages.firstWhere(
          (page) => page.type == PageType.homepage,
          orElse: () => _pages.first,
        );
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
            const Text('Website Preview'),
            Text(
              widget.website.fullDomain,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedDevice,
            items: const [
              DropdownMenuItem(
                value: 'mobile',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smartphone, size: 16),
                    SizedBox(width: 8),
                    Text('Mobile'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'tablet',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tablet, size: 16),
                    SizedBox(width: 8),
                    Text('Tablet'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'desktop',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.desktop_mac, size: 16),
                    SizedBox(width: 8),
                    Text('Desktop'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDevice = value);
              }
            },
            underline: const SizedBox(),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in Browser',
          ),
          IconButton(
            onPressed: _shareWebsite,
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Preview', icon: Icon(Icons.preview)),
            Tab(text: 'Pages', icon: Icon(Icons.pages)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPreviewTab(),
                _buildPagesTab(),
              ],
            ),
    );
  }

  Widget _buildPreviewTab() {
    if (_currentPage == null) {
      return const Center(
        child: Text('No page selected'),
      );
    }

    final deviceSize = _deviceSizes[_selectedDevice]!;
    
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Container(
          width: deviceSize['width'],
          height: deviceSize['height'],
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _selectedDevice == 'mobile' 
                ? material.BorderRadius.circular(20) 
                : _selectedDevice == 'tablet'
                    ? material.BorderRadius.circular(12)
                    : material.BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: _selectedDevice == 'mobile' 
                ? material.BorderRadius.circular(20) 
                : _selectedDevice == 'tablet'
                    ? material.BorderRadius.circular(12)
                    : material.BorderRadius.circular(8),
            child: Column(
              children: [
                _buildWebsiteHeader(),
                Expanded(
                  child: _buildPageContent(),
                ),
                _buildWebsiteFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebsiteHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (widget.website.settings.logo.isNotEmpty)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: material.BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.website.settings.logo),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: material.BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event, color: Colors.white),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.website.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildNavigationMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationMenu() {
    final navItems = widget.website.settings.navigation.items;
    
    if (_selectedDevice == 'mobile') {
      return IconButton(
        onPressed: _showMobileMenu,
        icon: const Icon(Icons.menu),
      );
    }

    return Row(
      children: navItems.take(4).map((item) {
        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextButton(
            onPressed: () => _navigateToPage(item.url),
            child: Text(item.label),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPageContent() {
    return ListView(
      children: _currentPage!.components.map((component) {
        return _buildComponentPreview(component);
      }).toList(),
    );
  }

  Widget _buildComponentPreview(PageComponent component) {
    if (!component.isVisible) return const SizedBox.shrink();

    switch (component.type) {
      case ComponentType.hero:
        return _buildHeroComponent(component);
      case ComponentType.text:
        return _buildTextComponent(component);
      case ComponentType.image:
        return _buildImageComponent(component);
      case ComponentType.speakers_grid:
        return _buildSpeakersComponent(component);
      case ComponentType.agenda_schedule:
        return _buildAgendaComponent(component);
      case ComponentType.sponsors_grid:
        return _buildSponsorsComponent(component);
      case ComponentType.countdown:
        return _buildCountdownComponent(component);
      default:
        return _buildGenericComponent(component);
    }
  }

  Widget _buildHeroComponent(PageComponent component) {
    final data = component.data;
    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse(widget.website.theme.colors.primary.substring(1), radix: 16) + 0xFF000000).withOpacity(0.8),
            Color(int.parse(widget.website.theme.colors.secondary.substring(1), radix: 16) + 0xFF000000).withOpacity(0.6),
          ],
        ),
        image: data['backgroundImage'] != null && (data['backgroundImage'] as String).isNotEmpty
            ? DecorationImage(
                image: NetworkImage(data['backgroundImage']),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.overlay,
                ),
              )
            : null,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['title'] ?? widget.website.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (data['subtitle'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  data['subtitle'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (data['buttonText'] != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _handleButtonPress(data['buttonUrl']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(int.parse(widget.website.theme.colors.accent.substring(1), radix: 16) + 0xFF000000),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(data['buttonText']),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextComponent(PageComponent component) {
    final data = component.data;
    return Container(
      padding: const EdgeInsets.all(32),
      child: Text(
        data['content'] ?? '',
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Color(int.parse(widget.website.theme.colors.text.substring(1), radix: 16) + 0xFF000000),
        ),
      ),
    );
  }

  Widget _buildImageComponent(PageComponent component) {
    final data = component.data;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (data['url'] != null && (data['url'] as String).isNotEmpty)
            Image.network(
              data['url'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
            )
          else
            _buildImagePlaceholder(),
          if (data['caption'] != null && (data['caption'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              data['caption'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeakersComponent(PageComponent component) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Featured Speakers',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _selectedDevice == 'mobile' ? 1 : _selectedDevice == 'tablet' ? 2 : 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: 3, // Demo speakers
            itemBuilder: (context, index) {
              return _buildSpeakerCard(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerCard(int index) {
    final speakers = [
      {'name': 'Dr. Sarah Johnson', 'title': 'AI Research Director', 'company': 'Tech Corp'},
      {'name': 'Michael Chen', 'title': 'Product Manager', 'company': 'StartupHub'},
      {'name': 'Lisa Williams', 'title': 'UX Designer', 'company': 'Design Studio'},
    ];
    
    final speaker = speakers[index % speakers.length];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: Text(
                speaker['name']!.split(' ').map((name) => name[0]).join(''),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              speaker['name']!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              speaker['title']!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            Text(
              speaker['company']!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaComponent(PageComponent component) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Event Schedule',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(3, (index) => _buildAgendaItem(index)),
        ],
      ),
    );
  }

  Widget _buildAgendaItem(int index) {
    final sessions = [
      {'time': '09:00 AM', 'title': 'Opening Keynote', 'speaker': 'Dr. Sarah Johnson'},
      {'time': '10:30 AM', 'title': 'AI in Product Development', 'speaker': 'Michael Chen'},
      {'time': '02:00 PM', 'title': 'Design Thinking Workshop', 'speaker': 'Lisa Williams'},
    ];
    
    final session = sessions[index % sessions.length];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: material.BorderRadius.circular(8),
                ),
                child: Text(
                  session['time']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${session['speaker']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSponsorsComponent(PageComponent component) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Our Sponsors',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _selectedDevice == 'mobile' ? 2 : _selectedDevice == 'tablet' ? 3 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: 6, // Demo sponsors
            itemBuilder: (context, index) {
              return _buildSponsorCard(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorCard(int index) {
    final sponsors = ['TechCorp', 'InnovateLabs', 'StartupHub', 'DataFlow', 'CloudTech', 'AI Systems'];
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            sponsors[index % sponsors.length],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownComponent(PageComponent component) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Color(int.parse(widget.website.theme.colors.primary.substring(1), radix: 16) + 0xFF000000).withOpacity(0.1),
      ),
      child: Column(
        children: [
          const Text(
            'Event Starts In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCountdownItem('15', 'Days'),
              _buildCountdownItem('08', 'Hours'),
              _buildCountdownItem('32', 'Minutes'),
              _buildCountdownItem('45', 'Seconds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownItem(String value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(int.parse(widget.website.theme.colors.primary.substring(1), radix: 16) + 0xFF000000),
            borderRadius: material.BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGenericComponent(PageComponent component) {
    return Container(
      height: 150,
      margin: const EdgeInsets.all(16),
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
              Icons.widgets,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              component.type.name,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: material.BorderRadius.circular(8),
      ),
      child: Center(
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
      ),
    );
  }

  Widget _buildWebsiteFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          if (widget.website.settings.footer.showSocialMedia)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.facebook, color: Colors.blue),
                ),
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.alternate_email, color: Colors.blue),
                ),
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.business, color: Colors.blue),
                ),
              ],
            ),
          if (widget.website.settings.footer.showCopyright)
            Text(
              '© ${DateTime.now().year} ${widget.website.title}. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPagesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _pages[index];
        final isCurrentPage = _currentPage?.id == page.id;
        
        return Card(
          color: isCurrentPage ? Colors.blue.withOpacity(0.1) : null,
          child: ListTile(
            leading: Icon(
              _getPageTypeIcon(page.type),
              color: isCurrentPage ? Colors.blue : Colors.grey[600],
            ),
            title: Text(
              page.title,
              style: TextStyle(
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                color: isCurrentPage ? Colors.blue : null,
              ),
            ),
            subtitle: Text('/${page.slug}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: page.isPublished ? Colors.green : Colors.orange,
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
            onTap: () {
              setState(() {
                _currentPage = page;
              });
              _tabController.animateTo(0); // Switch to preview tab
            },
          ),
        );
      },
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

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.website.settings.navigation.items.map((item) {
              return ListTile(
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPage(item.url);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(String url) {
    final targetPage = _pages.firstWhere(
      (page) => '/${page.slug}' == url || (url == '/' && page.type == PageType.homepage),
      orElse: () => _pages.first,
    );
    
    setState(() {
      _currentPage = targetPage;
    });
  }

  void _handleButtonPress(String? url) {
    if (url != null) {
      _navigateToPage(url);
    }
  }

  void _openInBrowser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${widget.website.fullDomain} in browser...')),
    );
  }

  void _shareWebsite() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Website',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              subtitle: Text(widget.website.fullDomain),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('QR Code'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR code feature would be implemented here')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via...'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature would be implemented here')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}