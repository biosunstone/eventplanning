import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/gamification.dart';
import '../../services/gamification_service.dart';

class AchievementsScreen extends StatefulWidget {
  final Event event;

  const AchievementsScreen({super.key, required this.event});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final GamificationService _gamificationService = GamificationService();
  
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  late TabController _tabController;
  
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    try {
      _achievements = await _gamificationService.getUserAchievements(
        _currentUserId,
        widget.event.id,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading achievements: $e')),
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
            const Text('Achievements'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Unlocked', icon: Icon(Icons.check_circle)),
            Tab(text: 'Locked', icon: Icon(Icons.lock)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadAchievements,
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
                _buildAchievementsList(_achievements),
                _buildAchievementsList(_achievements.where((a) => a.isUnlocked).toList()),
                _buildAchievementsList(_achievements.where((a) => !a.isUnlocked).toList()),
              ],
            ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements) {
    if (achievements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No achievements found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start participating in event activities to unlock achievements!',
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

    // Group achievements by type
    final groupedAchievements = <AchievementType, List<Achievement>>{};
    for (final achievement in achievements) {
      groupedAchievements[achievement.type] ??= [];
      groupedAchievements[achievement.type]!.add(achievement);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAchievementSummary(achievements),
          const SizedBox(height: 24),
          ...groupedAchievements.entries.map((entry) {
            return _buildAchievementCategory(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementSummary(List<Achievement> achievements) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalPoints = achievements.where((a) => a.isUnlocked).fold(0, (sum, a) => sum + a.points);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Unlocked',
                '$unlockedCount/${achievements.length}',
                Icons.emoji_events,
                Colors.orange,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Expanded(
              child: _buildSummaryItem(
                'Points Earned',
                totalPoints.toString(),
                Icons.stars,
                Colors.blue,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Expanded(
              child: _buildSummaryItem(
                'Progress',
                '${((unlockedCount / achievements.length) * 100).toStringAsFixed(0)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
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
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCategory(AchievementType type, List<Achievement> achievements) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getAchievementTypeLabel(type),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              return _buildAchievementCard(achievements[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final rarityColor = _getRarityColor(achievement.rarity);

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Card(
        elevation: isUnlocked ? 4 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked ? rarityColor : Colors.grey[300]!,
              width: isUnlocked ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isUnlocked 
                            ? rarityColor.withOpacity(0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isUnlocked ? rarityColor : Colors.grey[400]!,
                        ),
                      ),
                      child: Icon(
                        _getAchievementIcon(achievement.type),
                        color: isUnlocked ? rarityColor : Colors.grey[500],
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUnlocked 
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${achievement.points}',
                        style: TextStyle(
                          color: isUnlocked ? Colors.orange : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  achievement.isSecret && !isUnlocked ? '???' : achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isUnlocked ? Colors.black87 : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.isSecret && !isUnlocked 
                      ? 'Hidden achievement' 
                      : achievement.description,
                  style: TextStyle(
                    color: isUnlocked ? Colors.grey[700] : Colors.grey[500],
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (!isUnlocked) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(achievement.progress * 100).toStringAsFixed(0)}% complete',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (isUnlocked) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Unlocked',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRarityLabel(achievement.rarity),
                          style: TextStyle(
                            color: rarityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: achievement.isUnlocked 
                      ? _getRarityColor(achievement.rarity).withOpacity(0.2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: achievement.isUnlocked 
                        ? _getRarityColor(achievement.rarity)
                        : Colors.grey[400]!,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _getAchievementIcon(achievement.type),
                  color: achievement.isUnlocked 
                      ? _getRarityColor(achievement.rarity)
                      : Colors.grey[500],
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                achievement.isSecret && !achievement.isUnlocked 
                    ? 'Secret Achievement' 
                    : achievement.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRarityColor(achievement.rarity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRarityLabel(achievement.rarity),
                  style: TextStyle(
                    color: _getRarityColor(achievement.rarity),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                achievement.isSecret && !achievement.isUnlocked 
                    ? 'This is a hidden achievement. Complete the requirements to reveal it!'
                    : achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '${achievement.points}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Text(
                        'Points',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _getAchievementTypeLabel(achievement.type),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (achievement.isUnlocked)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                        const Text(
                          'Unlocked',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Text(
                          '${(achievement.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Progress',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (!achievement.isUnlocked) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: achievement.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getRarityColor(achievement.rarity)),
                ),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAchievementTypeLabel(AchievementType type) {
    switch (type) {
      case AchievementType.attendance:
        return 'Attendance';
      case AchievementType.networking:
        return 'Networking';
      case AchievementType.engagement:
        return 'Engagement';
      case AchievementType.social:
        return 'Social';
      case AchievementType.learning:
        return 'Learning';
      case AchievementType.participation:
        return 'Participation';
      case AchievementType.milestone:
        return 'Milestone';
      case AchievementType.special:
        return 'Special';
    }
  }

  String _getRarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
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
}