import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/attendee_profile.dart';
import '../../services/networking_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/attendee_profile_card.dart';

class NetworkingScreen extends StatefulWidget {
  final Event event;

  const NetworkingScreen({super.key, required this.event});

  @override
  State<NetworkingScreen> createState() => _NetworkingScreenState();
}

class _NetworkingScreenState extends State<NetworkingScreen>
    with SingleTickerProviderStateMixin {
  final NetworkingService _networkingService = NetworkingService();
  final _searchController = TextEditingController();
  
  late TabController _tabController;
  List<AttendeeProfile> _allProfiles = [];
  List<AttendeeProfile> _searchResults = [];
  List<NetworkingRecommendation> _recommendations = [];
  Map<String, List<AttendeeProfile>> _groupedProfiles = {};
  
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNetworkingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNetworkingData() async {
    setState(() => _isLoading = true);

    // In a real app, this would fetch from your backend
    _allProfiles = _generateSampleProfiles();
    _searchResults = _allProfiles;
    
    if (_allProfiles.isNotEmpty) {
      final userProfile = _allProfiles.first;
      _recommendations = await _networkingService.getRecommendations(
        userProfile,
        _allProfiles.skip(1).toList(),
      );
      
      _groupedProfiles = await _networkingService.groupProfilesByAttribute(
        _allProfiles,
        'company',
      );
    }

    setState(() => _isLoading = false);
  }

  List<AttendeeProfile> _generateSampleProfiles() {
    // Sample data - replace with real data from your backend
    return [
      AttendeeProfile(
        id: '1',
        userId: 'user1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        company: 'Tech Corp',
        jobTitle: 'Software Engineer',
        industry: 'Technology',
        city: 'San Francisco',
        country: 'USA',
        interests: ['Flutter', 'AI', 'Mobile Development'],
        skills: ['Dart', 'React', 'Python'],
        professionalLevel: ProfessionalLevel.senior,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      AttendeeProfile(
        id: '2',
        userId: 'user2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        company: 'Design Studio',
        jobTitle: 'UX Designer',
        industry: 'Design',
        city: 'New York',
        country: 'USA',
        interests: ['UX Design', 'Psychology', 'Art'],
        skills: ['Figma', 'Sketch', 'User Research'],
        professionalLevel: ProfessionalLevel.mid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Add more sample profiles...
    ];
  }

  Future<void> _searchProfiles(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = _allProfiles);
      return;
    }

    final results = await _networkingService.searchProfiles(
      query: query,
      profiles: _allProfiles,
    );

    setState(() => _searchResults = results);
  }

  void _navigateToProfileDetail(AttendeeProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${profile.firstName} ${profile.lastName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company: ${profile.company}'),
            Text('Job Title: ${profile.jobTitle}'),
            Text('Industry: ${profile.industry}'),
            Text('Location: ${profile.city}, ${profile.country}'),
            const SizedBox(height: 8),
            const Text('Interests:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...profile.interests.map((interest) => Text('• $interest')),
            const SizedBox(height: 8),
            const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...profile.skills.map((skill) => Text('• $skill')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connection request sent to ${profile.firstName}')),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile creation feature - functionality demonstrated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Networking'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToCreateProfile,
            icon: const Icon(Icons.person_add),
            tooltip: 'Complete Profile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.people)),
            Tab(text: 'Recommended', icon: Icon(Icons.recommend)),
            Tab(text: 'Companies', icon: Icon(Icons.business)),
            Tab(text: 'Interests', icon: Icon(Icons.interests)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllProfilesTab(),
                _buildRecommendationsTab(),
                _buildCompaniesTab(),
                _buildInterestsTab(),
              ],
            ),
    );
  }

  Widget _buildAllProfilesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CustomTextField(
                controller: _searchController,
                labelText: 'Search attendees',
                prefixIcon: Icons.search,
                onChanged: _searchProfiles,
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All'),
                    _buildFilterChip('company', 'Same Company'),
                    _buildFilterChip('industry', 'Same Industry'),
                    _buildFilterChip('location', 'Same Location'),
                    _buildFilterChip('level', 'Similar Level'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? _buildEmptyState('No attendees found', 'Try adjusting your search filters')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final profile = _searchResults[index];
                    return AttendeeProfileCard(
                      profile: profile,
                      onTap: () => _navigateToProfileDetail(profile),
                      showRecommendationReason: false,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return _buildEmptyState(
        'No recommendations available',
        'Complete your profile to get personalized recommendations',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        final profile = _allProfiles.firstWhere(
          (p) => p.id == recommendation.profileId,
        );

        return AttendeeProfileCard(
          profile: profile,
          onTap: () => _navigateToProfileDetail(profile),
          showRecommendationReason: true,
          recommendationReason: recommendation.reason,
          recommendationScore: recommendation.score,
        );
      },
    );
  }

  Widget _buildCompaniesTab() {
    if (_groupedProfiles.isEmpty) {
      return _buildEmptyState('No companies found', 'Attendees will be grouped by company');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groupedProfiles.keys.length,
      itemBuilder: (context, index) {
        final company = _groupedProfiles.keys.elementAt(index);
        final profiles = _groupedProfiles[company]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(company),
            subtitle: Text('${profiles.length} attendees'),
            leading: CircleAvatar(
              child: Text(company.substring(0, 1)),
            ),
            children: profiles
                .map((profile) => ListTile(
                      title: Text(profile.fullName),
                      subtitle: Text(profile.jobTitle ?? 'No title'),
                      onTap: () => _navigateToProfileDetail(profile),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildInterestsTab() {
    return FutureBuilder<List<String>>(
      future: _networkingService.getPopularInterests(_allProfiles),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final interests = snapshot.data!;
        if (interests.isEmpty) {
          return _buildEmptyState('No interests found', 'Attendees can add interests to their profiles');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: interests.length,
          itemBuilder: (context, index) {
            final interest = interests[index];
            final interestedProfiles = _allProfiles
                .where((p) => p.interests.contains(interest))
                .toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(interest),
                subtitle: Text('${interestedProfiles.length} people interested'),
                leading: const CircleAvatar(
                  child: Icon(Icons.interests),
                ),
                children: interestedProfiles
                    .map((profile) => ListTile(
                          title: Text(profile.fullName),
                          subtitle: Text(profile.company ?? 'No company'),
                          onTap: () => _navigateToProfileDetail(profile),
                        ))
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() => _selectedFilter = selected ? value : 'all');
          _applyFilter();
        },
      ),
    );
  }

  void _applyFilter() {
    // Implement filtering logic based on _selectedFilter
    switch (_selectedFilter) {
      case 'all':
        setState(() => _searchResults = _allProfiles);
        break;
      case 'company':
        // Filter by same company
        break;
      case 'industry':
        // Filter by same industry
        break;
      case 'location':
        // Filter by same location
        break;
      case 'level':
        // Filter by similar professional level
        break;
    }
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
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
        ],
      ),
    );
  }
}