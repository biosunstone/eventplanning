enum AchievementType {
  attendance,
  networking,
  engagement,
  social,
  learning,
  participation,
  milestone,
  special,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

enum ChallengeType {
  attendance,
  networking,
  photo,
  poll,
  session,
  community,
  daily,
  weekly,
  special,
}

enum ChallengeStatus {
  active,
  completed,
  expired,
  locked,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final AchievementType type;
  final AchievementRarity rarity;
  final int points;
  final Map<String, dynamic> requirements;
  final bool isSecret;
  final DateTime? unlockedAt;
  final double progress;
  final String eventId;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.rarity,
    required this.points,
    required this.requirements,
    this.isSecret = false,
    this.unlockedAt,
    this.progress = 0.0,
    required this.eventId,
  });

  bool get isUnlocked => unlockedAt != null;
  bool get isCompleted => progress >= 1.0;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconUrl,
    AchievementType? type,
    AchievementRarity? rarity,
    int? points,
    Map<String, dynamic>? requirements,
    bool? isSecret,
    DateTime? unlockedAt,
    double? progress,
    String? eventId,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      points: points ?? this.points,
      requirements: requirements ?? this.requirements,
      isSecret: isSecret ?? this.isSecret,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      eventId: eventId ?? this.eventId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'type': type.name,
      'rarity': rarity.name,
      'points': points,
      'requirements': requirements.toString(),
      'isSecret': isSecret,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
      'eventId': eventId,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      type: AchievementType.values.firstWhere((e) => e.name == json['type']),
      rarity: AchievementRarity.values.firstWhere((e) => e.name == json['rarity']),
      points: json['points'] as int,
      requirements: Map<String, dynamic>.from(json['requirements']),
      isSecret: json['isSecret'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      eventId: json['eventId'] as String,
    );
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final ChallengeType type;
  final ChallengeStatus status;
  final int points;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> requirements;
  final List<String> participants;
  final String eventId;
  final bool isTeamChallenge;
  final List<String> rewards;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.status,
    required this.points,
    required this.targetValue,
    this.currentValue = 0,
    required this.startDate,
    required this.endDate,
    required this.requirements,
    this.participants = const [],
    required this.eventId,
    this.isTeamChallenge = false,
    this.rewards = const [],
  });

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentValue >= targetValue;
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActive => DateTime.now().isBefore(endDate) && DateTime.now().isAfter(startDate);
  Duration get timeRemaining => endDate.difference(DateTime.now());

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    String? iconUrl,
    ChallengeType? type,
    ChallengeStatus? status,
    int? points,
    int? targetValue,
    int? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? requirements,
    List<String>? participants,
    String? eventId,
    bool? isTeamChallenge,
    List<String>? rewards,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      points: points ?? this.points,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      requirements: requirements ?? this.requirements,
      participants: participants ?? this.participants,
      eventId: eventId ?? this.eventId,
      isTeamChallenge: isTeamChallenge ?? this.isTeamChallenge,
      rewards: rewards ?? this.rewards,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'type': type.name,
      'status': status.name,
      'points': points,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'requirements': requirements.toString(),
      'participants': participants.join(','),
      'eventId': eventId,
      'isTeamChallenge': isTeamChallenge,
      'rewards': rewards.join(','),
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      type: ChallengeType.values.firstWhere((e) => e.name == json['type']),
      status: ChallengeStatus.values.firstWhere((e) => e.name == json['status']),
      points: json['points'] as int,
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      requirements: Map<String, dynamic>.from(json['requirements']),
      participants: json['participants'] != null 
          ? (json['participants'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      eventId: json['eventId'] as String,
      isTeamChallenge: json['isTeamChallenge'] as bool? ?? false,
      rewards: json['rewards'] != null
          ? (json['rewards'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
    );
  }
}

class UserGamificationProfile {
  final String userId;
  final String eventId;
  final int totalPoints;
  final int level;
  final int experiencePoints;
  final int experienceToNextLevel;
  final List<Achievement> unlockedAchievements;
  final List<Challenge> activeChallenges;
  final List<Challenge> completedChallenges;
  final Map<String, int> dailyProgress;
  final Map<String, int> categoryPoints;
  final DateTime lastActiveDate;
  final int streak;
  final String title;
  final List<String> badges;

  UserGamificationProfile({
    required this.userId,
    required this.eventId,
    this.totalPoints = 0,
    this.level = 1,
    this.experiencePoints = 0,
    this.experienceToNextLevel = 100,
    this.unlockedAchievements = const [],
    this.activeChallenges = const [],
    this.completedChallenges = const [],
    this.dailyProgress = const {},
    this.categoryPoints = const {},
    required this.lastActiveDate,
    this.streak = 0,
    this.title = 'Newcomer',
    this.badges = const [],
  });

  double get levelProgress => experienceToNextLevel > 0 ? (experiencePoints / experienceToNextLevel).clamp(0.0, 1.0) : 0.0;
  int get totalAchievements => unlockedAchievements.length;
  int get totalChallenges => completedChallenges.length;

  UserGamificationProfile copyWith({
    String? userId,
    String? eventId,
    int? totalPoints,
    int? level,
    int? experiencePoints,
    int? experienceToNextLevel,
    List<Achievement>? unlockedAchievements,
    List<Challenge>? activeChallenges,
    List<Challenge>? completedChallenges,
    Map<String, int>? dailyProgress,
    Map<String, int>? categoryPoints,
    DateTime? lastActiveDate,
    int? streak,
    String? title,
    List<String>? badges,
  }) {
    return UserGamificationProfile(
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      experienceToNextLevel: experienceToNextLevel ?? this.experienceToNextLevel,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      categoryPoints: categoryPoints ?? this.categoryPoints,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streak: streak ?? this.streak,
      title: title ?? this.title,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'eventId': eventId,
      'totalPoints': totalPoints,
      'level': level,
      'experiencePoints': experiencePoints,
      'experienceToNextLevel': experienceToNextLevel,
      'unlockedAchievements': unlockedAchievements.map((a) => a.toJson()).toList(),
      'activeChallenges': activeChallenges.map((c) => c.toJson()).toList(),
      'completedChallenges': completedChallenges.map((c) => c.toJson()).toList(),
      'dailyProgress': dailyProgress,
      'categoryPoints': categoryPoints,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'streak': streak,
      'title': title,
      'badges': badges.join(','),
    };
  }

  factory UserGamificationProfile.fromJson(Map<String, dynamic> json) {
    return UserGamificationProfile(
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      experiencePoints: json['experiencePoints'] as int? ?? 0,
      experienceToNextLevel: json['experienceToNextLevel'] as int? ?? 100,
      unlockedAchievements: (json['unlockedAchievements'] as List?)
          ?.map((a) => Achievement.fromJson(a))
          .toList() ?? [],
      activeChallenges: (json['activeChallenges'] as List?)
          ?.map((c) => Challenge.fromJson(c))
          .toList() ?? [],
      completedChallenges: (json['completedChallenges'] as List?)
          ?.map((c) => Challenge.fromJson(c))
          .toList() ?? [],
      dailyProgress: Map<String, int>.from(json['dailyProgress'] ?? {}),
      categoryPoints: Map<String, int>.from(json['categoryPoints'] ?? {}),
      lastActiveDate: DateTime.parse(json['lastActiveDate']),
      streak: json['streak'] as int? ?? 0,
      title: json['title'] as String? ?? 'Newcomer',
      badges: json['badges'] != null
          ? (json['badges'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String userAvatar;
  final int points;
  final int level;
  final int rank;
  final String title;
  final List<String> badges;
  final Map<String, int> categoryPoints;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.points,
    required this.level,
    required this.rank,
    required this.title,
    this.badges = const [],
    this.categoryPoints = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'points': points,
      'level': level,
      'rank': rank,
      'title': title,
      'badges': badges.join(','),
      'categoryPoints': categoryPoints,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      points: json['points'] as int,
      level: json['level'] as int,
      rank: json['rank'] as int,
      title: json['title'] as String,
      badges: json['badges'] != null
          ? (json['badges'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      categoryPoints: Map<String, int>.from(json['categoryPoints'] ?? {}),
    );
  }
}

class GamificationAction {
  final String type;
  final int points;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  GamificationAction({
    required this.type,
    required this.points,
    required this.description,
    this.metadata = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'points': points,
      'description': description,
      'metadata': metadata.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GamificationAction.fromJson(Map<String, dynamic> json) {
    return GamificationAction(
      type: json['type'] as String,
      points: json['points'] as int,
      description: json['description'] as String,
      metadata: Map<String, dynamic>.from(json['metadata']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}