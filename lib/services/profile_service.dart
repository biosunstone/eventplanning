import '../models/attendee_profile.dart';
import 'database_service.dart';

class ProfileService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<AttendeeProfile>> getAllProfiles() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendee_profiles',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      final profileData = maps[i];
      profileData['interests'] = (profileData['interests'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      profileData['skills'] = (profileData['skills'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      profileData['isPublic'] = profileData['isPublic'] == 1;
      profileData['allowNetworking'] = profileData['allowNetworking'] == 1;
      profileData['allowMessages'] = profileData['allowMessages'] == 1;
      
      return AttendeeProfile.fromJson(profileData);
    });
  }

  Future<AttendeeProfile?> getProfileByUserId(String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendee_profiles',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final profileData = maps.first;
      profileData['interests'] = (profileData['interests'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      profileData['skills'] = (profileData['skills'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      profileData['isPublic'] = profileData['isPublic'] == 1;
      profileData['allowNetworking'] = profileData['allowNetworking'] == 1;
      profileData['allowMessages'] = profileData['allowMessages'] == 1;
      
      return AttendeeProfile.fromJson(profileData);
    }
    return null;
  }

  Future<AttendeeProfile?> getProfileById(String profileId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendee_profiles',
      where: 'id = ?',
      whereArgs: [profileId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final profileData = maps.first;
      profileData['interests'] = (profileData['interests'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      profileData['skills'] = (profileData['skills'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      profileData['isPublic'] = profileData['isPublic'] == 1;
      profileData['allowNetworking'] = profileData['allowNetworking'] == 1;
      profileData['allowMessages'] = profileData['allowMessages'] == 1;
      
      return AttendeeProfile.fromJson(profileData);
    }
    return null;
  }

  Future<AttendeeProfile> createProfile(AttendeeProfile profile) async {
    final db = await _databaseService.database;
    
    final profileData = profile.toJson();
    profileData['interests'] = profile.interests.join(',');
    profileData['skills'] = profile.skills.join(',');
    profileData['isPublic'] = profile.isPublic ? 1 : 0;
    profileData['allowNetworking'] = profile.allowNetworking ? 1 : 0;
    profileData['allowMessages'] = profile.allowMessages ? 1 : 0;

    await db.insert('attendee_profiles', profileData);
    return profile;
  }

  Future<AttendeeProfile> updateProfile(AttendeeProfile profile) async {
    final db = await _databaseService.database;
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    
    final profileData = updatedProfile.toJson();
    profileData['interests'] = updatedProfile.interests.join(',');
    profileData['skills'] = updatedProfile.skills.join(',');
    profileData['isPublic'] = updatedProfile.isPublic ? 1 : 0;
    profileData['allowNetworking'] = updatedProfile.allowNetworking ? 1 : 0;
    profileData['allowMessages'] = updatedProfile.allowMessages ? 1 : 0;

    await db.update(
      'attendee_profiles',
      profileData,
      where: 'id = ?',
      whereArgs: [profile.id],
    );
    
    return updatedProfile;
  }

  Future<void> deleteProfile(String profileId) async {
    final db = await _databaseService.database;
    await db.delete(
      'attendee_profiles',
      where: 'id = ?',
      whereArgs: [profileId],
    );
  }

  Future<List<AttendeeProfile>> getPublicProfiles() async {
    final profiles = await getAllProfiles();
    return profiles.where((profile) => profile.isPublic).toList();
  }

  Future<List<AttendeeProfile>> getNetworkingEnabledProfiles() async {
    final profiles = await getAllProfiles();
    return profiles.where((profile) => profile.isPublic && profile.allowNetworking).toList();
  }

  Future<List<AttendeeProfile>> searchProfiles({
    required String query,
    String? company,
    String? industry,
    String? city,
    String? country,
    ProfessionalLevel? professionalLevel,
    List<String>? interests,
    List<String>? skills,
  }) async {
    final allProfiles = await getPublicProfiles();
    
    return allProfiles.where((profile) {
      final searchTerms = query.toLowerCase().split(' ');
      final profileText = '${profile.fullName} ${profile.company ?? ''} '
          '${profile.jobTitle ?? ''} ${profile.bio ?? ''} '
          '${profile.interests.join(' ')} ${profile.skills.join(' ')}'
          .toLowerCase();

      final matchesQuery = query.isEmpty || searchTerms.every((term) => profileText.contains(term));
      final matchesCompany = company == null || profile.company?.toLowerCase().contains(company.toLowerCase()) == true;
      final matchesIndustry = industry == null || profile.industry?.toLowerCase().contains(industry.toLowerCase()) == true;
      final matchesCity = city == null || profile.city?.toLowerCase().contains(city.toLowerCase()) == true;
      final matchesCountry = country == null || profile.country?.toLowerCase().contains(country.toLowerCase()) == true;
      final matchesLevel = professionalLevel == null || profile.professionalLevel == professionalLevel;
      final matchesInterests = interests == null || interests.any((interest) => profile.interests.contains(interest));
      final matchesSkills = skills == null || skills.any((skill) => profile.skills.contains(skill));

      return matchesQuery && matchesCompany && matchesIndustry && 
             matchesCity && matchesCountry && matchesLevel &&
             matchesInterests && matchesSkills;
    }).toList();
  }

  Future<List<AttendeeProfile>> getProfilesByCompany(String company) async {
    final profiles = await getPublicProfiles();
    return profiles.where((profile) => 
      profile.company?.toLowerCase() == company.toLowerCase()
    ).toList();
  }

  Future<List<AttendeeProfile>> getProfilesByIndustry(String industry) async {
    final profiles = await getPublicProfiles();
    return profiles.where((profile) => 
      profile.industry?.toLowerCase() == industry.toLowerCase()
    ).toList();
  }

  Future<List<AttendeeProfile>> getProfilesByLocation(String location) async {
    final profiles = await getPublicProfiles();
    return profiles.where((profile) => 
      profile.city?.toLowerCase() == location.toLowerCase() ||
      profile.country?.toLowerCase() == location.toLowerCase()
    ).toList();
  }

  Future<List<AttendeeProfile>> getProfilesWithInterest(String interest) async {
    final profiles = await getPublicProfiles();
    return profiles.where((profile) => 
      profile.interests.any((i) => i.toLowerCase() == interest.toLowerCase())
    ).toList();
  }

  Future<List<AttendeeProfile>> getProfilesWithSkill(String skill) async {
    final profiles = await getPublicProfiles();
    return profiles.where((profile) => 
      profile.skills.any((s) => s.toLowerCase() == skill.toLowerCase())
    ).toList();
  }

  Future<Map<String, int>> getCompanyDistribution() async {
    final profiles = await getPublicProfiles();
    final Map<String, int> distribution = {};
    
    for (final profile in profiles) {
      if (profile.company != null && profile.company!.isNotEmpty) {
        distribution[profile.company!] = (distribution[profile.company!] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  Future<Map<String, int>> getIndustryDistribution() async {
    final profiles = await getPublicProfiles();
    final Map<String, int> distribution = {};
    
    for (final profile in profiles) {
      if (profile.industry != null && profile.industry!.isNotEmpty) {
        distribution[profile.industry!] = (distribution[profile.industry!] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  Future<Map<String, int>> getLocationDistribution() async {
    final profiles = await getPublicProfiles();
    final Map<String, int> distribution = {};
    
    for (final profile in profiles) {
      final location = profile.city ?? profile.country;
      if (location != null && location.isNotEmpty) {
        distribution[location] = (distribution[location] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  Future<Map<ProfessionalLevel, int>> getProfessionalLevelDistribution() async {
    final profiles = await getPublicProfiles();
    final Map<ProfessionalLevel, int> distribution = {};
    
    for (final profile in profiles) {
      if (profile.professionalLevel != null) {
        distribution[profile.professionalLevel!] = (distribution[profile.professionalLevel!] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  Future<List<String>> getPopularInterests({int limit = 20}) async {
    final profiles = await getPublicProfiles();
    final Map<String, int> interestCounts = {};
    
    for (final profile in profiles) {
      for (final interest in profile.interests) {
        interestCounts[interest] = (interestCounts[interest] ?? 0) + 1;
      }
    }
    
    final sortedInterests = interestCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedInterests.take(limit).map((e) => e.key).toList();
  }

  Future<List<String>> getPopularSkills({int limit = 20}) async {
    final profiles = await getPublicProfiles();
    final Map<String, int> skillCounts = {};
    
    for (final profile in profiles) {
      for (final skill in profile.skills) {
        skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
      }
    }
    
    final sortedSkills = skillCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedSkills.take(limit).map((e) => e.key).toList();
  }

  Future<Map<String, dynamic>> getProfileStats() async {
    final profiles = await getAllProfiles();
    final publicProfiles = profiles.where((p) => p.isPublic).length;
    final networkingEnabled = profiles.where((p) => p.allowNetworking).length;
    final messagingEnabled = profiles.where((p) => p.allowMessages).length;
    
    // Calculate completeness scores
    int totalCompleteness = 0;
    for (final profile in profiles) {
      totalCompleteness += _calculateProfileCompleteness(profile);
    }
    final avgCompleteness = profiles.isEmpty ? 0 : totalCompleteness ~/ profiles.length;
    
    return {
      'totalProfiles': profiles.length,
      'publicProfiles': publicProfiles,
      'networkingEnabled': networkingEnabled,
      'messagingEnabled': messagingEnabled,
      'averageCompleteness': avgCompleteness,
      'withProfileImage': profiles.where((p) => p.profileImage != null).length,
      'withBio': profiles.where((p) => p.bio != null && p.bio!.isNotEmpty).length,
      'withCompany': profiles.where((p) => p.company != null && p.company!.isNotEmpty).length,
      'withInterests': profiles.where((p) => p.interests.isNotEmpty).length,
      'withSkills': profiles.where((p) => p.skills.isNotEmpty).length,
    };
  }

  int _calculateProfileCompleteness(AttendeeProfile profile) {
    int score = 0;
    const int maxScore = 100;
    
    // Basic info (40%)
    if (profile.firstName.isNotEmpty) score += 10;
    if (profile.lastName.isNotEmpty) score += 10;
    if (profile.email.isNotEmpty) score += 10;
    if (profile.bio != null && profile.bio!.isNotEmpty) score += 10;
    
    // Professional info (30%)
    if (profile.company != null && profile.company!.isNotEmpty) score += 10;
    if (profile.jobTitle != null && profile.jobTitle!.isNotEmpty) score += 10;
    if (profile.industry != null && profile.industry!.isNotEmpty) score += 10;
    
    // Personal info (20%)
    if (profile.profileImage != null) score += 10;
    if (profile.city != null && profile.city!.isNotEmpty) score += 10;
    
    // Networking info (10%)
    if (profile.interests.isNotEmpty) score += 5;
    if (profile.skills.isNotEmpty) score += 5;
    
    return score;
  }

  Future<bool> isProfileComplete(String userId) async {
    final profile = await getProfileByUserId(userId);
    if (profile == null) return false;
    
    final completeness = _calculateProfileCompleteness(profile);
    return completeness >= 70; // Consider 70% as complete
  }

  Future<List<String>> getProfileCompletionSuggestions(String userId) async {
    final profile = await getProfileByUserId(userId);
    if (profile == null) return ['Create a profile'];
    
    final suggestions = <String>[];
    
    if (profile.profileImage == null) {
      suggestions.add('Add a profile photo');
    }
    if (profile.bio == null || profile.bio!.isEmpty) {
      suggestions.add('Write a bio');
    }
    if (profile.company == null || profile.company!.isEmpty) {
      suggestions.add('Add your company');
    }
    if (profile.jobTitle == null || profile.jobTitle!.isEmpty) {
      suggestions.add('Add your job title');
    }
    if (profile.industry == null || profile.industry!.isEmpty) {
      suggestions.add('Specify your industry');
    }
    if (profile.city == null || profile.city!.isEmpty) {
      suggestions.add('Add your location');
    }
    if (profile.interests.isEmpty) {
      suggestions.add('Add your interests');
    }
    if (profile.skills.isEmpty) {
      suggestions.add('List your skills');
    }
    if (profile.linkedInUrl == null || profile.linkedInUrl!.isEmpty) {
      suggestions.add('Connect your LinkedIn');
    }
    
    return suggestions;
  }
}