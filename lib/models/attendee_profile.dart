enum ProfessionalLevel {
  student,
  junior,
  mid,
  senior,
  executive,
  cLevel,
  founder,
}

class AttendeeProfile {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? company;
  final String? jobTitle;
  final String? department;
  final ProfessionalLevel? professionalLevel;
  final String? industry;
  final String? location;
  final String? city;
  final String? country;
  final String? bio;
  final List<String> interests;
  final List<String> skills;
  final String? linkedInUrl;
  final String? twitterHandle;
  final String? website;
  final bool isPublic;
  final bool allowNetworking;
  final bool allowMessages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendeeProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.profileImage,
    this.company,
    this.jobTitle,
    this.department,
    this.professionalLevel,
    this.industry,
    this.location,
    this.city,
    this.country,
    this.bio,
    this.interests = const [],
    this.skills = const [],
    this.linkedInUrl,
    this.twitterHandle,
    this.website,
    this.isPublic = true,
    this.allowNetworking = true,
    this.allowMessages = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory AttendeeProfile.fromJson(Map<String, dynamic> json) {
    return AttendeeProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profileImage'],
      company: json['company'],
      jobTitle: json['jobTitle'],
      department: json['department'],
      professionalLevel: json['professionalLevel'] != null
          ? ProfessionalLevel.values.firstWhere(
              (e) => e.toString() == 'ProfessionalLevel.${json['professionalLevel']}',
              orElse: () => ProfessionalLevel.mid,
            )
          : null,
      industry: json['industry'],
      location: json['location'],
      city: json['city'],
      country: json['country'],
      bio: json['bio'],
      interests: List<String>.from(json['interests'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      linkedInUrl: json['linkedInUrl'],
      twitterHandle: json['twitterHandle'],
      website: json['website'],
      isPublic: json['isPublic'] ?? true,
      allowNetworking: json['allowNetworking'] ?? true,
      allowMessages: json['allowMessages'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'company': company,
      'jobTitle': jobTitle,
      'department': department,
      'professionalLevel': professionalLevel?.toString().split('.').last,
      'industry': industry,
      'location': location,
      'city': city,
      'country': country,
      'bio': bio,
      'interests': interests,
      'skills': skills,
      'linkedInUrl': linkedInUrl,
      'twitterHandle': twitterHandle,
      'website': website,
      'isPublic': isPublic,
      'allowNetworking': allowNetworking,
      'allowMessages': allowMessages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AttendeeProfile copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImage,
    String? company,
    String? jobTitle,
    String? department,
    ProfessionalLevel? professionalLevel,
    String? industry,
    String? location,
    String? city,
    String? country,
    String? bio,
    List<String>? interests,
    List<String>? skills,
    String? linkedInUrl,
    String? twitterHandle,
    String? website,
    bool? isPublic,
    bool? allowNetworking,
    bool? allowMessages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendeeProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      professionalLevel: professionalLevel ?? this.professionalLevel,
      industry: industry ?? this.industry,
      location: location ?? this.location,
      city: city ?? this.city,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      skills: skills ?? this.skills,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      website: website ?? this.website,
      isPublic: isPublic ?? this.isPublic,
      allowNetworking: allowNetworking ?? this.allowNetworking,
      allowMessages: allowMessages ?? this.allowMessages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}