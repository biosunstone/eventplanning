import 'package:json_annotation/json_annotation.dart';

part 'sponsor.g.dart';

enum SponsorTier {
  platinum,
  gold,
  silver,
  bronze,
  startup,
  community,
}

enum SponsorType {
  corporate,
  startup,
  nonprofit,
  media,
  government,
  academic,
}

enum BoothType {
  virtual,
  physical,
  hybrid,
}

@JsonSerializable(explicitToJson: true)
class Sponsor {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final String logoUrl;
  final String bannerUrl;
  final String websiteUrl;
  final String? videoUrl;
  final SponsorTier tier;
  final SponsorType type;
  final List<String> tags;
  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> socialMedia;
  final List<String> representativeIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isFeatured;
  final int displayOrder;

  const Sponsor({
    required this.id,
    required this.eventId,
    required this.name,
    required this.description,
    required this.logoUrl,
    this.bannerUrl = '',
    this.websiteUrl = '',
    this.videoUrl,
    required this.tier,
    required this.type,
    this.tags = const [],
    this.contactInfo = const {},
    this.socialMedia = const {},
    this.representativeIds = const [],
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isFeatured = false,
    this.displayOrder = 0,
  });

  factory Sponsor.fromJson(Map<String, dynamic> json) => _$SponsorFromJson(json);
  Map<String, dynamic> toJson() => _$SponsorToJson(this);

  Sponsor copyWith({
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? websiteUrl,
    String? videoUrl,
    SponsorTier? tier,
    SponsorType? type,
    List<String>? tags,
    Map<String, dynamic>? contactInfo,
    Map<String, dynamic>? socialMedia,
    List<String>? representativeIds,
    DateTime? updatedAt,
    bool? isActive,
    bool? isFeatured,
    int? displayOrder,
  }) {
    return Sponsor(
      id: id,
      eventId: eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      tier: tier ?? this.tier,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      contactInfo: contactInfo ?? this.contactInfo,
      socialMedia: socialMedia ?? this.socialMedia,
      representativeIds: representativeIds ?? this.representativeIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  String get tierDisplayName {
    switch (tier) {
      case SponsorTier.platinum:
        return 'Platinum';
      case SponsorTier.gold:
        return 'Gold';
      case SponsorTier.silver:
        return 'Silver';
      case SponsorTier.bronze:
        return 'Bronze';
      case SponsorTier.startup:
        return 'Startup';
      case SponsorTier.community:
        return 'Community';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case SponsorType.corporate:
        return 'Corporate';
      case SponsorType.startup:
        return 'Startup';
      case SponsorType.nonprofit:
        return 'Nonprofit';
      case SponsorType.media:
        return 'Media';
      case SponsorType.government:
        return 'Government';
      case SponsorType.academic:
        return 'Academic';
    }
  }

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasWebsite => websiteUrl.isNotEmpty;
  bool get hasSocialMedia => socialMedia.isNotEmpty;
}

@JsonSerializable(explicitToJson: true)
class ExhibitorBooth {
  final String id;
  final String sponsorId;
  final String eventId;
  final String name;
  final String description;
  final BoothType type;
  final String? location; // For physical booths
  final String? virtualRoomUrl; // For virtual booths
  final Map<String, dynamic> resources; // Documents, videos, etc.
  final List<String> staffIds;
  final List<String> visitorIds;
  final Map<String, dynamic> analytics;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic> settings;

  const ExhibitorBooth({
    required this.id,
    required this.sponsorId,
    required this.eventId,
    required this.name,
    required this.description,
    required this.type,
    this.location,
    this.virtualRoomUrl,
    this.resources = const {},
    this.staffIds = const [],
    this.visitorIds = const [],
    this.analytics = const {},
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.settings = const {},
  });

  factory ExhibitorBooth.fromJson(Map<String, dynamic> json) => _$ExhibitorBoothFromJson(json);
  Map<String, dynamic> toJson() => _$ExhibitorBoothToJson(this);

  ExhibitorBooth copyWith({
    String? name,
    String? description,
    BoothType? type,
    String? location,
    String? virtualRoomUrl,
    Map<String, dynamic>? resources,
    List<String>? staffIds,
    List<String>? visitorIds,
    Map<String, dynamic>? analytics,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return ExhibitorBooth(
      id: id,
      sponsorId: sponsorId,
      eventId: eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      location: location ?? this.location,
      virtualRoomUrl: virtualRoomUrl ?? this.virtualRoomUrl,
      resources: resources ?? this.resources,
      staffIds: staffIds ?? this.staffIds,
      visitorIds: visitorIds ?? this.visitorIds,
      analytics: analytics ?? this.analytics,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case BoothType.virtual:
        return 'Virtual';
      case BoothType.physical:
        return 'Physical';
      case BoothType.hybrid:
        return 'Hybrid';
    }
  }

  bool get isVirtual => type == BoothType.virtual || type == BoothType.hybrid;
  bool get isPhysical => type == BoothType.physical || type == BoothType.hybrid;
  bool get hasResources => resources.isNotEmpty;
  int get totalVisitors => visitorIds.length;
  int get staffCount => staffIds.length;
}

@JsonSerializable(explicitToJson: true)
class SponsorLead {
  final String id;
  final String sponsorId;
  final String boothId;
  final String attendeeId;
  final String attendeeName;
  final String attendeeEmail;
  final String? attendeePhone;
  final String? attendeeCompany;
  final String? attendeePosition;
  final Map<String, dynamic> customFields;
  final String source; // 'booth_visit', 'business_card_scan', 'manual_entry'
  final String status; // 'new', 'contacted', 'qualified', 'converted'
  final String notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? lastContactedAt;
  final String? assignedToId;

  const SponsorLead({
    required this.id,
    required this.sponsorId,
    required this.boothId,
    required this.attendeeId,
    required this.attendeeName,
    required this.attendeeEmail,
    this.attendeePhone,
    this.attendeeCompany,
    this.attendeePosition,
    this.customFields = const {},
    required this.source,
    this.status = 'new',
    this.notes = '',
    this.tags = const [],
    required this.createdAt,
    this.lastContactedAt,
    this.assignedToId,
  });

  factory SponsorLead.fromJson(Map<String, dynamic> json) => _$SponsorLeadFromJson(json);
  Map<String, dynamic> toJson() => _$SponsorLeadToJson(this);

  SponsorLead copyWith({
    String? attendeeName,
    String? attendeeEmail,
    String? attendeePhone,
    String? attendeeCompany,
    String? attendeePosition,
    Map<String, dynamic>? customFields,
    String? status,
    String? notes,
    List<String>? tags,
    DateTime? lastContactedAt,
    String? assignedToId,
  }) {
    return SponsorLead(
      id: id,
      sponsorId: sponsorId,
      boothId: boothId,
      attendeeId: attendeeId,
      attendeeName: attendeeName ?? this.attendeeName,
      attendeeEmail: attendeeEmail ?? this.attendeeEmail,
      attendeePhone: attendeePhone ?? this.attendeePhone,
      attendeeCompany: attendeeCompany ?? this.attendeeCompany,
      attendeePosition: attendeePosition ?? this.attendeePosition,
      customFields: customFields ?? this.customFields,
      source: source,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      assignedToId: assignedToId ?? this.assignedToId,
    );
  }

  bool get isNew => status == 'new';
  bool get isContacted => status == 'contacted';
  bool get isQualified => status == 'qualified';
  bool get isConverted => status == 'converted';
  bool get hasPhone => attendeePhone != null && attendeePhone!.isNotEmpty;
  bool get hasCompany => attendeeCompany != null && attendeeCompany!.isNotEmpty;
  bool get isAssigned => assignedToId != null;
}

@JsonSerializable(explicitToJson: true)
class SponsorshipPackage {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final SponsorTier tier;
  final double price;
  final String currency;
  final List<String> benefits;
  final Map<String, dynamic> inclusions; // booth_space, speaking_slots, etc.
  final Map<String, dynamic> branding; // logo_placement, banner_locations, etc.
  final int maxSponsors;
  final int currentSponsors;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isVisible;

  const SponsorshipPackage({
    required this.id,
    required this.eventId,
    required this.name,
    required this.description,
    required this.tier,
    required this.price,
    this.currency = 'USD',
    this.benefits = const [],
    this.inclusions = const {},
    this.branding = const {},
    this.maxSponsors = 1,
    this.currentSponsors = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isVisible = true,
  });

  factory SponsorshipPackage.fromJson(Map<String, dynamic> json) => _$SponsorshipPackageFromJson(json);
  Map<String, dynamic> toJson() => _$SponsorshipPackageToJson(this);

  bool get isAvailable => isActive && currentSponsors < maxSponsors;
  bool get isSoldOut => currentSponsors >= maxSponsors;
  int get availableSpots => maxSponsors - currentSponsors;
}