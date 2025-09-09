import '../models/attendee_profile.dart';

enum RecommendationType {
  sameCompany,
  sameIndustry,
  sameLocation,
  commonInterests,
  skillMatch,
  professionalLevel,
  previousConnections,
}

class NetworkingRecommendation {
  final String profileId;
  final RecommendationType type;
  final String reason;
  final double score;
  final List<String> commonAttributes;

  NetworkingRecommendation({
    required this.profileId,
    required this.type,
    required this.reason,
    required this.score,
    required this.commonAttributes,
  });
}

class NetworkingService {
  Future<List<NetworkingRecommendation>> getRecommendations(
    AttendeeProfile userProfile,
    List<AttendeeProfile> allProfiles,
  ) async {
    final recommendations = <NetworkingRecommendation>[];

    for (final profile in allProfiles) {
      if (profile.id == userProfile.id || !profile.allowNetworking) continue;

      final profileRecommendations = _analyzeProfile(userProfile, profile);
      recommendations.addAll(profileRecommendations);
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(50).toList();
  }

  List<NetworkingRecommendation> _analyzeProfile(
    AttendeeProfile userProfile,
    AttendeeProfile targetProfile,
  ) {
    final recommendations = <NetworkingRecommendation>[];

    _checkSameCompany(userProfile, targetProfile, recommendations);
    _checkSameIndustry(userProfile, targetProfile, recommendations);
    _checkSameLocation(userProfile, targetProfile, recommendations);
    _checkCommonInterests(userProfile, targetProfile, recommendations);
    _checkSkillMatch(userProfile, targetProfile, recommendations);
    _checkProfessionalLevel(userProfile, targetProfile, recommendations);

    return recommendations;
  }

  void _checkSameCompany(
    AttendeeProfile userProfile,
    AttendeeProfile targetProfile,
    List<NetworkingRecommendation> recommendations,
  ) {
    if (userProfile.company != null &&
        targetProfile.company != null &&
        userProfile.company == targetProfile.company) {
      recommendations.add(NetworkingRecommendation(
        profileId: targetProfile.id,
        type: RecommendationType.sameCompany,
        reason: 'Works at ${targetProfile.company}',
        score: 0.9,
        commonAttributes: [targetProfile.company!],
      ));
    }
  }

  void _checkSameIndustry(
    AttendeeProfile userProfile,
    AttendeeProfile targetProfile,
    List<NetworkingRecommendation> recommendations,
  ) {
    if (userProfile.industry != null &&
        targetProfile.industry != null &&
        userProfile.industry == targetProfile.industry) {
      recommendations.add(NetworkingRecommendation(
        profileId: targetProfile.id,
        type: RecommendationType.sameIndustry,
        reason: 'Works in ${targetProfile.industry}',
        score: 0.7,
        commonAttributes: [targetProfile.industry!],
      ));
    }
  }

  void _checkSameLocation(
    AttendeeProfile userProfile,
    AttendeeProfile targetProfile,
    List<NetworkingRecommendation> recommendations,
  ) {
    if (userProfile.city != null &&
        targetProfile.city != null &&
        userProfile.city == targetProfile.city) {
      recommendations.add(NetworkingRecommendation(
        profileId: targetProfile.id,
        type: RecommendationType.sameLocation,
        reason: 'From ${targetProfile.city}',
        score: 0.6,
        commonAttributes: [targetProfile.city!],
      ));
    }
  }

  void _checkCommonInterests(
    AttendeeProfile userProfile,
    AttendeeProfile targetProfile,
    List<NetworkingRecommendation> recommendations,
  ) {
    final commonInterests = userProfile.interests
        .where((interest) => targetProfile.interests.contains(interest))
        .toList();

    if (commonInterests.isNotEmpty) {
      final score = (commonInterests.length / userProfile.interests.length) * 0.8;
      recommendations.add(NetworkingRecommendation(
        profileId: targetProfile.id,
        type: RecommendationType.commonInterests,
        reason: 'Common interests: ${commonInterests.take(3).join(', ')}',
        score: score,
        commonAttributes: commonInterests,
      ));
    }
  }

  void _checkSkillMatch(
    AttendeeProfile userProfile,
    AttendeeProfile targetProfile,
    List<NetworkingRecommendation> recommendations,
  ) {
    final commonSkills = userProfile.skills
        .where((skill) => targetProfile.skills.contains(skill))
        .toList();

    if (commonSkills.isNotEmpty) {
      final score = (commonSkills.length / userProfile.skills.length) * 0.75;
      recommendations.add(NetworkingRecommendation(
        profileId: targetProfile.id,
        type: RecommendationType.skillMatch,
        reason: 'Common skills: ${commonSkills.take(3).join(', ')}',
        score: score,
        commonAttributes: commonSkills,
      ));
    }
  }

  void _checkProfessionalLevel(
    AttendeeProfile userProfile,
    AttendeeProfile targetProfile,
    List<NetworkingRecommendation> recommendations,
  ) {
    if (userProfile.professionalLevel != null &&
        targetProfile.professionalLevel != null) {
      final userLevel = _getProfessionalLevelValue(userProfile.professionalLevel!);
      final targetLevel = _getProfessionalLevelValue(targetProfile.professionalLevel!);

      if ((userLevel - targetLevel).abs() <= 1) {
        recommendations.add(NetworkingRecommendation(
          profileId: targetProfile.id,
          type: RecommendationType.professionalLevel,
          reason: 'Similar professional level',
          score: 0.5,
          commonAttributes: [targetProfile.professionalLevel!.toString().split('.').last],
        ));
      }
    }
  }

  int _getProfessionalLevelValue(ProfessionalLevel level) {
    switch (level) {
      case ProfessionalLevel.student:
        return 0;
      case ProfessionalLevel.junior:
        return 1;
      case ProfessionalLevel.mid:
        return 2;
      case ProfessionalLevel.senior:
        return 3;
      case ProfessionalLevel.executive:
        return 4;
      case ProfessionalLevel.cLevel:
        return 5;
      case ProfessionalLevel.founder:
        return 6;
    }
  }

  Future<List<AttendeeProfile>> searchProfiles({
    required String query,
    required List<AttendeeProfile> profiles,
    String? company,
    String? industry,
    String? location,
    List<String>? interests,
    List<String>? skills,
  }) async {
    return profiles.where((profile) {
      if (!profile.isPublic) return false;

      final searchTerms = query.toLowerCase().split(' ');
      final profileText = '${profile.fullName} ${profile.company ?? ''} '
          '${profile.jobTitle ?? ''} ${profile.bio ?? ''} '
          '${profile.interests.join(' ')} ${profile.skills.join(' ')}'
          .toLowerCase();

      final matchesQuery = searchTerms.every((term) => profileText.contains(term));

      final matchesCompany = company == null || profile.company == company;
      final matchesIndustry = industry == null || profile.industry == industry;
      final matchesLocation = location == null || profile.city == location || profile.country == location;
      final matchesInterests = interests == null || interests.any((interest) => profile.interests.contains(interest));
      final matchesSkills = skills == null || skills.any((skill) => profile.skills.contains(skill));

      return matchesQuery && matchesCompany && matchesIndustry && 
             matchesLocation && matchesInterests && matchesSkills;
    }).toList();
  }

  Future<Map<String, List<AttendeeProfile>>> groupProfilesByAttribute(
    List<AttendeeProfile> profiles,
    String attribute,
  ) async {
    final Map<String, List<AttendeeProfile>> groups = {};

    for (final profile in profiles) {
      String? key;
      
      switch (attribute) {
        case 'company':
          key = profile.company;
          break;
        case 'industry':
          key = profile.industry;
          break;
        case 'location':
          key = profile.city ?? profile.country;
          break;
        case 'professionalLevel':
          key = profile.professionalLevel?.toString().split('.').last;
          break;
      }

      if (key != null) {
        groups.putIfAbsent(key, () => []).add(profile);
      }
    }

    return groups;
  }

  Future<List<String>> getPopularInterests(List<AttendeeProfile> profiles) async {
    final interestCounts = <String, int>{};
    
    for (final profile in profiles) {
      for (final interest in profile.interests) {
        interestCounts[interest] = (interestCounts[interest] ?? 0) + 1;
      }
    }

    final sortedInterests = interestCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedInterests.take(20).map((e) => e.key).toList();
  }

  Future<List<String>> getPopularSkills(List<AttendeeProfile> profiles) async {
    final skillCounts = <String, int>{};
    
    for (final profile in profiles) {
      for (final skill in profile.skills) {
        skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
      }
    }

    final sortedSkills = skillCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSkills.take(20).map((e) => e.key).toList();
  }
}