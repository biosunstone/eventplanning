import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/gamification.dart';
import '../../services/gamification_service.dart';
import '../../widgets/custom_fab.dart';
import 'achievements_screen.dart';
import 'challenges_screen.dart';
import 'leaderboard_screen.dart';

class GamificationDashboardScreen extends StatefulWidget {
  final Event event;

  const GamificationDashboardScreen({super.key, required this.event});

  @override
  State<GamificationDashboardScreen> createState() => _GamificationDashboardScreenState();
}

class _GamificationDashboardScreenState extends State<GamificationDashboardScreen>
    with SingleTickerProviderStateMixin {
  final GamificationService _gamificationService = GamificationService();
  
  UserGamificationProfile? _userProfile;
  List<LeaderboardEntry> _topUsers = [];
  List<Achievement> _recentAchievements = [];
  List<Challenge> _activeChallenges = [];
  List<GamificationAction> _recentActivity = [];
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _loadGamificationData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGamificationData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _gamificationService.getUserProfile(_currentUserId, widget.event.id),
        _gamificationService.getLeaderboard(widget.event.id, limit: 5),
        _gamificationService.getUserAchievements(_currentUserId, widget.event.id),
        _gamificationService.getEventChallenges(widget.event.id),
        _gamificationService.getUserRecentActivity(_currentUserId, widget.event.id, limit: 10),
      ]);

      _userProfile = results[0] as UserGamificationProfile;
      _topUsers = results[1] as List<LeaderboardEntry>;
      final allAchievements = results[2] as List<Achievement>;
      final allChallenges = results[3] as List<Challenge>;
      _recentActivity = results[4] as List<GamificationAction>;

      _recentAchievements = allAchievements
          .where((a) => a.isUnlocked)
          .take(3)
          .toList();

      _activeChallenges = allChallenges
          .where((c) => c.isActive && c.participants.contains(_currentUserId))
          .take(3)
          .toList();

      if (mounted) {
        setState(() {});
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading gamification data: $e')),
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
            const Text('Gamification'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadGamificationData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGamificationData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserProfileCard(),
                            const SizedBox(height: 24),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildRecentAchievements(),
                            const SizedBox(height: 24),
                            _buildActiveChallenges(),
                            const SizedBox(height: 24),
                            _buildLeaderboardPreview(),
                            const SizedBox(height: 24),
                            _buildRecentActivity(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: CustomFAB(
        onPressed: () => _showFullLeaderboard(),
        icon: Icons.leaderboard,
        label: 'Leaderboard',
      ),
    );
  }

  Widget _buildUserProfileCard() {
    if (_userProfile == null) return const SizedBox.shrink();

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
                      'L${_userProfile!.level}',
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
                        Text(
                          _userProfile!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_userProfile!.totalPoints} points • Level ${_userProfile!.level}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_userProfile!.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_userProfile!.streak}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progress to next level',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${_userProfile!.experiencePoints}/${_userProfile!.experiencePoints + _userProfile!.experienceToNextLevel}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _userProfile!.levelProgress,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Achievements',
                    Icons.emoji_events,
                    Colors.orange,
                    () => _navigateToAchievements(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Challenges',
                    Icons.flag,
                    Colors.green,
                    () => _navigateToChallenges(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Leaderboard',
                    Icons.leaderboard,
                    Colors.blue,
                    () => _showFullLeaderboard(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAchievements() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Achievements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _navigateToAchievements,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentAchievements.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No achievements unlocked yet.\nStart participating to earn your first achievement!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_recentAchievements.map((achievement) {
                return _buildAchievementItem(achievement);
              })),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRarityColor(achievement.rarity).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getRarityColor(achievement.rarity)),
            ),
            child: Icon(
              _getAchievementIcon(achievement.type),
              color: _getRarityColor(achievement.rarity),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+${achievement.points}',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallenges() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Active Challenges',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _navigateToChallenges,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_activeChallenges.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No active challenges.\nCheck out available challenges to join!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_activeChallenges.map((challenge) {
                return _buildChallengeItem(challenge);
              })),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeItem(Challenge challenge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getChallengeIcon(challenge.type),
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${challenge.points}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            challenge.description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: challenge.progress,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${challenge.currentValue}/${challenge.targetValue}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Top Performers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showFullLeaderboard,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_topUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              return _buildLeaderboardItem(user, index);
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry user, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getRankColor(index),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user.title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.points}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Level ${user.level}',
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

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_recentActivity.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No recent activity.\nStart participating to see your progress here!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _recentActivity.length,
                  itemBuilder: (context, index) {
                    final activity = _recentActivity[index];
                    return _buildActivityItem(activity);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(GamificationAction activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity.description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            _formatTimeAgo(activity.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  IconData _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.attendance:
        return Icons.event_seat;
      case AchievementType.networking:
        return Icons.people;
      case AchievementType.engagement:
        return Icons.favorite;
      case AchievementType.social:
        return Icons.photo_camera;
      case AchievementType.learning:
        return Icons.school;
      case AchievementType.participation:
        return Icons.how_to_vote;
      case AchievementType.milestone:
        return Icons.flag;
      case AchievementType.special:
        return Icons.star;
    }
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.attendance:
        return Icons.event_seat;
      case ChallengeType.networking:
        return Icons.people;
      case ChallengeType.photo:
        return Icons.photo_camera;
      case ChallengeType.poll:
        return Icons.poll;
      case ChallengeType.session:
        return Icons.event;
      case ChallengeType.community:
        return Icons.forum;
      case ChallengeType.daily:
        return Icons.today;
      case ChallengeType.weekly:
        return Icons.date_range;
      case ChallengeType.special:
        return Icons.star;
    }
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
        return Colors.blue;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AchievementsScreen(event: widget.event),
      ),
    );
  }

  void _navigateToChallenges() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChallengesScreen(event: widget.event),
      ),
    );
  }

  void _showFullLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeaderboardScreen(event: widget.event),
      ),
    );
  }
}