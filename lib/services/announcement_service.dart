import '../models/announcement.dart';
import 'database_service.dart';

class AnnouncementService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Announcement>> getEventAnnouncements(String eventId, {
    AnnouncementType? type,
    AnnouncementPriority? priority,
    AnnouncementStatus? status,
    bool activeOnly = false,
  }) async {
    final db = await _databaseService.database;
    
    String whereClause = 'eventId = ?';
    List<dynamic> whereArgs = [eventId];
    
    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.name);
    }
    
    if (priority != null) {
      whereClause += ' AND priority = ?';
      whereArgs.add(priority.name);
    }
    
    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status.name);
    }
    
    if (activeOnly) {
      whereClause += ' AND status = ? AND (expiresAt IS NULL OR expiresAt > ?)';
      whereArgs.addAll([AnnouncementStatus.active.name, DateTime.now().toIso8601String()]);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'announcements',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'isPinned DESC, priority DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      final announcementData = maps[i];
      announcementData['targetAudience'] = (announcementData['targetAudience'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      announcementData['tags'] = (announcementData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      announcementData['readByUsers'] = (announcementData['readByUsers'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      announcementData['dismissedByUsers'] = (announcementData['dismissedByUsers'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      announcementData['isPinned'] = announcementData['isPinned'] == 1;
      announcementData['sendPushNotification'] = announcementData['sendPushNotification'] == 1;
      announcementData['sendEmail'] = announcementData['sendEmail'] == 1;
      announcementData['sendSMS'] = announcementData['sendSMS'] == 1;
      return Announcement.fromJson(announcementData);
    });
  }

  Future<Announcement> createAnnouncement(Announcement announcement) async {
    final db = await _databaseService.database;
    
    final announcementData = announcement.toJson();
    announcementData['targetAudience'] = announcement.targetAudience.join(',');
    announcementData['tags'] = announcement.tags.join(',');
    announcementData['readByUsers'] = announcement.readByUsers.join(',');
    announcementData['dismissedByUsers'] = announcement.dismissedByUsers.join(',');
    announcementData['isPinned'] = announcement.isPinned ? 1 : 0;
    announcementData['sendPushNotification'] = announcement.sendPushNotification ? 1 : 0;
    announcementData['sendEmail'] = announcement.sendEmail ? 1 : 0;
    announcementData['sendSMS'] = announcement.sendSMS ? 1 : 0;

    await db.insert('announcements', announcementData);
    
    // If announcement is active and should send notifications, trigger them
    if (announcement.status == AnnouncementStatus.active) {
      await _triggerNotifications(announcement);
    }
    
    return announcement;
  }

  Future<Announcement> updateAnnouncement(Announcement announcement) async {
    final db = await _databaseService.database;
    
    final announcementData = announcement.toJson();
    announcementData['targetAudience'] = announcement.targetAudience.join(',');
    announcementData['tags'] = announcement.tags.join(',');
    announcementData['readByUsers'] = announcement.readByUsers.join(',');
    announcementData['dismissedByUsers'] = announcement.dismissedByUsers.join(',');
    announcementData['isPinned'] = announcement.isPinned ? 1 : 0;
    announcementData['sendPushNotification'] = announcement.sendPushNotification ? 1 : 0;
    announcementData['sendEmail'] = announcement.sendEmail ? 1 : 0;
    announcementData['sendSMS'] = announcement.sendSMS ? 1 : 0;

    await db.update(
      'announcements',
      announcementData,
      where: 'id = ?',
      whereArgs: [announcement.id],
    );
    
    return announcement;
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    final db = await _databaseService.database;
    await db.delete(
      'announcements',
      where: 'id = ?',
      whereArgs: [announcementId],
    );
  }

  Future<Announcement?> getAnnouncementById(String announcementId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'announcements',
      where: 'id = ?',
      whereArgs: [announcementId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final announcementData = maps.first;
      announcementData['targetAudience'] = (announcementData['targetAudience'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      announcementData['tags'] = (announcementData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      announcementData['readByUsers'] = (announcementData['readByUsers'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      announcementData['dismissedByUsers'] = (announcementData['dismissedByUsers'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      announcementData['isPinned'] = announcementData['isPinned'] == 1;
      announcementData['sendPushNotification'] = announcementData['sendPushNotification'] == 1;
      announcementData['sendEmail'] = announcementData['sendEmail'] == 1;
      announcementData['sendSMS'] = announcementData['sendSMS'] == 1;
      return Announcement.fromJson(announcementData);
    }
    return null;
  }

  Future<void> markAsRead(String announcementId, String userId) async {
    final announcement = await getAnnouncementById(announcementId);
    if (announcement == null || announcement.readByUsers.contains(userId)) return;

    final updatedReadByUsers = [...announcement.readByUsers, userId];
    final updatedAnnouncement = announcement.copyWith(
      readByUsers: updatedReadByUsers,
      viewCount: announcement.viewCount + 1,
    );
    
    await updateAnnouncement(updatedAnnouncement);
  }

  Future<void> markAsDismissed(String announcementId, String userId) async {
    final announcement = await getAnnouncementById(announcementId);
    if (announcement == null || announcement.dismissedByUsers.contains(userId)) return;

    final updatedDismissedByUsers = [...announcement.dismissedByUsers, userId];
    final updatedAnnouncement = announcement.copyWith(dismissedByUsers: updatedDismissedByUsers);
    
    await updateAnnouncement(updatedAnnouncement);
  }

  Future<void> incrementClickCount(String announcementId) async {
    final announcement = await getAnnouncementById(announcementId);
    if (announcement == null) return;

    final updatedAnnouncement = announcement.copyWith(clickCount: announcement.clickCount + 1);
    await updateAnnouncement(updatedAnnouncement);
  }

  Future<List<Announcement>> getUnreadAnnouncements(String eventId, String userId) async {
    final announcements = await getEventAnnouncements(eventId, activeOnly: true);
    return announcements.where((announcement) => 
      !announcement.isReadBy(userId) && !announcement.isDismissedBy(userId)
    ).toList();
  }

  Future<List<Announcement>> getPinnedAnnouncements(String eventId) async {
    final announcements = await getEventAnnouncements(eventId, activeOnly: true);
    return announcements.where((announcement) => announcement.isPinned).toList();
  }

  Future<List<Announcement>> getUrgentAnnouncements(String eventId) async {
    return getEventAnnouncements(
      eventId, 
      priority: AnnouncementPriority.urgent, 
      activeOnly: true,
    );
  }

  Future<List<Announcement>> getScheduledAnnouncements(String eventId) async {
    return getEventAnnouncements(eventId, status: AnnouncementStatus.scheduled);
  }

  Future<void> activateScheduledAnnouncements() async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();
    
    // Get scheduled announcements that should now be active
    final List<Map<String, dynamic>> maps = await db.query(
      'announcements',
      where: 'status = ? AND scheduledAt <= ?',
      whereArgs: [AnnouncementStatus.scheduled.name, now],
    );

    for (final map in maps) {
      final announcement = Announcement.fromJson(map);
      final activatedAnnouncement = announcement.copyWith(
        status: AnnouncementStatus.active,
      );
      
      await updateAnnouncement(activatedAnnouncement);
      await _triggerNotifications(activatedAnnouncement);
    }
  }

  Future<void> expireAnnouncements() async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'announcements',
      {'status': AnnouncementStatus.expired.name},
      where: 'status = ? AND expiresAt <= ?',
      whereArgs: [AnnouncementStatus.active.name, now],
    );
  }

  Future<List<Announcement>> searchAnnouncements(String eventId, String query) async {
    final announcements = await getEventAnnouncements(eventId);
    final lowercaseQuery = query.toLowerCase();
    
    return announcements.where((announcement) {
      return announcement.title.toLowerCase().contains(lowercaseQuery) ||
             announcement.content.toLowerCase().contains(lowercaseQuery) ||
             announcement.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<Map<AnnouncementType, int>> getAnnouncementTypeDistribution(String eventId) async {
    final announcements = await getEventAnnouncements(eventId);
    final Map<AnnouncementType, int> distribution = {};
    
    for (final type in AnnouncementType.values) {
      distribution[type] = 0;
    }
    
    for (final announcement in announcements) {
      distribution[announcement.type] = (distribution[announcement.type] ?? 0) + 1;
    }
    
    return distribution;
  }

  Future<Map<String, dynamic>> getAnnouncementStats(String eventId) async {
    final announcements = await getEventAnnouncements(eventId);
    
    int totalViews = 0;
    int totalClicks = 0;
    int totalReads = 0;
    int totalDismissals = 0;
    int activeCount = 0;
    int pinnedCount = 0;
    int urgentCount = 0;
    
    for (final announcement in announcements) {
      totalViews += announcement.viewCount;
      totalClicks += announcement.clickCount;
      totalReads += announcement.readCount;
      totalDismissals += announcement.dismissedCount;
      
      if (announcement.status == AnnouncementStatus.active) activeCount++;
      if (announcement.isPinned) pinnedCount++;
      if (announcement.priority == AnnouncementPriority.urgent) urgentCount++;
    }
    
    return {
      'totalAnnouncements': announcements.length,
      'activeAnnouncements': activeCount,
      'pinnedAnnouncements': pinnedCount,
      'urgentAnnouncements': urgentCount,
      'totalViews': totalViews,
      'totalClicks': totalClicks,
      'totalReads': totalReads,
      'totalDismissals': totalDismissals,
      'averageViewsPerAnnouncement': announcements.isEmpty ? 0.0 : totalViews / announcements.length,
      'averageClicksPerAnnouncement': announcements.isEmpty ? 0.0 : totalClicks / announcements.length,
      'readRate': totalViews == 0 ? 0.0 : totalReads / totalViews,
      'dismissalRate': totalViews == 0 ? 0.0 : totalDismissals / totalViews,
      'typeDistribution': await getAnnouncementTypeDistribution(eventId),
    };
  }

  // Template Management
  Future<List<AnnouncementTemplate>> getAnnouncementTemplates() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'announcement_templates',
      orderBy: 'isDefault DESC, name ASC',
    );

    return List.generate(maps.length, (i) {
      final templateData = maps[i];
      templateData['tags'] = (templateData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      templateData['isDefault'] = templateData['isDefault'] == 1;
      return AnnouncementTemplate.fromJson(templateData);
    });
  }

  Future<AnnouncementTemplate> createTemplate(AnnouncementTemplate template) async {
    final db = await _databaseService.database;
    
    final templateData = template.toJson();
    templateData['tags'] = template.tags.join(',');
    templateData['isDefault'] = template.isDefault ? 1 : 0;

    await db.insert('announcement_templates', templateData);
    return template;
  }

  Future<void> deleteTemplate(String templateId) async {
    final db = await _databaseService.database;
    await db.delete(
      'announcement_templates',
      where: 'id = ?',
      whereArgs: [templateId],
    );
  }

  Future<void> _triggerNotifications(Announcement announcement) async {
    // In a real app, this would trigger actual push notifications, emails, SMS
    // For now, we'll just simulate the notification triggers
    
    if (announcement.sendPushNotification) {
      await _sendPushNotification(announcement);
    }
    
    if (announcement.sendEmail) {
      await _sendEmailNotification(announcement);
    }
    
    if (announcement.sendSMS) {
      await _sendSMSNotification(announcement);
    }
  }

  Future<void> _sendPushNotification(Announcement announcement) async {
    // Simulate push notification
    print('Push notification sent for announcement: ${announcement.title}');
    // In real app: Firebase Cloud Messaging, APNs, etc.
  }

  Future<void> _sendEmailNotification(Announcement announcement) async {
    // Simulate email notification
    print('Email notification sent for announcement: ${announcement.title}');
    // In real app: SendGrid, AWS SES, etc.
  }

  Future<void> _sendSMSNotification(Announcement announcement) async {
    // Simulate SMS notification
    print('SMS notification sent for announcement: ${announcement.title}');
    // In real app: Twilio, AWS SNS, etc.
  }

  Future<void> pinAnnouncement(String announcementId, bool pin) async {
    final announcement = await getAnnouncementById(announcementId);
    if (announcement != null) {
      final updatedAnnouncement = announcement.copyWith(isPinned: pin);
      await updateAnnouncement(updatedAnnouncement);
    }
  }

  Future<void> changeAnnouncementStatus(String announcementId, AnnouncementStatus newStatus) async {
    final announcement = await getAnnouncementById(announcementId);
    if (announcement != null) {
      final updatedAnnouncement = announcement.copyWith(status: newStatus);
      await updateAnnouncement(updatedAnnouncement);
      
      // If activating an announcement, trigger notifications
      if (newStatus == AnnouncementStatus.active) {
        await _triggerNotifications(updatedAnnouncement);
      }
    }
  }

  Future<List<Announcement>> getAnnouncementsForUser(String eventId, String userId) async {
    final announcements = await getEventAnnouncements(eventId, activeOnly: true);
    
    return announcements.where((announcement) {
      // If no target audience specified, show to everyone
      if (announcement.targetAudience.isEmpty) return true;
      
      // Check if user is in target audience
      return announcement.targetAudience.contains(userId) ||
             announcement.targetAudience.contains('all') ||
             announcement.targetAudience.contains('attendees');
    }).toList();
  }

  // Scheduled task to run periodically
  Future<void> processScheduledAnnouncements() async {
    await activateScheduledAnnouncements();
    await expireAnnouncements();
  }
}