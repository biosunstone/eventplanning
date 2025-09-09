import '../models/sponsor.dart';
import 'database_service.dart';

class SponsorService {
  final DatabaseService _databaseService = DatabaseService();

  // Sponsor Management
  Future<List<Sponsor>> getEventSponsors(String eventId, {SponsorTier? tier}) async {
    final db = await _databaseService.database;
    
    String whereClause = 'eventId = ? AND isActive = 1';
    List<dynamic> whereArgs = [eventId];
    
    if (tier != null) {
      whereClause += ' AND tier = ?';
      whereArgs.add(tier.name);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'sponsors',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'displayOrder ASC, tier ASC, name ASC',
    );

    return maps.map((map) => Sponsor.fromJson(map)).toList();
  }

  Future<Sponsor?> getSponsor(String sponsorId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sponsors',
      where: 'id = ?',
      whereArgs: [sponsorId],
    );

    return maps.isNotEmpty ? Sponsor.fromJson(maps.first) : null;
  }

  Future<List<Sponsor>> getFeaturedSponsors(String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sponsors',
      where: 'eventId = ? AND isActive = 1 AND isFeatured = 1',
      whereArgs: [eventId],
      orderBy: 'tier ASC, displayOrder ASC',
    );

    return maps.map((map) => Sponsor.fromJson(map)).toList();
  }

  Future<List<Sponsor>> getSponsorsByTier(String eventId, SponsorTier tier) async {
    return await getEventSponsors(eventId, tier: tier);
  }

  Future<Sponsor> createSponsor(Sponsor sponsor) async {
    final db = await _databaseService.database;
    await db.insert('sponsors', sponsor.toJson());
    return sponsor;
  }

  Future<void> updateSponsor(Sponsor sponsor) async {
    final db = await _databaseService.database;
    await db.update(
      'sponsors',
      sponsor.toJson(),
      where: 'id = ?',
      whereArgs: [sponsor.id],
    );
  }

  Future<void> deleteSponsor(String sponsorId) async {
    final db = await _databaseService.database;
    
    // Delete related data
    await Future.wait([
      db.delete('exhibitor_booths', where: 'sponsorId = ?', whereArgs: [sponsorId]),
      db.delete('sponsor_leads', where: 'sponsorId = ?', whereArgs: [sponsorId]),
    ]);
    
    // Delete sponsor
    await db.delete('sponsors', where: 'id = ?', whereArgs: [sponsorId]);
  }

  // Exhibitor Booth Management
  Future<List<ExhibitorBooth>> getEventBooths(String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'exhibitor_booths',
      where: 'eventId = ? AND isActive = 1',
      whereArgs: [eventId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => ExhibitorBooth.fromJson(map)).toList();
  }

  Future<ExhibitorBooth?> getBooth(String boothId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'exhibitor_booths',
      where: 'id = ?',
      whereArgs: [boothId],
    );

    return maps.isNotEmpty ? ExhibitorBooth.fromJson(maps.first) : null;
  }

  Future<List<ExhibitorBooth>> getSponsorBooths(String sponsorId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'exhibitor_booths',
      where: 'sponsorId = ? AND isActive = 1',
      whereArgs: [sponsorId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => ExhibitorBooth.fromJson(map)).toList();
  }

  Future<List<ExhibitorBooth>> getBoothsByType(String eventId, BoothType type) async {
    final booths = await getEventBooths(eventId);
    return booths.where((booth) => booth.type == type).toList();
  }

  Future<ExhibitorBooth> createBooth(ExhibitorBooth booth) async {
    final db = await _databaseService.database;
    await db.insert('exhibitor_booths', booth.toJson());
    return booth;
  }

  Future<void> updateBooth(ExhibitorBooth booth) async {
    final db = await _databaseService.database;
    await db.update(
      'exhibitor_booths',
      booth.toJson(),
      where: 'id = ?',
      whereArgs: [booth.id],
    );
  }

  Future<void> deleteBooth(String boothId) async {
    final db = await _databaseService.database;
    
    // Delete related leads
    await db.delete('sponsor_leads', where: 'boothId = ?', whereArgs: [boothId]);
    
    // Delete booth
    await db.delete('exhibitor_booths', where: 'id = ?', whereArgs: [boothId]);
  }

  Future<void> visitBooth(String boothId, String userId) async {
    final booth = await getBooth(boothId);
    if (booth != null && !booth.visitorIds.contains(userId)) {
      final updatedBooth = booth.copyWith(
        visitorIds: [...booth.visitorIds, userId],
        analytics: {
          ...booth.analytics,
          'totalVisits': (booth.analytics['totalVisits'] ?? 0) + 1,
          'lastVisit': DateTime.now().toIso8601String(),
        },
      );
      await updateBooth(updatedBooth);
    }
  }

  // Lead Management
  Future<List<SponsorLead>> getSponsorLeads(String sponsorId, {String? status}) async {
    final db = await _databaseService.database;
    
    String whereClause = 'sponsorId = ?';
    List<dynamic> whereArgs = [sponsorId];
    
    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'sponsor_leads',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => SponsorLead.fromJson(map)).toList();
  }

  Future<List<SponsorLead>> getBoothLeads(String boothId, {String? status}) async {
    final db = await _databaseService.database;
    
    String whereClause = 'boothId = ?';
    List<dynamic> whereArgs = [boothId];
    
    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'sponsor_leads',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => SponsorLead.fromJson(map)).toList();
  }

  Future<SponsorLead?> getLead(String leadId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sponsor_leads',
      where: 'id = ?',
      whereArgs: [leadId],
    );

    return maps.isNotEmpty ? SponsorLead.fromJson(maps.first) : null;
  }

  Future<SponsorLead> createLead(SponsorLead lead) async {
    final db = await _databaseService.database;
    await db.insert('sponsor_leads', lead.toJson());
    return lead;
  }

  Future<void> updateLead(SponsorLead lead) async {
    final db = await _databaseService.database;
    await db.update(
      'sponsor_leads',
      lead.toJson(),
      where: 'id = ?',
      whereArgs: [lead.id],
    );
  }

  Future<void> updateLeadStatus(String leadId, String status) async {
    final lead = await getLead(leadId);
    if (lead != null) {
      final updatedLead = lead.copyWith(
        status: status,
        lastContactedAt: status != 'new' ? DateTime.now() : null,
      );
      await updateLead(updatedLead);
    }
  }

  Future<void> assignLead(String leadId, String assignedToId) async {
    final lead = await getLead(leadId);
    if (lead != null) {
      final updatedLead = lead.copyWith(assignedToId: assignedToId);
      await updateLead(updatedLead);
    }
  }

  Future<void> deleteLead(String leadId) async {
    final db = await _databaseService.database;
    await db.delete('sponsor_leads', where: 'id = ?', whereArgs: [leadId]);
  }

  // Sponsorship Package Management
  Future<List<SponsorshipPackage>> getEventPackages(String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sponsorship_packages',
      where: 'eventId = ? AND isActive = 1',
      whereArgs: [eventId],
      orderBy: 'tier ASC, price DESC',
    );

    return maps.map((map) => SponsorshipPackage.fromJson(map)).toList();
  }

  Future<List<SponsorshipPackage>> getAvailablePackages(String eventId) async {
    final packages = await getEventPackages(eventId);
    return packages.where((package) => package.isAvailable && package.isVisible).toList();
  }

  Future<SponsorshipPackage?> getPackage(String packageId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sponsorship_packages',
      where: 'id = ?',
      whereArgs: [packageId],
    );

    return maps.isNotEmpty ? SponsorshipPackage.fromJson(maps.first) : null;
  }

  Future<SponsorshipPackage> createPackage(SponsorshipPackage package) async {
    final db = await _databaseService.database;
    await db.insert('sponsorship_packages', package.toJson());
    return package;
  }

  Future<void> updatePackage(SponsorshipPackage package) async {
    final db = await _databaseService.database;
    await db.update(
      'sponsorship_packages',
      package.toJson(),
      where: 'id = ?',
      whereArgs: [package.id],
    );
  }

  // Analytics & Reporting
  Future<Map<String, dynamic>> getSponsorAnalytics(String sponsorId) async {
    final sponsor = await getSponsor(sponsorId);
    final booths = await getSponsorBooths(sponsorId);
    final leads = await getSponsorLeads(sponsorId);
    
    if (sponsor == null) return {};

    final totalVisitors = booths.fold(0, (sum, booth) => sum + booth.totalVisitors);
    final newLeads = leads.where((lead) => lead.isNew).length;
    final qualifiedLeads = leads.where((lead) => lead.isQualified).length;
    final convertedLeads = leads.where((lead) => lead.isConverted).length;
    
    final conversionRate = leads.isNotEmpty ? (convertedLeads / leads.length) * 100 : 0.0;

    return {
      'sponsorId': sponsorId,
      'sponsorName': sponsor.name,
      'tier': sponsor.tierDisplayName,
      'totalBooths': booths.length,
      'totalVisitors': totalVisitors,
      'totalLeads': leads.length,
      'newLeads': newLeads,
      'qualifiedLeads': qualifiedLeads,
      'convertedLeads': convertedLeads,
      'conversionRate': conversionRate,
      'boothAnalytics': booths.map((booth) => {
        'boothId': booth.id,
        'boothName': booth.name,
        'visitors': booth.totalVisitors,
        'type': booth.typeDisplayName,
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> getEventSponsorshipAnalytics(String eventId) async {
    final sponsors = await getEventSponsors(eventId);
    final booths = await getEventBooths(eventId);
    final packages = await getEventPackages(eventId);
    
    final sponsorsByTier = <String, int>{};
    for (final tier in SponsorTier.values) {
      sponsorsByTier[tier.name] = sponsors.where((s) => s.tier == tier).length;
    }

    final totalVisitors = booths.fold(0, (sum, booth) => sum + booth.totalVisitors);
    final virtualBooths = booths.where((booth) => booth.isVirtual).length;
    final physicalBooths = booths.where((booth) => booth.isPhysical).length;

    final totalRevenue = packages.fold(0.0, (sum, package) => 
      sum + (package.price * package.currentSponsors));

    return {
      'eventId': eventId,
      'totalSponsors': sponsors.length,
      'totalBooths': booths.length,
      'totalPackages': packages.length,
      'totalVisitors': totalVisitors,
      'virtualBooths': virtualBooths,
      'physicalBooths': physicalBooths,
      'sponsorsByTier': sponsorsByTier,
      'totalRevenue': totalRevenue,
      'averageVisitorsPerBooth': booths.isNotEmpty ? totalVisitors / booths.length : 0.0,
    };
  }

  // Utility methods for generating demo data
  Future<void> generateDemoSponsors(String eventId) async {
    final demoSponsors = [
      Sponsor(
        id: 'sponsor_1',
        eventId: eventId,
        name: 'TechCorp Solutions',
        description: 'Leading provider of enterprise software solutions and cloud services.',
        logoUrl: 'https://example.com/logos/techcorp.png',
        bannerUrl: 'https://example.com/banners/techcorp-banner.jpg',
        websiteUrl: 'https://techcorp.com',
        videoUrl: 'https://example.com/videos/techcorp-intro.mp4',
        tier: SponsorTier.platinum,
        type: SponsorType.corporate,
        tags: ['technology', 'enterprise', 'cloud'],
        contactInfo: {
          'email': 'partnerships@techcorp.com',
          'phone': '+1-555-0123',
          'address': '123 Tech Street, Silicon Valley, CA 94000',
        },
        socialMedia: {
          'twitter': '@techcorp',
          'linkedin': 'company/techcorp',
          'youtube': 'techcorpchannel',
        },
        representativeIds: ['rep_1', 'rep_2'],
        createdAt: DateTime.now(),
        isFeatured: true,
        displayOrder: 1,
      ),
      Sponsor(
        id: 'sponsor_2',
        eventId: eventId,
        name: 'InnovateLabs',
        description: 'Cutting-edge AI and machine learning research laboratory.',
        logoUrl: 'https://example.com/logos/innovatelabs.png',
        bannerUrl: 'https://example.com/banners/innovatelabs-banner.jpg',
        websiteUrl: 'https://innovatelabs.ai',
        tier: SponsorTier.gold,
        type: SponsorType.startup,
        tags: ['AI', 'machine learning', 'research'],
        contactInfo: {
          'email': 'hello@innovatelabs.ai',
          'phone': '+1-555-0456',
        },
        socialMedia: {
          'twitter': '@innovatelabs',
          'linkedin': 'company/innovatelabs',
        },
        representativeIds: ['rep_3'],
        createdAt: DateTime.now(),
        isFeatured: true,
        displayOrder: 2,
      ),
      Sponsor(
        id: 'sponsor_3',
        eventId: eventId,
        name: 'GreenTech Initiative',
        description: 'Non-profit organization promoting sustainable technology solutions.',
        logoUrl: 'https://example.com/logos/greentech.png',
        websiteUrl: 'https://greentech-initiative.org',
        tier: SponsorTier.silver,
        type: SponsorType.nonprofit,
        tags: ['sustainability', 'green tech', 'environment'],
        contactInfo: {
          'email': 'info@greentech-initiative.org',
        },
        socialMedia: {
          'twitter': '@greentechini',
          'instagram': 'greentechinitiative',
        },
        representativeIds: ['rep_4'],
        createdAt: DateTime.now(),
        displayOrder: 3,
      ),
      Sponsor(
        id: 'sponsor_4',
        eventId: eventId,
        name: 'StartupHub Accelerator',
        description: 'Supporting early-stage startups with funding and mentorship.',
        logoUrl: 'https://example.com/logos/startuphub.png',
        websiteUrl: 'https://startuphub.vc',
        tier: SponsorTier.community,
        type: SponsorType.startup,
        tags: ['startups', 'funding', 'acceleration'],
        contactInfo: {
          'email': 'partnerships@startuphub.vc',
          'phone': '+1-555-0789',
        },
        representativeIds: ['rep_5'],
        createdAt: DateTime.now(),
        displayOrder: 4,
      ),
    ];

    for (final sponsor in demoSponsors) {
      await createSponsor(sponsor);
    }
  }

  Future<void> generateDemoBooths(String eventId) async {
    final demoBooths = [
      ExhibitorBooth(
        id: 'booth_1',
        sponsorId: 'sponsor_1',
        eventId: eventId,
        name: 'TechCorp Enterprise Solutions',
        description: 'Discover our latest enterprise software and cloud solutions. Meet our experts and see live demos.',
        type: BoothType.hybrid,
        location: 'Hall A, Booth 101',
        virtualRoomUrl: 'https://virtual-expo.com/rooms/techcorp',
        resources: {
          'brochures': ['enterprise-solutions.pdf', 'cloud-migration-guide.pdf'],
          'videos': ['product-demo.mp4', 'customer-testimonials.mp4'],
          'whitepapers': ['cloud-security-best-practices.pdf'],
        },
        staffIds: ['staff_1', 'staff_2', 'staff_3'],
        visitorIds: ['user1', 'user2', 'user3', 'user4', 'user5'],
        analytics: {
          'totalVisits': 15,
          'averageVisitDuration': 8.5,
          'documentsDownloaded': 12,
          'videosWatched': 8,
        },
        createdAt: DateTime.now(),
        settings: {
          'allowVisitorMessages': true,
          'requireLeadCapture': true,
          'showStaffAvailability': true,
        },
      ),
      ExhibitorBooth(
        id: 'booth_2',
        sponsorId: 'sponsor_2',
        eventId: eventId,
        name: 'AI Innovation Showcase',
        description: 'Experience the future of AI technology. Interactive demos and expert consultations available.',
        type: BoothType.virtual,
        virtualRoomUrl: 'https://virtual-expo.com/rooms/innovatelabs',
        resources: {
          'demos': ['ai-chatbot-demo', 'computer-vision-demo'],
          'research': ['latest-ai-research.pdf', 'ml-trends-2024.pdf'],
        },
        staffIds: ['staff_4', 'staff_5'],
        visitorIds: ['user2', 'user6', 'user7'],
        analytics: {
          'totalVisits': 8,
          'averageVisitDuration': 12.3,
          'demosCompleted': 5,
        },
        createdAt: DateTime.now(),
        settings: {
          'allowVisitorMessages': true,
          'requireLeadCapture': false,
          'showDemoScheduling': true,
        },
      ),
      ExhibitorBooth(
        id: 'booth_3',
        sponsorId: 'sponsor_3',
        eventId: eventId,
        name: 'Sustainable Tech Solutions',
        description: 'Learn about green technology initiatives and sustainable business practices.',
        type: BoothType.physical,
        location: 'Hall B, Booth 205',
        resources: {
          'guides': ['sustainability-guide.pdf', 'green-tech-roadmap.pdf'],
          'case-studies': ['corporate-sustainability-success.pdf'],
        },
        staffIds: ['staff_6'],
        visitorIds: ['user1', 'user8'],
        analytics: {
          'totalVisits': 6,
          'averageVisitDuration': 6.7,
          'brochuresTaken': 4,
        },
        createdAt: DateTime.now(),
      ),
    ];

    for (final booth in demoBooths) {
      await createBooth(booth);
    }
  }

  Future<void> generateDemoPackages(String eventId) async {
    final demoPackages = [
      SponsorshipPackage(
        id: 'package_platinum',
        eventId: eventId,
        name: 'Platinum Sponsorship',
        description: 'Premier sponsorship package with maximum visibility and premium benefits.',
        tier: SponsorTier.platinum,
        price: 50000.0,
        benefits: [
          'Prime booth location (20x20 ft)',
          'Main stage keynote slot (30 minutes)',
          'Logo on all event materials',
          'VIP reception hosting rights',
          'Dedicated mobile app section',
          'Pre and post-event attendee data',
          'Social media promotion',
          'Video advertisement during breaks',
        ],
        inclusions: {
          'booth_space': '20x20',
          'speaking_slots': 1,
          'workshop_sessions': 2,
          'networking_events': 'VIP access',
          'attendee_data': 'full_access',
        },
        branding: {
          'logo_placement': ['main_stage', 'mobile_app', 'website', 'banners'],
          'banner_locations': ['entrance', 'main_hall', 'networking_area'],
          'digital_signage': 'premium_rotation',
        },
        maxSponsors: 2,
        currentSponsors: 1,
        createdAt: DateTime.now(),
      ),
      SponsorshipPackage(
        id: 'package_gold',
        eventId: eventId,
        name: 'Gold Sponsorship',
        description: 'Excellent visibility package with great networking opportunities.',
        tier: SponsorTier.gold,
        price: 25000.0,
        benefits: [
          'Premium booth location (15x15 ft)',
          'Breakout session slot (20 minutes)',
          'Logo on select materials',
          'Networking reception access',
          'Mobile app listing',
          'Lead retrieval system',
          'Email blast to attendees',
        ],
        inclusions: {
          'booth_space': '15x15',
          'speaking_slots': 0,
          'workshop_sessions': 1,
          'networking_events': 'premium_access',
          'attendee_data': 'leads_only',
        },
        branding: {
          'logo_placement': ['mobile_app', 'website', 'select_materials'],
          'banner_locations': ['main_hall', 'networking_area'],
          'digital_signage': 'standard_rotation',
        },
        maxSponsors: 4,
        currentSponsors: 2,
        createdAt: DateTime.now(),
      ),
      SponsorshipPackage(
        id: 'package_startup',
        eventId: eventId,
        name: 'Startup Showcase',
        description: 'Affordable package designed for early-stage startups and small companies.',
        tier: SponsorTier.startup,
        price: 5000.0,
        benefits: [
          'Startup pavilion space (8x8 ft)',
          'Pitch competition entry',
          'Startup directory listing',
          'Networking access',
          'Digital marketing kit',
        ],
        inclusions: {
          'booth_space': '8x8',
          'pitch_opportunity': true,
          'directory_listing': true,
          'networking_events': 'standard_access',
        },
        branding: {
          'logo_placement': ['startup_directory', 'mobile_app'],
          'digital_signage': 'startup_showcase',
        },
        maxSponsors: 20,
        currentSponsors: 8,
        createdAt: DateTime.now(),
      ),
    ];

    for (final package in demoPackages) {
      await createPackage(package);
    }
  }
}