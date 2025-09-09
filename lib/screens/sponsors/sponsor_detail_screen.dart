import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event.dart';
import '../../models/sponsor.dart';
import '../../services/sponsor_service.dart';

class SponsorDetailScreen extends StatefulWidget {
  final Event event;
  final Sponsor sponsor;

  const SponsorDetailScreen({
    super.key,
    required this.event,
    required this.sponsor,
  });

  @override
  State<SponsorDetailScreen> createState() => _SponsorDetailScreenState();
}

class _SponsorDetailScreenState extends State<SponsorDetailScreen>
    with SingleTickerProviderStateMixin {
  final SponsorService _sponsorService = SponsorService();
  
  List<ExhibitorBooth> _booths = [];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBoothData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBoothData() async {
    setState(() => _isLoading = true);

    try {
      _booths = await _sponsorService.getSponsorBooths(widget.sponsor.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booth data: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSponsorInfo(),
                _buildTabSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.sponsor.bannerUrl.isNotEmpty)
              Image.network(
                widget.sponsor.bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultBanner(),
              )
            else
              _buildDefaultBanner(),
            Container(
              decoration: BoxDecoration(
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
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(widget.sponsor.logoUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {},
                      ),
                      color: Colors.white,
                    ),
                    child: widget.sponsor.logoUrl.isEmpty
                        ? const Icon(Icons.business, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sponsor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _getTierIcon(widget.sponsor.tier),
                            const SizedBox(width: 8),
                            Text(
                              widget.sponsor.tierDisplayName,
                              style: TextStyle(
                                color: _getTierColor(widget.sponsor.tier),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showShareOptions,
          icon: const Icon(Icons.share),
          tooltip: 'Share',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            if (widget.sponsor.hasWebsite)
              const PopupMenuItem(
                value: 'website',
                child: ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Visit Website'),
                  dense: true,
                ),
              ),
            const PopupMenuItem(
              value: 'contact',
              child: ListTile(
                leading: Icon(Icons.contact_mail),
                title: Text('Contact Info'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'booths',
              child: ListTile(
                leading: Icon(Icons.store),
                title: Text('View Booths'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      color: _getTierColor(widget.sponsor.tier).withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.business,
          size: 100,
          color: _getTierColor(widget.sponsor.tier).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildSponsorInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
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
                      'About ${widget.sponsor.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.sponsor.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.sponsor.isFeatured) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (widget.sponsor.tags.isNotEmpty) ...[ 
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.sponsor.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        if (widget.sponsor.hasWebsite)
          Expanded(
            child: _buildActionButton(
              'Visit Website',
              Icons.language,
              Colors.blue,
              () => _launchWebsite(),
            ),
          ),
        if (widget.sponsor.hasWebsite && _booths.isNotEmpty)
          const SizedBox(width: 12),
        if (_booths.isNotEmpty)
          Expanded(
            child: _buildActionButton(
              'Visit Booth',
              Icons.store,
              Colors.green,
              () => _visitFirstBooth(),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Contact',
            Icons.contact_mail,
            Colors.orange,
            () => _showContactInfo(),
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
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      height: 500,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Booths', icon: Icon(Icons.store)),
              Tab(text: 'Media', icon: Icon(Icons.photo_library)),
              Tab(text: 'Contact', icon: Icon(Icons.contact_mail)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBoothsTab(),
                _buildMediaTab(),
                _buildContactTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoothsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_booths.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No booths available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'This sponsor doesn\'t have any exhibition booths',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _booths.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBoothCard(_booths[index]),
        );
      },
    );
  }

  Widget _buildBoothCard(ExhibitorBooth booth) {
    return Card(
      child: InkWell(
        onTap: () => _visitBooth(booth),
        borderRadius: BorderRadius.circular(12),
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
                      color: _getBoothTypeColor(booth.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booth.typeDisplayName,
                      style: TextStyle(
                        color: _getBoothTypeColor(booth.type),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (booth.isActive)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booth.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                booth.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              if (booth.location != null) ...[ 
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      booth.location!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${booth.totalVisitors} visitors',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${booth.staffCount} staff',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _visitBooth(booth),
                    child: const Text('Visit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
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

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.sponsor.hasVideo) ...[ 
            const Text(
              'Video Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Company Introduction Video',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'Social Media',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (widget.sponsor.hasSocialMedia) ...[ 
            ...widget.sponsor.socialMedia.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSocialMediaItem(entry.key, entry.value),
              );
            }),
          ] else
            const Text(
              'No social media links available',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaItem(String platform, String handle) {
    IconData icon;
    Color color;
    
    switch (platform.toLowerCase()) {
      case 'twitter':
        icon = Icons.alternate_email;
        color = Colors.blue;
        break;
      case 'linkedin':
        icon = Icons.business;
        color = Colors.blue[800]!;
        break;
      case 'youtube':
        icon = Icons.video_library;
        color = Colors.red;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      default:
        icon = Icons.link;
        color = Colors.grey;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(platform.toUpperCase()),
      subtitle: Text(handle),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => _launchSocialMedia(platform, handle),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...widget.sponsor.contactInfo.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildContactInfoItem(entry.key, entry.value),
            );
          }),
          if (widget.sponsor.contactInfo.isEmpty)
            const Text(
              'No contact information available',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfoItem(String key, dynamic value) {
    IconData icon;
    switch (key.toLowerCase()) {
      case 'email':
        icon = Icons.email;
        break;
      case 'phone':
        icon = Icons.phone;
        break;
      case 'address':
        icon = Icons.location_on;
        break;
      default:
        icon = Icons.info;
    }

    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(key.toUpperCase()),
      subtitle: Text(value.toString()),
      trailing: const Icon(Icons.copy),
      onTap: () => _copyToClipboard(value.toString()),
    );
  }

  Widget _getTierIcon(SponsorTier tier, {double size = 24}) {
    IconData icon;
    switch (tier) {
      case SponsorTier.platinum:
        icon = Icons.diamond;
        break;
      case SponsorTier.gold:
        icon = Icons.emoji_events;
        break;
      case SponsorTier.silver:
        icon = Icons.military_tech;
        break;
      case SponsorTier.bronze:
        icon = Icons.grade;
        break;
      case SponsorTier.startup:
        icon = Icons.rocket_launch;
        break;
      case SponsorTier.community:
        icon = Icons.groups;
        break;
    }
    return Icon(icon, size: size, color: Colors.white);
  }

  Color _getTierColor(SponsorTier tier) {
    switch (tier) {
      case SponsorTier.platinum:
        return const Color(0xFF9CA3AF);
      case SponsorTier.gold:
        return const Color(0xFFD97706);
      case SponsorTier.silver:
        return const Color(0xFF6B7280);
      case SponsorTier.bronze:
        return const Color(0xFFA16207);
      case SponsorTier.startup:
        return Colors.purple;
      case SponsorTier.community:
        return Colors.green;
    }
  }

  Color _getBoothTypeColor(BoothType type) {
    switch (type) {
      case BoothType.virtual:
        return Colors.blue;
      case BoothType.physical:
        return Colors.green;
      case BoothType.hybrid:
        return Colors.purple;
    }
  }

  Future<void> _launchWebsite() async {
    final url = Uri.parse(widget.sponsor.websiteUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchSocialMedia(String platform, String handle) async {
    // This would launch the appropriate social media app/website
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $platform: $handle')),
    );
  }

  void _copyToClipboard(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard: $text')),
    );
  }

  void _visitFirstBooth() {
    if (_booths.isNotEmpty) {
      _visitBooth(_booths.first);
    }
  }

  void _visitBooth(ExhibitorBooth booth) {
    // Record the visit
    _sponsorService.visitBooth(booth.id, 'current_user_id');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Visiting ${booth.name}')),
    );
  }

  void _showContactInfo() {
    _tabController.animateTo(2);
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Sponsor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via...'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'website':
        _launchWebsite();
        break;
      case 'contact':
        _showContactInfo();
        break;
      case 'booths':
        _tabController.animateTo(0);
        break;
    }
  }
}