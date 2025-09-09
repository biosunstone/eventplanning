import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/gamification.dart';
import '../../services/gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final Event event;

  const LeaderboardScreen({super.key, required this.event});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final GamificationService _gamificationService = GamificationService();
  
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = false;
  late TabController _tabController;
  String _selectedCategory = 'overall';
  
  String _currentUserId = 'user1'; // Get from auth provider in real app

  final List<Map<String, String>> _categories = [
    {'key': 'overall', 'label': 'Overall', 'icon': '🏆'},
    {'key': 'sessions', 'label': 'Sessions', 'icon': '📅'},
    {'key': 'networking', 'label': 'Networking', 'icon': '👥'},
    {'key': 'community', 'label': 'Community', 'icon': '💬'},
    {'key': 'photos', 'label': 'Photos', 'icon': '📸'},
    {'key': 'polls', 'label': 'Polls', 'icon': '📊'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      _leaderboard = await _gamificationService.getLeaderboard(
        widget.event.id,
        category: _selectedCategory,
        limit: 100,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
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
            const Text('Leaderboard'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rankings', icon: Icon(Icons.leaderboard)),
            Tab(text: 'My Rank', icon: Icon(Icons.person)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (category) {
              setState(() => _selectedCategory = category);
              _loadLeaderboard();
            },
            itemBuilder: (context) => _categories.map((cat) {
              return PopupMenuItem<String>(
                value: cat['key'],
                child: Row(
                  children: [
                    Text(cat['icon']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Text(cat['label']!),
                    if (_selectedCategory == cat['key']) ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Colors.green),
                    ],
                  ],
                ),
              );
            }).toList(),
            icon: const Icon(Icons.category),
            tooltip: 'Category',
          ),
          IconButton(
            onPressed: _loadLeaderboard,
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
                _buildLeaderboardTab(),
                _buildMyRankTab(),
              ],
            ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.leaderboard,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No rankings available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start participating to see rankings!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(),
            const SizedBox(height: 16),
            if (_leaderboard.length >= 3) _buildPodium(),
            const SizedBox(height: 24),
            _buildLeaderboardList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRankTab() {
    final myEntry = _leaderboard.firstWhere(
      (entry) => entry.userId == _currentUserId,
      orElse: () => LeaderboardEntry(
        userId: _currentUserId,
        userName: 'You',
        userAvatar: '',
        points: 0,
        level: 1,
        rank: _leaderboard.length + 1,
        title: 'Newcomer',
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMyRankCard(myEntry),
          const SizedBox(height: 24),
          _buildNearbyRanks(myEntry),
          const SizedBox(height: 24),
          _buildRankingTips(),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    final selectedCategory = _categories.firstWhere(
      (cat) => cat['key'] == _selectedCategory,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  selectedCategory['icon']!,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedCategory['label']} Leaderboard',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_leaderboard.length} participants',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    final top3 = _leaderboard.take(3).toList();
    while (top3.length < 3) {
      top3.add(LeaderboardEntry(
        userId: '',
        userName: '---',
        userAvatar: '',
        points: 0,
        level: 0,
        rank: top3.length + 1,
        title: '',
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPodiumPlace(top3[1], 2, Colors.grey[600]!), // 2nd place
            _buildPodiumPlace(top3[0], 1, Colors.amber), // 1st place
            _buildPodiumPlace(top3[2], 3, Colors.brown), // 3rd place
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumPlace(LeaderboardEntry entry, int place, Color color) {
    final isEmpty = entry.userId.isEmpty;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: place == 1 ? 80 : 70,
              height: place == 1 ? 80 : 70,
              decoration: BoxDecoration(
                color: isEmpty ? Colors.grey[200] : color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEmpty ? Colors.grey[400]! : color,
                  width: 3,
                ),
              ),
              child: isEmpty
                  ? Icon(Icons.person, color: Colors.grey[400], size: 30)
                  : CircleAvatar(
                      radius: place == 1 ? 35 : 30,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: place == 1 ? 24 : 20,
                        ),
                      ),
                    ),
            ),
            if (!isEmpty)
              Positioned(
                bottom: -5,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$place',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 80,
          child: Column(
            children: [
              Text(
                isEmpty ? '---' : entry.userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: place == 1 ? 16 : 14,
                  color: isEmpty ? Colors.grey[400] : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isEmpty ? '---' : '${entry.points} pts',
                style: TextStyle(
                  color: isEmpty ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                isEmpty ? '' : 'Level ${entry.level}',
                style: TextStyle(
                  color: isEmpty ? Colors.grey[400] : Colors.grey[500],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    final startIndex = _leaderboard.length > 3 ? 3 : 0;
    final listEntries = _leaderboard.skip(startIndex).toList();

    if (listEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Full Rankings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${startIndex + 1}-${_leaderboard.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listEntries.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = listEntries[index];
              final isCurrentUser = entry.userId == _currentUserId;
              return _buildLeaderboardItem(entry, isCurrentUser);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, bool isCurrentUser) {
    return Container(
      color: isCurrentUser ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(entry.rank - 1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            child: Text(
              entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCurrentUser ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (entry.badges.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: entry.badges.take(3).map((badge) {
                      return Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Level ${entry.level}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard(LeaderboardEntry myEntry) {
    final isInTop100 = myEntry.rank <= _leaderboard.length;
    
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      '${myEntry.rank}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Rank',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          isInTop100 ? 'Rank #${myEntry.rank}' : 'Not Ranked',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${myEntry.points} points • Level ${myEntry.level}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${myEntry.points}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Points',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white30),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${myEntry.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Level',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white30),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            myEntry.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'Title',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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
      ),
    );
  }

  Widget _buildNearbyRanks(LeaderboardEntry myEntry) {
    final myRank = myEntry.rank;
    final nearby = <LeaderboardEntry>[];
    
    // Get users around my rank (±5 positions)
    for (int i = (myRank - 6).clamp(1, _leaderboard.length); 
         i <= (myRank + 5).clamp(1, _leaderboard.length); 
         i++) {
      if (i - 1 < _leaderboard.length) {
        nearby.add(_leaderboard[i - 1]);
      }
    }
    
    if (nearby.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Nearby Rankings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nearby.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = nearby[index];
              final isCurrentUser = entry.userId == _currentUserId;
              return _buildLeaderboardItem(entry, isCurrentUser);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ranking Tips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTip('Attend sessions and check-in to earn attendance points', Icons.event_seat),
            _buildTip('Connect with other attendees for networking points', Icons.people),
            _buildTip('Share photos and engage with the community', Icons.photo_camera),
            _buildTip('Participate in polls and Q&A sessions', Icons.poll),
            _buildTip('Complete daily challenges for bonus points', Icons.flag),
            _buildTip('Maintain your daily streak for streak bonuses', Icons.local_fire_department),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey[600]!; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return Theme.of(context).primaryColor;
    }
  }
}