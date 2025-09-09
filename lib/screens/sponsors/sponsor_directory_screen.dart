import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/sponsor.dart';
import '../../services/sponsor_service.dart';
import 'sponsor_detail_screen.dart';
import 'exhibitor_hall_screen.dart';

class SponsorDirectoryScreen extends StatefulWidget {
  final Event event;

  const SponsorDirectoryScreen({super.key, required this.event});

  @override
  State<SponsorDirectoryScreen> createState() => _SponsorDirectoryScreenState();
}

class _SponsorDirectoryScreenState extends State<SponsorDirectoryScreen>
    with SingleTickerProviderStateMixin {
  final SponsorService _sponsorService = SponsorService();
  
  List<Sponsor> _allSponsors = [];
  List<Sponsor> _filteredSponsors = [];
  Map<SponsorTier, List<Sponsor>> _sponsorsByTier = {};
  bool _isLoading = false;
  SponsorTier? _selectedTier;
  String _searchQuery = '';
  late TabController _tabController;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSponsors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSponsors() async {
    setState(() => _isLoading = true);

    try {
      // Generate demo data if needed
      final existingSponsors = await _sponsorService.getEventSponsors(widget.event.id);
      if (existingSponsors.isEmpty) {
        await _sponsorService.generateDemoSponsors(widget.event.id);
        await _sponsorService.generateDemoBooths(widget.event.id);
        await _sponsorService.generateDemoPackages(widget.event.id);
      }

      _allSponsors = await _sponsorService.getEventSponsors(widget.event.id);
      _groupSponsorsByTier();
      _filterSponsors();
      
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sponsors: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _groupSponsorsByTier() {
    _sponsorsByTier.clear();
    for (final sponsor in _allSponsors) {
      if (!_sponsorsByTier.containsKey(sponsor.tier)) {
        _sponsorsByTier[sponsor.tier] = [];
      }
      _sponsorsByTier[sponsor.tier]!.add(sponsor);
    }
  }

  void _filterSponsors() {
    List<Sponsor> filtered = _allSponsors;

    if (_selectedTier != null) {
      filtered = filtered.where((sponsor) => sponsor.tier == _selectedTier).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((sponsor) =>
        sponsor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        sponsor.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        sponsor.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    _filteredSponsors = filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterSponsors();
    setState(() {});
  }

  void _onTierFilterChanged(SponsorTier? tier) {
    setState(() {
      _selectedTier = tier;
    });
    _filterSponsors();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sponsors & Exhibitors'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Directory', icon: Icon(Icons.business)),
            Tab(text: 'By Tier', icon: Icon(Icons.star)),
            Tab(text: 'Exhibitor Hall', icon: Icon(Icons.store)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadSponsors,
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
                _buildDirectoryTab(),
                _buildByTierTab(),
                _buildExhibitorHallTab(),
              ],
            ),
    );
  }

  Widget _buildDirectoryTab() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: _filteredSponsors.isEmpty
              ? _buildEmptyState()
              : _buildSponsorsList(_filteredSponsors),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search sponsors...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _selectedTier == null, () => _onTierFilterChanged(null)),
                const SizedBox(width: 8),
                ...SponsorTier.values.map((tier) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    _getTierDisplayName(tier),
                    _selectedTier == tier,
                    () => _onTierFilterChanged(tier),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildByTierTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: SponsorTier.values.length,
      itemBuilder: (context, index) {
        final tier = SponsorTier.values[index];
        final sponsors = _sponsorsByTier[tier] ?? [];
        
        if (sponsors.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildTierSection(tier, sponsors),
        );
      },
    );
  }

  Widget _buildTierSection(SponsorTier tier, List<Sponsor> sponsors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getTierIcon(tier),
                const SizedBox(width: 8),
                Text(
                  '${_getTierDisplayName(tier)} Sponsors',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getTierColor(tier),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTierColor(tier).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sponsors.length}',
                    style: TextStyle(
                      color: _getTierColor(tier),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sponsors.map((sponsor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSponsorCard(sponsor),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildExhibitorHallTab() {
    return ExhibitorHallScreen(event: widget.event);
  }

  Widget _buildSponsorsList(List<Sponsor> sponsors) {
    return RefreshIndicator(
      onRefresh: _loadSponsors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sponsors.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSponsorCard(sponsors[index]),
          );
        },
      ),
    );
  }

  Widget _buildSponsorCard(Sponsor sponsor) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToSponsorDetail(sponsor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                      image: DecorationImage(
                        image: NetworkImage(sponsor.logoUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {},
                      ),
                      color: Colors.grey[200],
                    ),
                    child: sponsor.logoUrl.isEmpty
                        ? Icon(Icons.business, color: Colors.grey[500])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sponsor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (sponsor.isFeatured)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _getTierIcon(sponsor.tier, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              sponsor.tierDisplayName,
                              style: TextStyle(
                                color: _getTierColor(sponsor.tier),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _getTypeIcon(sponsor.type),
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sponsor.typeDisplayName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sponsor.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (sponsor.tags.isNotEmpty) ...[ 
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: sponsor.tags.take(3).map((tag) {
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
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (sponsor.hasWebsite) ...[
                    Icon(Icons.language, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Website',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (sponsor.hasWebsite && sponsor.hasSocialMedia)
                    const SizedBox(width: 12),
                  if (sponsor.hasSocialMedia) ...[
                    Icon(Icons.share, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Social Media',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _navigateToSponsorDetail(sponsor),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedTier != null
                  ? 'No sponsors match your search'
                  : 'No sponsors found',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedTier != null
                  ? 'Try adjusting your search or filters'
                  : 'Sponsors will appear here when added',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedTier != null) ...[ 
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onTierFilterChanged(null);
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getTierIcon(SponsorTier tier, {double size = 20}) {
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
    return Icon(icon, size: size, color: _getTierColor(tier));
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

  String _getTierDisplayName(SponsorTier tier) {
    switch (tier) {
      case SponsorTier.platinum:
        return 'Platinum';
      case SponsorTier.gold:
        return 'Gold';
      case SponsorTier.silver:
        return 'Silver';
      case SponsorTier.bronze:
        return 'Bronze';
      case SponsorTier.startup:
        return 'Startup';
      case SponsorTier.community:
        return 'Community';
    }
  }

  IconData _getTypeIcon(SponsorType type) {
    switch (type) {
      case SponsorType.corporate:
        return Icons.corporate_fare;
      case SponsorType.startup:
        return Icons.rocket_launch;
      case SponsorType.nonprofit:
        return Icons.volunteer_activism;
      case SponsorType.media:
        return Icons.mic;
      case SponsorType.government:
        return Icons.account_balance;
      case SponsorType.academic:
        return Icons.school;
    }
  }

  void _navigateToSponsorDetail(Sponsor sponsor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SponsorDetailScreen(
          event: widget.event,
          sponsor: sponsor,
        ),
      ),
    );
  }
}