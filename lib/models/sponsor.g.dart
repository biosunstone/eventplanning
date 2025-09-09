// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sponsor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sponsor _$SponsorFromJson(Map<String, dynamic> json) => Sponsor(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      logoUrl: json['logoUrl'] as String,
      bannerUrl: json['bannerUrl'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      tier: $enumDecode(_$SponsorTierEnumMap, json['tier']),
      type: $enumDecode(_$SponsorTypeEnumMap, json['type']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      contactInfo: json['contactInfo'] as Map<String, dynamic>? ?? const {},
      socialMedia: json['socialMedia'] as Map<String, dynamic>? ?? const {},
      representativeIds: (json['representativeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SponsorToJson(Sponsor instance) => <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'name': instance.name,
      'description': instance.description,
      'logoUrl': instance.logoUrl,
      'bannerUrl': instance.bannerUrl,
      'websiteUrl': instance.websiteUrl,
      'videoUrl': instance.videoUrl,
      'tier': _$SponsorTierEnumMap[instance.tier]!,
      'type': _$SponsorTypeEnumMap[instance.type]!,
      'tags': instance.tags,
      'contactInfo': instance.contactInfo,
      'socialMedia': instance.socialMedia,
      'representativeIds': instance.representativeIds,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'isFeatured': instance.isFeatured,
      'displayOrder': instance.displayOrder,
    };

const _$SponsorTierEnumMap = {
  SponsorTier.platinum: 'platinum',
  SponsorTier.gold: 'gold',
  SponsorTier.silver: 'silver',
  SponsorTier.bronze: 'bronze',
  SponsorTier.startup: 'startup',
  SponsorTier.community: 'community',
};

const _$SponsorTypeEnumMap = {
  SponsorType.corporate: 'corporate',
  SponsorType.startup: 'startup',
  SponsorType.nonprofit: 'nonprofit',
  SponsorType.media: 'media',
  SponsorType.government: 'government',
  SponsorType.academic: 'academic',
};

ExhibitorBooth _$ExhibitorBoothFromJson(Map<String, dynamic> json) =>
    ExhibitorBooth(
      id: json['id'] as String,
      sponsorId: json['sponsorId'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$BoothTypeEnumMap, json['type']),
      location: json['location'] as String?,
      virtualRoomUrl: json['virtualRoomUrl'] as String?,
      resources: json['resources'] as Map<String, dynamic>? ?? const {},
      staffIds: (json['staffIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      visitorIds: (json['visitorIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      analytics: json['analytics'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      settings: json['settings'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ExhibitorBoothToJson(ExhibitorBooth instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sponsorId': instance.sponsorId,
      'eventId': instance.eventId,
      'name': instance.name,
      'description': instance.description,
      'type': _$BoothTypeEnumMap[instance.type]!,
      'location': instance.location,
      'virtualRoomUrl': instance.virtualRoomUrl,
      'resources': instance.resources,
      'staffIds': instance.staffIds,
      'visitorIds': instance.visitorIds,
      'analytics': instance.analytics,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'settings': instance.settings,
    };

const _$BoothTypeEnumMap = {
  BoothType.virtual: 'virtual',
  BoothType.physical: 'physical',
  BoothType.hybrid: 'hybrid',
};

SponsorLead _$SponsorLeadFromJson(Map<String, dynamic> json) => SponsorLead(
      id: json['id'] as String,
      sponsorId: json['sponsorId'] as String,
      boothId: json['boothId'] as String,
      attendeeId: json['attendeeId'] as String,
      attendeeName: json['attendeeName'] as String,
      attendeeEmail: json['attendeeEmail'] as String,
      attendeePhone: json['attendeePhone'] as String?,
      attendeeCompany: json['attendeeCompany'] as String?,
      attendeePosition: json['attendeePosition'] as String?,
      customFields: json['customFields'] as Map<String, dynamic>? ?? const {},
      source: json['source'] as String,
      status: json['status'] as String? ?? 'new',
      notes: json['notes'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastContactedAt: json['lastContactedAt'] == null
          ? null
          : DateTime.parse(json['lastContactedAt'] as String),
      assignedToId: json['assignedToId'] as String?,
    );

Map<String, dynamic> _$SponsorLeadToJson(SponsorLead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sponsorId': instance.sponsorId,
      'boothId': instance.boothId,
      'attendeeId': instance.attendeeId,
      'attendeeName': instance.attendeeName,
      'attendeeEmail': instance.attendeeEmail,
      'attendeePhone': instance.attendeePhone,
      'attendeeCompany': instance.attendeeCompany,
      'attendeePosition': instance.attendeePosition,
      'customFields': instance.customFields,
      'source': instance.source,
      'status': instance.status,
      'notes': instance.notes,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastContactedAt': instance.lastContactedAt?.toIso8601String(),
      'assignedToId': instance.assignedToId,
    };

SponsorshipPackage _$SponsorshipPackageFromJson(Map<String, dynamic> json) =>
    SponsorshipPackage(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      tier: $enumDecode(_$SponsorTierEnumMap, json['tier']),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      inclusions: json['inclusions'] as Map<String, dynamic>? ?? const {},
      branding: json['branding'] as Map<String, dynamic>? ?? const {},
      maxSponsors: (json['maxSponsors'] as num?)?.toInt() ?? 1,
      currentSponsors: (json['currentSponsors'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isVisible: json['isVisible'] as bool? ?? true,
    );

Map<String, dynamic> _$SponsorshipPackageToJson(SponsorshipPackage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'name': instance.name,
      'description': instance.description,
      'tier': _$SponsorTierEnumMap[instance.tier]!,
      'price': instance.price,
      'currency': instance.currency,
      'benefits': instance.benefits,
      'inclusions': instance.inclusions,
      'branding': instance.branding,
      'maxSponsors': instance.maxSponsors,
      'currentSponsors': instance.currentSponsors,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'isVisible': instance.isVisible,
    };
