import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/sponsor.dart';
import '../../services/sponsor_service.dart';
import '../../services/gamification_service.dart';
import 'booth_detail_screen.dart';

class ExhibitorHallScreen extends StatefulWidget {
  final Event event;

  const ExhibitorHallScreen({super.key, required this.event});

  @override
  State<ExhibitorHallScreen> createState() => _ExhibitorHallScreenState();
}

class _ExhibitorHallScreenState extends State<ExhibitorHallScreen>
    with SingleTickerProviderStateMixin {
  final SponsorService _sponsorService = SponsorService();
  final GamificationService _gamificationService = GamificationService();
  
  List<ExhibitorBooth> _allBooths = [];
  List<ExhibitorBooth> _filteredBooths = [];
  Map<BoothType, List<ExhibitorBooth>> _boothsByType = {};
  bool _isLoading = false;
  BoothType? _selectedType;
  String _searchQuery = '';
  late TabController _tabController;
  
  final TextEditingController _searchController = TextEditingController();
  final String _currentUserId = 'user1'; // Get from auth in real app

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBooths();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooths() async {
    setState(() => _isLoading = true);

    try {
      _allBooths = await _sponsorService.getEventBooths(widget.event.id);
      _groupBoothsByType();
      _filterBooths();
      
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exhibitor hall: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _groupBoothsByType() {
    _boothsByType.clear();
    for (final booth in _allBooths) {
      if (!_boothsByType.containsKey(booth.type)) {
        _boothsByType[booth.type] = [];
      }
      _boothsByType[booth.type]!.add(booth);
    }
  }

  void _filterBooths() {
    List<ExhibitorBooth> filtered = _allBooths;

    if (_selectedType != null) {
      filtered = filtered.where((booth) => booth.type == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((booth) =>
        booth.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        booth.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    _filteredBooths = filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterBooths();
    setState(() {});
  }

  void _onTypeFilterChanged(BoothType? type) {
    setState(() {
      _selectedType = type;
    });
    _filterBooths();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllBoothsTab(),
              _buildVirtualBoothsTab(),
              _buildPhysicalBoothsTab(),
              _buildHallMapTab(),
            ],
          ),
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
              labelText: 'Search exhibitors...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(
                text: 'All (${_allBooths.length})',
                icon: const Icon(Icons.store),
              ),
              Tab(
                text: 'Virtual (${_boothsByType[BoothType.virtual]?.length ?? 0})',
                icon: const Icon(Icons.computer),
              ),
              Tab(
                text: 'Physical (${_boothsByType[BoothType.physical]?.length ?? 0})',
                icon: const Icon(Icons.location_on),
              ),
              const Tab(
                text: 'Hall Map',
                icon: Icon(Icons.map),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllBoothsTab() {
    return _buildBoothsList(_filteredBooths);
  }

  Widget _buildVirtualBoothsTab() {
    final virtualBooths = _boothsByType[BoothType.virtual] ?? [];
    return _buildBoothsList(virtualBooths);
  }

  Widget _buildPhysicalBoothsTab() {
    final physicalBooths = _boothsByType[BoothType.physical] ?? [];
    return _buildBoothsList(physicalBooths);
  }

  Widget _buildHallMapTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.map, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Interactive Hall Map',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Navigate the exhibition hall and find exhibitor booths',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showInteractiveMap,
                    icon: const Icon(Icons.explore),
                    label: const Text('Open Interactive Map'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildHallOverview(),
        ],
      ),
    );
  }

  Widget _buildHallOverview() {
    final totalBooths = _allBooths.length;
    final virtualBooths = _boothsByType[BoothType.virtual]?.length ?? 0;
    final physicalBooths = _boothsByType[BoothType.physical]?.length ?? 0;
    final hybridBooths = _boothsByType[BoothType.hybrid]?.length ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hall Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Total Booths',
                    '$totalBooths',
                    Icons.store,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildOverviewStat(
                    'Virtual',
                    '$virtualBooths',
                    Icons.computer,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Physical',
                    '$physicalBooths',
                    Icons.location_on,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildOverviewStat(
                    'Hybrid',
                    '$hybridBooths',
                    Icons.device_hub,
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

  Widget _buildOverviewStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBoothsList(List<ExhibitorBooth> booths) {
    if (booths.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadBooths,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: booths.length,
        itemBuilder: (context, index) {
          return _buildBoothCard(booths[index]);
        },
      ),
    );
  }

  Widget _buildBoothCard(ExhibitorBooth booth) {
    final isVisited = booth.visitorIds.contains(_currentUserId);

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _navigateToBoothDetail(booth),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getBoothTypeColor(booth.type).withOpacity(0.1),
                      _getBoothTypeColor(booth.type).withOpacity(0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getBoothTypeIcon(booth.type),
                            size: 32,
                            color: _getBoothTypeColor(booth.type),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booth.typeDisplayName,
                            style: TextStyle(
                              color: _getBoothTypeColor(booth.type),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: booth.isActive ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    if (isVisited)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'VISITED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booth.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        booth.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (booth.location != null) ...[ 
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booth.location!,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(Icons.people, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${booth.totalVisitors}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => _visitBooth(booth),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Visit',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              Icons.store_mall_directory,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedType != null
                  ? 'No booths match your search'
                  : 'No exhibitor booths found',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedType != null
                  ? 'Try adjusting your search or filters'
                  : 'Exhibitor booths will appear here when added',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedType != null) ...[ 
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onTypeFilterChanged(null);
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
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

  IconData _getBoothTypeIcon(BoothType type) {
    switch (type) {
      case BoothType.virtual:
        return Icons.computer;
      case BoothType.physical:
        return Icons.location_on;
      case BoothType.hybrid:
        return Icons.device_hub;
    }
  }

  Future<void> _visitBooth(ExhibitorBooth booth) async {
    try {
      // Record the visit
      await _sponsorService.visitBooth(booth.id, _currentUserId);
      
      // Award gamification points
      await _gamificationService.awardPoints(
        _currentUserId,
        widget.event.id,
        'booth_visit',
        metadata: {
          'boothId': booth.id,
          'boothName': booth.name,
        },
      );
      
      // Navigate to booth detail
      _navigateToBoothDetail(booth);
      
      // Refresh data to show updated visitor count
      _loadBooths();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visited ${booth.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error visiting booth: $e')),
      );
    }
  }

  void _navigateToBoothDetail(ExhibitorBooth booth) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BoothDetailScreen(
          event: widget.event,
          booth: booth,
        ),
      ),
    );
  }

  void _showInteractiveMap() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Interactive Map',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Interactive Hall Map',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Would be implemented with floor plan integration',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}