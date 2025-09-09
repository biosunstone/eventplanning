import '../models/gamification.dart';
import '../models/event.dart';
import 'database_service.dart';
import 'profile_service.dart';

class GamificationService {
  final DatabaseService _databaseService = DatabaseService();
  final ProfileService _profileService = ProfileService();

  // Points configuration
  static const Map<String, int> pointsConfig = {
    'session_checkin': 10,
    'session_complete': 25,
    'photo_upload': 15,
    'photo_like': 5,
    'community_post': 20,
    'community_comment': 10,
    'community_like': 5,
    'poll_participation': 15,
    'message_sent': 5,
    'connection_made': 30,
    'profile_complete': 50,
    'announcement_read': 5,
    'daily_login': 10,
    'streak_bonus': 25,
    'challenge_complete': 100,
    'achievement_unlock': 50,
  };

  // Level requirements
  static const List<int> levelRequirements = [
    0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700, 3250,
    3850, 4500, 5200, 5950, 6750, 7600, 8500, 9450, 10450, 11500,
  ];

  // Initialize user gamification profile
  Future<UserGamificationProfile> initializeUserProfile(String userId, String eventId) async {
    final db = await _databaseService.database;
    
    // Check if profile already exists
    final List<Map<String, dynamic>> existing = await db.query(
      'user_gamification_profiles',
      where: 'userId = ? AND eventId = ?',
      whereArgs: [userId, eventId],
    );

    if (existing.isNotEmpty) {
      return UserGamificationProfile.fromJson(existing.first);
    }

    // Create new profile
    final profile = UserGamificationProfile(
      userId: userId,
      eventId: eventId,
      lastActiveDate: DateTime.now(),
    );

    await db.insert('user_gamification_profiles', profile.toJson());
    
    // Initialize with welcome achievement
    await _checkAndUnlockAchievement(userId, eventId, 'welcome');
    
    return profile;
  }

  // Award points for an action
  Future<UserGamificationProfile> awardPoints(
    String userId, 
    String eventId, 
    String actionType, {
    Map<String, dynamic>? metadata,
  }) async {
    final points = pointsConfig[actionType] ?? 0;
    if (points == 0) return await getUserProfile(userId, eventId);

    final db = await _databaseService.database;
    
    // Get current profile
    var profile = await getUserProfile(userId, eventId);
    
    // Calculate new values
    final newTotalPoints = profile.totalPoints + points;
    final newExperiencePoints = profile.experiencePoints + points;
    
    // Check for level up
    int newLevel = profile.level;
    int newExperienceToNextLevel = profile.experienceToNextLevel;
    
    while (newLevel < levelRequirements.length - 1 && 
           newExperiencePoints >= levelRequirements[newLevel + 1]) {
      newLevel++;
    }
    
    if (newLevel < levelRequirements.length - 1) {
      newExperienceToNextLevel = levelRequirements[newLevel + 1] - newExperiencePoints;
    } else {
      newExperienceToNextLevel = 0;
    }

    // Update category points
    final categoryPoints = Map<String, int>.from(profile.categoryPoints);
    final category = _getActionCategory(actionType);
    categoryPoints[category] = (categoryPoints[category] ?? 0) + points;

    // Update daily progress
    final today = DateTime.now().toIso8601String().split('T')[0];
    final dailyProgress = Map<String, int>.from(profile.dailyProgress);
    dailyProgress[today] = (dailyProgress[today] ?? 0) + points;

    // Calculate streak
    int newStreak = profile.streak;
    final lastActiveDate = profile.lastActiveDate;
    final now = DateTime.now();
    
    if (lastActiveDate.day != now.day || lastActiveDate.month != now.month || lastActiveDate.year != now.year) {
      final daysDifference = now.difference(lastActiveDate).inDays;
      if (daysDifference == 1) {
        newStreak++;
      } else if (daysDifference > 1) {
        newStreak = 1;
      }
    }

    // Update profile
    profile = profile.copyWith(
      totalPoints: newTotalPoints,
      level: newLevel,
      experiencePoints: newExperiencePoints,
      experienceToNextLevel: newExperienceToNextLevel,
      categoryPoints: categoryPoints,
      dailyProgress: dailyProgress,
      lastActiveDate: now,
      streak: newStreak,
      title: _getTitleForLevel(newLevel),
    );

    // Save to database
    await db.update(
      'user_gamification_profiles',
      profile.toJson(),
      where: 'userId = ? AND eventId = ?',
      whereArgs: [userId, eventId],
    );

    // Record the action
    final action = GamificationAction(
      type: actionType,
      points: points,
      description: _getActionDescription(actionType, points),
      metadata: metadata ?? {},
      timestamp: now,
    );
    
    await _recordAction(userId, eventId, action);

    // Check for new achievements
    await _checkAllAchievements(userId, eventId, profile);
    
    // Check for challenge progress
    await _updateChallengeProgress(userId, eventId, actionType, metadata);

    // Check for level up achievement
    if (newLevel > profile.level) {
      await _checkAndUnlockAchievement(userId, eventId, 'level_up_${newLevel}');
    }

    // Check for streak achievements
    if (newStreak > profile.streak && newStreak % 5 == 0) {
      await _checkAndUnlockAchievement(userId, eventId, 'streak_${newStreak}');
    }

    return profile;
  }

  // Get user gamification profile
  Future<UserGamificationProfile> getUserProfile(String userId, String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'user_gamification_profiles',
      where: 'userId = ? AND eventId = ?',
      whereArgs: [userId, eventId],
    );

    if (maps.isNotEmpty) {
      return UserGamificationProfile.fromJson(maps.first);
    }

    // Initialize if doesn't exist
    return await initializeUserProfile(userId, eventId);
  }

  // Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(String eventId, {
    String category = 'overall',
    int limit = 50,
  }) async {
    final db = await _databaseService.database;
    
    String orderBy = 'totalPoints DESC';
    if (category != 'overall') {
      orderBy = 'JSON_EXTRACT(categoryPoints, "\$.$category") DESC';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT ugp.*, p.name as userName, p.profilePictureUrl as userAvatar
      FROM user_gamification_profiles ugp
      JOIN profiles p ON ugp.userId = p.userId
      WHERE ugp.eventId = ?
      ORDER BY $orderBy
      LIMIT ?
    ''', [eventId, limit]);

    return maps.asMap().entries.map((entry) {
      final index = entry.key;
      final map = entry.value;
      
      return LeaderboardEntry(
        userId: map['userId'],
        userName: map['userName'] ?? 'Unknown User',
        userAvatar: map['userAvatar'] ?? '',
        points: category == 'overall' 
            ? map['totalPoints'] 
            : (map['categoryPoints'] as Map<String, dynamic>?)?[category] ?? 0,
        level: map['level'],
        rank: index + 1,
        title: map['title'],
        badges: map['badges']?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
        categoryPoints: Map<String, int>.from(map['categoryPoints'] ?? {}),
      );
    }).toList();
  }

  // Get achievements for event
  Future<List<Achievement>> getEventAchievements(String eventId) async {
    return _generateAchievements(eventId);
  }

  // Get user achievements
  Future<List<Achievement>> getUserAchievements(String userId, String eventId) async {
    final profile = await getUserProfile(userId, eventId);
    final allAchievements = await getEventAchievements(eventId);
    
    // Update progress for each achievement
    final updatedAchievements = <Achievement>[];
    for (final achievement in allAchievements) {
      final progress = await _calculateAchievementProgress(userId, eventId, achievement);
      final isUnlocked = profile.unlockedAchievements.any((a) => a.id == achievement.id);
      
      updatedAchievements.add(achievement.copyWith(
        progress: progress,
        unlockedAt: isUnlocked 
            ? profile.unlockedAchievements.firstWhere((a) => a.id == achievement.id).unlockedAt
            : null,
      ));
    }
    
    return updatedAchievements;
  }

  // Get challenges for event
  Future<List<Challenge>> getEventChallenges(String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'challenges',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'endDate ASC',
    );

    final challenges = maps.map((map) => Challenge.fromJson(map)).toList();
    
    // Add default challenges if none exist
    if (challenges.isEmpty) {
      return await _generateDefaultChallenges(eventId);
    }
    
    return challenges;
  }

  // Join a challenge
  Future<bool> joinChallenge(String userId, String eventId, String challengeId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'challenges',
      where: 'id = ? AND eventId = ?',
      whereArgs: [challengeId, eventId],
    );

    if (maps.isEmpty) return false;
    
    final challenge = Challenge.fromJson(maps.first);
    if (challenge.participants.contains(userId)) return true;
    
    final updatedChallenge = challenge.copyWith(
      participants: [...challenge.participants, userId],
    );
    
    await db.update(
      'challenges',
      updatedChallenge.toJson(),
      where: 'id = ?',
      whereArgs: [challengeId],
    );
    
    return true;
  }

  // Private helper methods
  
  String _getActionCategory(String actionType) {
    if (actionType.contains('session')) return 'sessions';
    if (actionType.contains('photo')) return 'photos';
    if (actionType.contains('community')) return 'community';
    if (actionType.contains('poll')) return 'polls';
    if (actionType.contains('message') || actionType.contains('connection')) return 'networking';
    if (actionType.contains('profile')) return 'profile';
    return 'general';
  }

  String _getActionDescription(String actionType, int points) {
    switch (actionType) {
      case 'session_checkin':
        return 'Checked into a session (+$points pts)';
      case 'session_complete':
        return 'Completed a session (+$points pts)';
      case 'photo_upload':
        return 'Uploaded a photo (+$points pts)';
      case 'community_post':
        return 'Created a community post (+$points pts)';
      case 'connection_made':
        return 'Made a new connection (+$points pts)';
      case 'poll_participation':
        return 'Participated in a poll (+$points pts)';
      default:
        return 'Earned points (+$points pts)';
    }
  }

  String _getTitleForLevel(int level) {
    if (level >= 20) return 'Event Legend';
    if (level >= 15) return 'Event Master';
    if (level >= 10) return 'Super Attendee';
    if (level >= 7) return 'Active Participant';
    if (level >= 5) return 'Engaged Attendee';
    if (level >= 3) return 'Regular Attendee';
    return 'Newcomer';
  }

  Future<void> _recordAction(String userId, String eventId, GamificationAction action) async {
    final db = await _databaseService.database;
    await db.insert('gamification_actions', {
      'userId': userId,
      'eventId': eventId,
      ...action.toJson(),
    });
  }

  Future<void> _checkAllAchievements(String userId, String eventId, UserGamificationProfile profile) async {
    final achievements = await getEventAchievements(eventId);
    
    for (final achievement in achievements) {
      if (!profile.unlockedAchievements.any((a) => a.id == achievement.id)) {
        final progress = await _calculateAchievementProgress(userId, eventId, achievement);
        if (progress >= 1.0) {
          await _unlockAchievement(userId, eventId, achievement);
        }
      }
    }
  }

  Future<double> _calculateAchievementProgress(String userId, String eventId, Achievement achievement) async {
    final profile = await getUserProfile(userId, eventId);
    
    switch (achievement.id) {
      case 'first_session':
        return profile.categoryPoints['sessions'] != null && profile.categoryPoints['sessions']! > 0 ? 1.0 : 0.0;
      case 'social_butterfly':
        final connections = profile.categoryPoints['networking'] ?? 0;
        return (connections / 150).clamp(0.0, 1.0); // 150 points = 5 connections
      case 'photographer':
        final photos = profile.categoryPoints['photos'] ?? 0;
        return (photos / 75).clamp(0.0, 1.0); // 75 points = 5 photos
      case 'community_leader':
        final community = profile.categoryPoints['community'] ?? 0;
        return (community / 100).clamp(0.0, 1.0); // 100 points = 5 posts
      case 'poll_master':
        final polls = profile.categoryPoints['polls'] ?? 0;
        return (polls / 150).clamp(0.0, 1.0); // 150 points = 10 polls
      case 'level_5':
        return profile.level >= 5 ? 1.0 : (profile.level / 5).clamp(0.0, 1.0);
      case 'level_10':
        return profile.level >= 10 ? 1.0 : (profile.level / 10).clamp(0.0, 1.0);
      case 'streak_7':
        return profile.streak >= 7 ? 1.0 : (profile.streak / 7).clamp(0.0, 1.0);
      case 'point_collector':
        return profile.totalPoints >= 1000 ? 1.0 : (profile.totalPoints / 1000).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  Future<void> _checkAndUnlockAchievement(String userId, String eventId, String achievementId) async {
    final achievements = await getEventAchievements(eventId);
    final achievement = achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => achievements.first,
    );
    
    final progress = await _calculateAchievementProgress(userId, eventId, achievement);
    if (progress >= 1.0) {
      await _unlockAchievement(userId, eventId, achievement);
    }
  }

  Future<void> _unlockAchievement(String userId, String eventId, Achievement achievement) async {
    final db = await _databaseService.database;
    
    // Add achievement to user's unlocked achievements
    final profile = await getUserProfile(userId, eventId);
    final unlockedAchievement = achievement.copyWith(
      unlockedAt: DateTime.now(),
      progress: 1.0,
    );
    
    final updatedAchievements = [...profile.unlockedAchievements, unlockedAchievement];
    
    final updatedProfile = profile.copyWith(
      unlockedAchievements: updatedAchievements,
    );
    
    await db.update(
      'user_gamification_profiles',
      updatedProfile.toJson(),
      where: 'userId = ? AND eventId = ?',
      whereArgs: [userId, eventId],
    );
    
    // Award achievement points
    await awardPoints(userId, eventId, 'achievement_unlock', metadata: {
      'achievementId': achievement.id,
      'achievementTitle': achievement.title,
      'achievementPoints': achievement.points,
    });
  }

  Future<void> _updateChallengeProgress(
    String userId, 
    String eventId, 
    String actionType, 
    Map<String, dynamic>? metadata,
  ) async {
    final challenges = await getEventChallenges(eventId);
    final userChallenges = challenges.where((c) => 
      c.participants.contains(userId) && c.isActive
    ).toList();
    
    for (final challenge in userChallenges) {
      bool shouldUpdate = false;
      int increment = 0;
      
      switch (challenge.type) {
        case ChallengeType.attendance:
          if (actionType == 'session_checkin') {
            shouldUpdate = true;
            increment = 1;
          }
          break;
        case ChallengeType.networking:
          if (actionType == 'connection_made') {
            shouldUpdate = true;
            increment = 1;
          }
          break;
        case ChallengeType.photo:
          if (actionType == 'photo_upload') {
            shouldUpdate = true;
            increment = 1;
          }
          break;
        case ChallengeType.poll:
          if (actionType == 'poll_participation') {
            shouldUpdate = true;
            increment = 1;
          }
          break;
        case ChallengeType.community:
          if (actionType == 'community_post') {
            shouldUpdate = true;
            increment = 1;
          }
          break;
        default:
          break;
      }
      
      if (shouldUpdate) {
        final updatedChallenge = challenge.copyWith(
          currentValue: challenge.currentValue + increment,
          status: (challenge.currentValue + increment) >= challenge.targetValue 
              ? ChallengeStatus.completed 
              : challenge.status,
        );
        
        final db = await _databaseService.database;
        await db.update(
          'challenges',
          updatedChallenge.toJson(),
          where: 'id = ?',
          whereArgs: [challenge.id],
        );
        
        // Award points if challenge completed
        if (updatedChallenge.isCompleted && !challenge.isCompleted) {
          await awardPoints(userId, eventId, 'challenge_complete', metadata: {
            'challengeId': challenge.id,
            'challengeTitle': challenge.title,
          });
        }
      }
    }
  }

  List<Achievement> _generateAchievements(String eventId) {
    return [
      Achievement(
        id: 'welcome',
        title: 'Welcome Aboard!',
        description: 'Welcome to the event! Your journey begins here.',
        iconUrl: 'https://example.com/icons/welcome.png',
        type: AchievementType.milestone,
        rarity: AchievementRarity.common,
        points: 50,
        requirements: {'auto_unlock': true},
        eventId: eventId,
      ),
      Achievement(
        id: 'first_session',
        title: 'Session Starter',
        description: 'Attend your first session.',
        iconUrl: 'https://example.com/icons/session.png',
        type: AchievementType.attendance,
        rarity: AchievementRarity.common,
        points: 25,
        requirements: {'sessions': 1},
        eventId: eventId,
      ),
      Achievement(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description: 'Make 5 new connections.',
        iconUrl: 'https://example.com/icons/networking.png',
        type: AchievementType.networking,
        rarity: AchievementRarity.uncommon,
        points: 100,
        requirements: {'connections': 5},
        eventId: eventId,
      ),
      Achievement(
        id: 'photographer',
        title: 'Event Photographer',
        description: 'Upload 5 photos to the gallery.',
        iconUrl: 'https://example.com/icons/camera.png',
        type: AchievementType.social,
        rarity: AchievementRarity.uncommon,
        points: 75,
        requirements: {'photos': 5},
        eventId: eventId,
      ),
      Achievement(
        id: 'community_leader',
        title: 'Community Leader',
        description: 'Create 5 community posts.',
        iconUrl: 'https://example.com/icons/community.png',
        type: AchievementType.engagement,
        rarity: AchievementRarity.rare,
        points: 150,
        requirements: {'posts': 5},
        eventId: eventId,
      ),
      Achievement(
        id: 'poll_master',
        title: 'Poll Master',
        description: 'Participate in 10 polls.',
        iconUrl: 'https://example.com/icons/poll.png',
        type: AchievementType.participation,
        rarity: AchievementRarity.uncommon,
        points: 100,
        requirements: {'polls': 10},
        eventId: eventId,
      ),
      Achievement(
        id: 'level_5',
        title: 'Rising Star',
        description: 'Reach level 5.',
        iconUrl: 'https://example.com/icons/star.png',
        type: AchievementType.milestone,
        rarity: AchievementRarity.rare,
        points: 200,
        requirements: {'level': 5},
        eventId: eventId,
      ),
      Achievement(
        id: 'level_10',
        title: 'Event Veteran',
        description: 'Reach level 10.',
        iconUrl: 'https://example.com/icons/veteran.png',
        type: AchievementType.milestone,
        rarity: AchievementRarity.epic,
        points: 500,
        requirements: {'level': 10},
        eventId: eventId,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Streak Master',
        description: 'Maintain a 7-day activity streak.',
        iconUrl: 'https://example.com/icons/streak.png',
        type: AchievementType.milestone,
        rarity: AchievementRarity.rare,
        points: 300,
        requirements: {'streak': 7},
        eventId: eventId,
      ),
      Achievement(
        id: 'point_collector',
        title: 'Point Collector',
        description: 'Earn 1000 total points.',
        iconUrl: 'https://example.com/icons/trophy.png',
        type: AchievementType.milestone,
        rarity: AchievementRarity.epic,
        points: 250,
        requirements: {'points': 1000},
        eventId: eventId,
      ),
    ];
  }

  Future<List<Challenge>> _generateDefaultChallenges(String eventId) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    
    final challenges = [
      Challenge(
        id: 'daily_explorer',
        title: 'Daily Explorer',
        description: 'Check in to 3 sessions today.',
        iconUrl: 'https://example.com/icons/explore.png',
        type: ChallengeType.daily,
        status: ChallengeStatus.active,
        points: 100,
        targetValue: 3,
        startDate: now,
        endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
        requirements: {'type': 'session_checkin'},
        eventId: eventId,
      ),
      Challenge(
        id: 'networking_champion',
        title: 'Networking Champion',
        description: 'Make 10 new connections this week.',
        iconUrl: 'https://example.com/icons/network.png',
        type: ChallengeType.weekly,
        status: ChallengeStatus.active,
        points: 250,
        targetValue: 10,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        requirements: {'type': 'connection_made'},
        eventId: eventId,
        isTeamChallenge: true,
      ),
      Challenge(
        id: 'photo_marathon',
        title: 'Photo Marathon',
        description: 'Upload 20 photos during the event.',
        iconUrl: 'https://example.com/icons/photo_marathon.png',
        type: ChallengeType.photo,
        status: ChallengeStatus.active,
        points: 300,
        targetValue: 20,
        startDate: now,
        endDate: now.add(const Duration(days: 3)),
        requirements: {'type': 'photo_upload'},
        eventId: eventId,
      ),
      Challenge(
        id: 'poll_participant',
        title: 'Poll Participant',
        description: 'Participate in 15 polls.',
        iconUrl: 'https://example.com/icons/poll_challenge.png',
        type: ChallengeType.poll,
        status: ChallengeStatus.active,
        points: 200,
        targetValue: 15,
        startDate: now,
        endDate: now.add(const Duration(days: 3)),
        requirements: {'type': 'poll_participation'},
        eventId: eventId,
      ),
      Challenge(
        id: 'community_contributor',
        title: 'Community Contributor',
        description: 'Create 8 community posts.',
        iconUrl: 'https://example.com/icons/community_challenge.png',
        type: ChallengeType.community,
        status: ChallengeStatus.active,
        points: 400,
        targetValue: 8,
        startDate: now,
        endDate: now.add(const Duration(days: 3)),
        requirements: {'type': 'community_post'},
        eventId: eventId,
      ),
    ];

    // Save challenges to database
    for (final challenge in challenges) {
      await db.insert('challenges', challenge.toJson());
    }

    return challenges;
  }

  // Get user's recent activity
  Future<List<GamificationAction>> getUserRecentActivity(String userId, String eventId, {int limit = 20}) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'gamification_actions',
      where: 'userId = ? AND eventId = ?',
      whereArgs: [userId, eventId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => GamificationAction.fromJson(map)).toList();
  }
}