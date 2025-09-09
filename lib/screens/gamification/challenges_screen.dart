import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/gamification.dart';
import '../../services/gamification_service.dart';

class ChallengesScreen extends StatefulWidget {
  final Event event;

  const ChallengesScreen({super.key, required this.event});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  final GamificationService _gamificationService = GamificationService();
  
  List<Challenge> _challenges = [];
  bool _isLoading = false;
  late TabController _tabController;
  
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);

    try {
      _challenges = await _gamificationService.getEventChallenges(widget.event.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading challenges: $e')),
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
            const Text('Challenges'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.flag)),
            Tab(text: 'Active', icon: Icon(Icons.play_arrow)),
            Tab(text: 'My Challenges', icon: Icon(Icons.person)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadChallenges,
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
                _buildChallengesList(_challenges),
                _buildChallengesList(_challenges.where((c) => c.isActive).toList()),
                _buildChallengesList(_challenges.where((c) => c.participants.contains(_currentUserId)).toList()),
                _buildChallengesList(_challenges.where((c) => c.isCompleted).toList()),
              ],
            ),
    );
  }

  Widget _buildChallengesList(List<Challenge> challenges) {
    if (challenges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No challenges found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Check back later for new challenges!',
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

    // Group challenges by type
    final groupedChallenges = <ChallengeType, List<Challenge>>{};
    for (final challenge in challenges) {
      groupedChallenges[challenge.type] ??= [];
      groupedChallenges[challenge.type]!.add(challenge);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChallengesSummary(challenges),
          const SizedBox(height: 24),
          ...groupedChallenges.entries.map((entry) {
            return _buildChallengeCategory(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildChallengesSummary(List<Challenge> challenges) {
    final activeChallenges = challenges.where((c) => c.isActive).length;
    final myChallenges = challenges.where((c) => c.participants.contains(_currentUserId)).length;
    final completedChallenges = challenges.where((c) => c.isCompleted && c.participants.contains(_currentUserId)).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Active',
                activeChallenges.toString(),
                Icons.play_arrow,
                Colors.green,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Expanded(
              child: _buildSummaryItem(
                'Joined',
                myChallenges.toString(),
                Icons.person,
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
                'Completed',
                completedChallenges.toString(),
                Icons.check_circle,
                Colors.orange,
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

  Widget _buildChallengeCategory(ChallengeType type, List<Challenge> challenges) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getChallengeTypeLabel(type),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...challenges.map((challenge) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildChallengeCard(challenge),
          )),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final isJoined = challenge.participants.contains(_currentUserId);
    final statusColor = _getStatusColor(challenge.status);
    final timeRemaining = challenge.timeRemaining;

    return Card(
      elevation: isJoined ? 4 : 2,
      child: InkWell(
        onTap: () => _showChallengeDetails(challenge),
        borderRadius: BorderRadius.circular(12),
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
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Icon(
                      _getChallengeIcon(challenge.type),
                      color: statusColor,
                      size: 20,
                    ),
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
                                challenge.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (challenge.isTeamChallenge)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'TEAM',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${challenge.points}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(challenge.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${challenge.currentValue}/${challenge.targetValue}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: challenge.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (challenge.isActive && timeRemaining.inSeconds > 0) ...[
                          Text(
                            'Time Left',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimeRemaining(timeRemaining),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ] else if (challenge.isCompleted) ...[
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else if (challenge.isExpired) ...[
                          const Icon(
                            Icons.access_time,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Expired',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (challenge.participants.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${challenge.participants.length} participant${challenge.participants.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (challenge.isActive && !isJoined)
                    ElevatedButton(
                      onPressed: () => _joinChallenge(challenge),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Join Challenge',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  else if (isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Joined',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  void _showChallengeDetails(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getStatusColor(challenge.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: _getStatusColor(challenge.status),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    _getChallengeIcon(challenge.type),
                    color: _getStatusColor(challenge.status),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(challenge.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusLabel(challenge.status),
                        style: TextStyle(
                          color: _getStatusColor(challenge.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (challenge.isTeamChallenge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TEAM CHALLENGE',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  challenge.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDetailItem(
                            'Progress',
                            '${challenge.currentValue}/${challenge.targetValue}',
                            Icons.trending_up,
                          ),
                          _buildDetailItem(
                            'Points',
                            '+${challenge.points}',
                            Icons.stars,
                          ),
                          _buildDetailItem(
                            'Participants',
                            '${challenge.participants.length}',
                            Icons.people,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: challenge.progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(challenge.status)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(challenge.progress * 100).toStringAsFixed(1)}% Complete',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(challenge.startDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'End Date',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(challenge.endDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (challenge.isActive && challenge.timeRemaining.inSeconds > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Time Remaining: ${_formatTimeRemaining(challenge.timeRemaining)}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                    if (challenge.isActive && !challenge.participants.contains(_currentUserId)) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _joinChallenge(challenge);
                          },
                          child: const Text('Join Challenge'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
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

  Future<void> _joinChallenge(Challenge challenge) async {
    try {
      final success = await _gamificationService.joinChallenge(
        _currentUserId,
        widget.event.id,
        challenge.id,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${challenge.title}" successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadChallenges(); // Refresh challenges
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join challenge'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining challenge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getChallengeTypeLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.attendance:
        return 'Attendance Challenges';
      case ChallengeType.networking:
        return 'Networking Challenges';
      case ChallengeType.photo:
        return 'Photo Challenges';
      case ChallengeType.poll:
        return 'Poll Challenges';
      case ChallengeType.session:
        return 'Session Challenges';
      case ChallengeType.community:
        return 'Community Challenges';
      case ChallengeType.daily:
        return 'Daily Challenges';
      case ChallengeType.weekly:
        return 'Weekly Challenges';
      case ChallengeType.special:
        return 'Special Challenges';
    }
  }

  String _getStatusLabel(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.active:
        return 'ACTIVE';
      case ChallengeStatus.completed:
        return 'COMPLETED';
      case ChallengeStatus.expired:
        return 'EXPIRED';
      case ChallengeStatus.locked:
        return 'LOCKED';
    }
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.completed:
        return Colors.blue;
      case ChallengeStatus.expired:
        return Colors.red;
      case ChallengeStatus.locked:
        return Colors.grey;
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

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}