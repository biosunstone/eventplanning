import '../models/website.dart';
import 'database_service.dart';

class WebsiteService {
  final DatabaseService _databaseService = DatabaseService();

  // Website Management
  Future<EventWebsite?> getEventWebsite(String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'event_websites',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );

    return maps.isNotEmpty ? EventWebsite.fromJson(maps.first) : null;
  }

  Future<EventWebsite?> getWebsiteById(String websiteId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'event_websites',
      where: 'id = ?',
      whereArgs: [websiteId],
    );

    return maps.isNotEmpty ? EventWebsite.fromJson(maps.first) : null;
  }

  Future<EventWebsite?> getWebsiteByDomain(String domain) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'event_websites',
      where: 'domain = ? OR customDomain = ?',
      whereArgs: [domain, domain],
    );

    return maps.isNotEmpty ? EventWebsite.fromJson(maps.first) : null;
  }

  Future<EventWebsite> createWebsite(EventWebsite website) async {
    final db = await _databaseService.database;
    await db.insert('event_websites', website.toJson());
    return website;
  }

  Future<void> updateWebsite(EventWebsite website) async {
    final db = await _databaseService.database;
    await db.update(
      'event_websites',
      website.toJson(),
      where: 'id = ?',
      whereArgs: [website.id],
    );
  }

  Future<void> deleteWebsite(String websiteId) async {
    final db = await _databaseService.database;
    
    // Delete related pages and components
    await Future.wait([
      db.delete('website_pages', where: 'websiteId = ?', whereArgs: [websiteId]),
    ]);
    
    // Delete website
    await db.delete('event_websites', where: 'id = ?', whereArgs: [websiteId]);
  }

  Future<void> publishWebsite(String websiteId) async {
    final website = await getWebsiteById(websiteId);
    if (website != null) {
      final updatedWebsite = website.copyWith(
        isPublished: true,
        publishedAt: DateTime.now(),
      );
      await updateWebsite(updatedWebsite);
    }
  }

  Future<void> unpublishWebsite(String websiteId) async {
    final website = await getWebsiteById(websiteId);
    if (website != null) {
      final updatedWebsite = website.copyWith(isPublished: false);
      await updateWebsite(updatedWebsite);
    }
  }

  // Page Management
  Future<List<WebsitePage>> getWebsitePages(String websiteId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'website_pages',
      where: 'websiteId = ?',
      whereArgs: [websiteId],
      orderBy: 'order ASC',
    );

    return maps.map((map) => WebsitePage.fromJson(map)).toList();
  }

  Future<WebsitePage?> getPageById(String pageId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'website_pages',
      where: 'id = ?',
      whereArgs: [pageId],
    );

    return maps.isNotEmpty ? WebsitePage.fromJson(maps.first) : null;
  }

  Future<WebsitePage?> getPageBySlug(String websiteId, String slug) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'website_pages',
      where: 'websiteId = ? AND slug = ?',
      whereArgs: [websiteId, slug],
    );

    return maps.isNotEmpty ? WebsitePage.fromJson(maps.first) : null;
  }

  Future<WebsitePage> createPage(WebsitePage page) async {
    final db = await _databaseService.database;
    await db.insert('website_pages', page.toJson());
    return page;
  }

  Future<void> updatePage(WebsitePage page) async {
    final db = await _databaseService.database;
    await db.update(
      'website_pages',
      page.toJson(),
      where: 'id = ?',
      whereArgs: [page.id],
    );
  }

  Future<void> deletePage(String pageId) async {
    final db = await _databaseService.database;
    await db.delete('website_pages', where: 'id = ?', whereArgs: [pageId]);
  }

  Future<void> reorderPages(String websiteId, List<String> pageIds) async {
    final db = await _databaseService.database;
    
    for (int i = 0; i < pageIds.length; i++) {
      await db.update(
        'website_pages',
        {'order': i},
        where: 'id = ? AND websiteId = ?',
        whereArgs: [pageIds[i], websiteId],
      );
    }
  }

  // Template Management
  Future<List<WebsiteTemplate>> getTemplates({String? category}) async {
    final db = await _databaseService.database;
    
    String whereClause = 'isActive = 1';
    List<dynamic> whereArgs = [];
    
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'website_templates',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((map) => WebsiteTemplate.fromJson(map)).toList();
  }

  Future<WebsiteTemplate?> getTemplate(String templateId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'website_templates',
      where: 'id = ?',
      whereArgs: [templateId],
    );

    return maps.isNotEmpty ? WebsiteTemplate.fromJson(maps.first) : null;
  }

  Future<EventWebsite> createWebsiteFromTemplate(
    String eventId,
    String templateId,
    String domain,
    String title,
  ) async {
    final template = await getTemplate(templateId);
    if (template == null) {
      throw Exception('Template not found');
    }

    final websiteId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final website = EventWebsite(
      id: websiteId,
      eventId: eventId,
      title: title,
      description: template.description,
      domain: domain,
      settings: template.defaultSettings,
      theme: template.theme,
      seo: WebsiteSEO(
        title: title,
        description: template.description,
      ),
      createdAt: DateTime.now(),
    );

    await createWebsite(website);

    // Create pages from template
    for (final templatePage in template.pages) {
      final pageId = DateTime.now().millisecondsSinceEpoch.toString();
      final page = WebsitePage(
        id: pageId,
        websiteId: websiteId,
        title: templatePage.title,
        slug: templatePage.slug,
        type: templatePage.type,
        layout: templatePage.layout,
        components: templatePage.components,
        createdAt: DateTime.now(),
        order: templatePage.order,
      );
      await createPage(page);
    }

    return website;
  }

  // Content Generation
  Future<void> generateContentFromEvent(String websiteId, String eventId) async {
    // This would integrate with the event data to populate website content
    // For now, we'll create placeholder implementations
    
    final website = await getWebsiteById(websiteId);
    if (website == null) return;

    final pages = await getWebsitePages(websiteId);
    
    // Update homepage with event info
    final homePage = pages.where((p) => p.type == PageType.homepage).firstOrNull;
    if (homePage != null) {
      // Add hero section with event details
      final heroComponent = PageComponent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ComponentType.hero,
        data: {
          'title': website.title,
          'subtitle': website.description,
          'backgroundImage': '',
          'buttonText': 'Register Now',
          'buttonUrl': '/registration',
        },
        style: const ComponentStyle(),
        order: 0,
      );

      final updatedComponents = [heroComponent, ...homePage.components];
      final updatedPage = homePage.copyWith(components: updatedComponents);
      await updatePage(updatedPage);
    }

    // Create agenda page if it doesn't exist
    final agendaPage = pages.where((p) => p.type == PageType.agenda).firstOrNull;
    if (agendaPage == null) {
      await _createAgendaPage(websiteId, eventId);
    }

    // Create speakers page if it doesn't exist
    final speakersPage = pages.where((p) => p.type == PageType.speakers).firstOrNull;
    if (speakersPage == null) {
      await _createSpeakersPage(websiteId, eventId);
    }

    // Create sponsors page if it doesn't exist
    final sponsorsPage = pages.where((p) => p.type == PageType.sponsors).firstOrNull;
    if (sponsorsPage == null) {
      await _createSponsorsPage(websiteId, eventId);
    }
  }

  Future<void> _createAgendaPage(String websiteId, String eventId) async {
    final pageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final agendaComponent = PageComponent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ComponentType.agenda_schedule,
      data: {
        'eventId': eventId,
        'showFilters': true,
        'showSpeakers': true,
        'layout': 'timeline',
      },
      style: const ComponentStyle(),
      order: 0,
    );

    final page = WebsitePage(
      id: pageId,
      websiteId: websiteId,
      title: 'Agenda',
      slug: 'agenda',
      type: PageType.agenda,
      metaTitle: 'Event Agenda - Schedule & Sessions',
      metaDescription: 'View the complete event schedule with sessions, speakers, and timing.',
      layout: LayoutType.single_column,
      components: [agendaComponent],
      createdAt: DateTime.now(),
      order: 1,
    );

    await createPage(page);
  }

  Future<void> _createSpeakersPage(String websiteId, String eventId) async {
    final pageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final speakersComponent = PageComponent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ComponentType.speakers_grid,
      data: {
        'eventId': eventId,
        'layout': 'grid',
        'columns': 3,
        'showBio': true,
        'showSocial': true,
      },
      style: const ComponentStyle(),
      order: 0,
    );

    final page = WebsitePage(
      id: pageId,
      websiteId: websiteId,
      title: 'Speakers',
      slug: 'speakers',
      type: PageType.speakers,
      metaTitle: 'Event Speakers - Meet Our Experts',
      metaDescription: 'Learn about our distinguished speakers and their expertise.',
      layout: LayoutType.single_column,
      components: [speakersComponent],
      createdAt: DateTime.now(),
      order: 2,
    );

    await createPage(page);
  }

  Future<void> _createSponsorsPage(String websiteId, String eventId) async {
    final pageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final sponsorsComponent = PageComponent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ComponentType.sponsors_grid,
      data: {
        'eventId': eventId,
        'groupByTier': true,
        'showDescription': true,
        'layout': 'tiered',
      },
      style: const ComponentStyle(),
      order: 0,
    );

    final page = WebsitePage(
      id: pageId,
      websiteId: websiteId,
      title: 'Sponsors',
      slug: 'sponsors',
      type: PageType.sponsors,
      metaTitle: 'Event Sponsors - Our Partners',
      metaDescription: 'Meet our sponsors and partners who make this event possible.',
      layout: LayoutType.single_column,
      components: [sponsorsComponent],
      createdAt: DateTime.now(),
      order: 3,
    );

    await createPage(page);
  }

  // Analytics
  Future<Map<String, dynamic>> getWebsiteAnalytics(String websiteId) async {
    final website = await getWebsiteById(websiteId);
    if (website == null) return {};

    // In a real implementation, this would fetch from analytics services
    return {
      'websiteId': websiteId,
      'pageViews': 1250,
      'uniqueVisitors': 890,
      'averageTimeOnSite': 180, // seconds
      'bounceRate': 0.35,
      'topPages': [
        {'path': '/', 'views': 450},
        {'path': '/agenda', 'views': 320},
        {'path': '/speakers', 'views': 280},
        {'path': '/registration', 'views': 200},
      ],
      'trafficSources': {
        'direct': 0.45,
        'search': 0.30,
        'social': 0.15,
        'referral': 0.10,
      },
      'deviceTypes': {
        'desktop': 0.55,
        'mobile': 0.35,
        'tablet': 0.10,
      },
    };
  }

  // Domain Management
  Future<bool> isDomainAvailable(String domain) async {
    final website = await getWebsiteByDomain(domain);
    return website == null;
  }

  Future<void> setCustomDomain(String websiteId, String customDomain) async {
    final website = await getWebsiteById(websiteId);
    if (website != null) {
      final updatedWebsite = website.copyWith(customDomain: customDomain);
      await updateWebsite(updatedWebsite);
    }
  }

  // Utility methods for generating demo data
  Future<void> generateDemoTemplates() async {
    final demoTemplates = [
      WebsiteTemplate(
        id: 'template_modern',
        name: 'Modern Conference',
        description: 'Clean and contemporary design perfect for professional conferences',
        preview: 'https://example.com/previews/modern.jpg',
        category: 'conference',
        tags: ['modern', 'clean', 'professional'],
        pages: _getModernTemplatePages(),
        theme: _getModernTheme(),
        defaultSettings: _getDefaultSettings(),
        createdAt: DateTime.now(),
      ),
      WebsiteTemplate(
        id: 'template_creative',
        name: 'Creative Workshop',
        description: 'Vibrant and artistic design for creative workshops and meetups',
        preview: 'https://example.com/previews/creative.jpg',
        category: 'workshop',
        tags: ['creative', 'colorful', 'artistic'],
        pages: _getCreativeTemplatePages(),
        theme: _getCreativeTheme(),
        defaultSettings: _getDefaultSettings(),
        createdAt: DateTime.now(),
      ),
      WebsiteTemplate(
        id: 'template_tech',
        name: 'Tech Summit',
        description: 'Sleek and innovative design for technology conferences',
        preview: 'https://example.com/previews/tech.jpg',
        category: 'tech',
        tags: ['tech', 'innovation', 'sleek'],
        pages: _getTechTemplatePages(),
        theme: _getTechTheme(),
        defaultSettings: _getDefaultSettings(),
        createdAt: DateTime.now(),
      ),
    ];

    final db = await _databaseService.database;
    for (final template in demoTemplates) {
      await db.insert('website_templates', template.toJson());
    }
  }

  List<WebsitePage> _getModernTemplatePages() {
    return [
      WebsitePage(
        id: 'page_home_modern',
        websiteId: '',
        title: 'Home',
        slug: '',
        type: PageType.homepage,
        layout: LayoutType.single_column,
        components: [
          PageComponent(
            id: 'hero_modern',
            type: ComponentType.hero,
            data: {
              'title': 'Welcome to Our Event',
              'subtitle': 'Join us for an unforgettable experience',
              'buttonText': 'Register Now',
              'buttonUrl': '/registration',
            },
            style: const ComponentStyle(),
          ),
          PageComponent(
            id: 'about_modern',
            type: ComponentType.text,
            data: {
              'content': 'About Our Event\n\nJoin industry leaders and innovators for a day of learning, networking, and inspiration.',
            },
            style: const ComponentStyle(),
            order: 1,
          ),
        ],
        createdAt: DateTime.now(),
      ),
      WebsitePage(
        id: 'page_about_modern',
        websiteId: '',
        title: 'About',
        slug: 'about',
        type: PageType.about,
        layout: LayoutType.single_column,
        components: [],
        createdAt: DateTime.now(),
        order: 1,
      ),
    ];
  }

  List<WebsitePage> _getCreativeTemplatePages() {
    return [
      WebsitePage(
        id: 'page_home_creative',
        websiteId: '',
        title: 'Home',
        slug: '',
        type: PageType.homepage,
        layout: LayoutType.single_column,
        components: [],
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<WebsitePage> _getTechTemplatePages() {
    return [
      WebsitePage(
        id: 'page_home_tech',
        websiteId: '',
        title: 'Home',
        slug: '',
        type: PageType.homepage,
        layout: LayoutType.single_column,
        components: [],
        createdAt: DateTime.now(),
      ),
    ];
  }

  WebsiteTheme _getModernTheme() {
    return const WebsiteTheme(
      name: 'Modern',
      colors: ColorScheme(
        primary: '#2563eb',
        secondary: '#64748b',
        accent: '#f59e0b',
        background: '#ffffff',
        surface: '#f8fafc',
        text: '#1e293b',
        textSecondary: '#64748b',
        border: '#e2e8f0',
        error: '#dc2626',
        success: '#16a34a',
        warning: '#d97706',
        info: '#0ea5e9',
      ),
      typography: Typography(
        headingFont: 'Inter',
        bodyFont: 'Inter',
        fontSizes: {
          'xs': 12,
          'sm': 14,
          'base': 16,
          'lg': 18,
          'xl': 20,
          '2xl': 24,
          '3xl': 30,
          '4xl': 36,
        },
        fontWeights: {
          'normal': 400,
          'medium': 500,
          'semibold': 600,
          'bold': 700,
        },
        lineHeights: {
          'tight': 1.25,
          'normal': 1.5,
          'relaxed': 1.75,
        },
      ),
      spacing: Spacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32),
      borderRadius: BorderRadius(sm: 4, md: 8, lg: 12, full: 9999),
      shadows: Shadows(
        sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
        md: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
        lg: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
        xl: '0 20px 25px -5px rgb(0 0 0 / 0.1)',
      ),
    );
  }

  WebsiteTheme _getCreativeTheme() {
    return const WebsiteTheme(
      name: 'Creative',
      colors: ColorScheme(
        primary: '#8b5cf6',
        secondary: '#ec4899',
        accent: '#f59e0b',
        background: '#fefefe',
        surface: '#f8fafc',
        text: '#1e293b',
        textSecondary: '#64748b',
        border: '#e2e8f0',
        error: '#dc2626',
        success: '#16a34a',
        warning: '#d97706',
        info: '#0ea5e9',
      ),
      typography: Typography(
        headingFont: 'Poppins',
        bodyFont: 'Open Sans',
        fontSizes: {
          'xs': 12,
          'sm': 14,
          'base': 16,
          'lg': 18,
          'xl': 20,
          '2xl': 24,
          '3xl': 30,
          '4xl': 36,
        },
        fontWeights: {
          'normal': 400,
          'medium': 500,
          'semibold': 600,
          'bold': 700,
        },
        lineHeights: {
          'tight': 1.25,
          'normal': 1.5,
          'relaxed': 1.75,
        },
      ),
      spacing: Spacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32),
      borderRadius: BorderRadius(sm: 6, md: 12, lg: 18, full: 9999),
      shadows: Shadows(
        sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
        md: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
        lg: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
        xl: '0 20px 25px -5px rgb(0 0 0 / 0.1)',
      ),
    );
  }

  WebsiteTheme _getTechTheme() {
    return const WebsiteTheme(
      name: 'Tech',
      colors: ColorScheme(
        primary: '#0f172a',
        secondary: '#334155',
        accent: '#06b6d4',
        background: '#ffffff',
        surface: '#f1f5f9',
        text: '#0f172a',
        textSecondary: '#475569',
        border: '#cbd5e1',
        error: '#dc2626',
        success: '#16a34a',
        warning: '#d97706',
        info: '#0ea5e9',
      ),
      typography: Typography(
        headingFont: 'JetBrains Mono',
        bodyFont: 'Inter',
        fontSizes: {
          'xs': 12,
          'sm': 14,
          'base': 16,
          'lg': 18,
          'xl': 20,
          '2xl': 24,
          '3xl': 30,
          '4xl': 36,
        },
        fontWeights: {
          'normal': 400,
          'medium': 500,
          'semibold': 600,
          'bold': 700,
        },
        lineHeights: {
          'tight': 1.25,
          'normal': 1.5,
          'relaxed': 1.75,
        },
      ),
      spacing: Spacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32),
      borderRadius: BorderRadius(sm: 2, md: 4, lg: 8, full: 9999),
      shadows: Shadows(
        sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
        md: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
        lg: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
        xl: '0 20px 25px -5px rgb(0 0 0 / 0.1)',
      ),
    );
  }

  WebsiteSettings _getDefaultSettings() {
    return const WebsiteSettings(
      contactInfo: ContactInfo(),
      navigation: NavigationSettings(
        items: [
          NavigationItem(label: 'Home', url: '/', order: 0),
          NavigationItem(label: 'About', url: '/about', order: 1),
          NavigationItem(label: 'Agenda', url: '/agenda', order: 2),
          NavigationItem(label: 'Speakers', url: '/speakers', order: 3),
          NavigationItem(label: 'Sponsors', url: '/sponsors', order: 4),
          NavigationItem(label: 'Register', url: '/registration', order: 5),
        ],
      ),
      footer: FooterSettings(),
    );
  }
}