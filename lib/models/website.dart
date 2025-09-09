import 'package:json_annotation/json_annotation.dart';

part 'website.g.dart';

enum PageType {
  homepage,
  about,
  agenda,
  speakers,
  sponsors,
  venue,
  registration,
  contact,
  custom,
}

enum ComponentType {
  hero,
  text,
  image,
  gallery,
  speakers_grid,
  agenda_schedule,
  sponsors_grid,
  registration_form,
  contact_form,
  map,
  video,
  countdown,
  testimonials,
  faq,
  social_media,
  custom_html,
}

enum LayoutType {
  single_column,
  two_column,
  three_column,
  sidebar_left,
  sidebar_right,
  grid,
  full_width,
}

@JsonSerializable(explicitToJson: true)
class EventWebsite {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final String domain; // subdomain.eventapp.com or custom domain
  final String? customDomain;
  final WebsiteSettings settings;
  final WebsiteTheme theme;
  final List<WebsitePage> pages;
  final WebsiteSEO seo;
  final Map<String, dynamic> analytics;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final bool isPublished;
  final bool isActive;

  const EventWebsite({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.domain,
    this.customDomain,
    required this.settings,
    required this.theme,
    this.pages = const [],
    required this.seo,
    this.analytics = const {},
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.isPublished = false,
    this.isActive = true,
  });

  factory EventWebsite.fromJson(Map<String, dynamic> json) => _$EventWebsiteFromJson(json);
  Map<String, dynamic> toJson() => _$EventWebsiteToJson(this);

  EventWebsite copyWith({
    String? title,
    String? description,
    String? domain,
    String? customDomain,
    WebsiteSettings? settings,
    WebsiteTheme? theme,
    List<WebsitePage>? pages,
    WebsiteSEO? seo,
    Map<String, dynamic>? analytics,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool? isPublished,
    bool? isActive,
  }) {
    return EventWebsite(
      id: id,
      eventId: eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      domain: domain ?? this.domain,
      customDomain: customDomain ?? this.customDomain,
      settings: settings ?? this.settings,
      theme: theme ?? this.theme,
      pages: pages ?? this.pages,
      seo: seo ?? this.seo,
      analytics: analytics ?? this.analytics,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      publishedAt: publishedAt ?? this.publishedAt,
      isPublished: isPublished ?? this.isPublished,
      isActive: isActive ?? this.isActive,
    );
  }

  String get fullDomain => customDomain ?? '$domain.eventapp.com';
  bool get hasCustomDomain => customDomain != null && customDomain!.isNotEmpty;
  WebsitePage? get homePage => pages.firstWhere((p) => p.type == PageType.homepage, orElse: () => pages.first);
}

@JsonSerializable(explicitToJson: true)
class WebsiteSettings {
  final String favicon;
  final String logo;
  final Map<String, String> socialMedia;
  final ContactInfo contactInfo;
  final NavigationSettings navigation;
  final FooterSettings footer;
  final Map<String, dynamic> integrations; // Google Analytics, Facebook Pixel, etc.
  final bool enableCookieConsent;
  final bool enableRightClick;
  final bool enableTextSelection;
  final String language;
  final String timezone;

  const WebsiteSettings({
    this.favicon = '',
    this.logo = '',
    this.socialMedia = const {},
    required this.contactInfo,
    required this.navigation,
    required this.footer,
    this.integrations = const {},
    this.enableCookieConsent = true,
    this.enableRightClick = true,
    this.enableTextSelection = true,
    this.language = 'en',
    this.timezone = 'UTC',
  });

  factory WebsiteSettings.fromJson(Map<String, dynamic> json) => _$WebsiteSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$WebsiteSettingsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ContactInfo {
  final String email;
  final String phone;
  final String address;
  final String website;

  const ContactInfo({
    this.email = '',
    this.phone = '',
    this.address = '',
    this.website = '',
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) => _$ContactInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ContactInfoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NavigationSettings {
  final List<NavigationItem> items;
  final String style; // horizontal, vertical, hamburger
  final bool showLogo;
  final bool sticky;
  final String position; // top, bottom

  const NavigationSettings({
    this.items = const [],
    this.style = 'horizontal',
    this.showLogo = true,
    this.sticky = true,
    this.position = 'top',
  });

  factory NavigationSettings.fromJson(Map<String, dynamic> json) => _$NavigationSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$NavigationSettingsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NavigationItem {
  final String label;
  final String url;
  final String? pageId;
  final String? icon;
  final bool openInNewTab;
  final List<NavigationItem> children;
  final int order;

  const NavigationItem({
    required this.label,
    required this.url,
    this.pageId,
    this.icon,
    this.openInNewTab = false,
    this.children = const [],
    this.order = 0,
  });

  factory NavigationItem.fromJson(Map<String, dynamic> json) => _$NavigationItemFromJson(json);
  Map<String, dynamic> toJson() => _$NavigationItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FooterSettings {
  final String content;
  final List<FooterColumn> columns;
  final bool showSocialMedia;
  final bool showCopyright;
  final String copyrightText;

  const FooterSettings({
    this.content = '',
    this.columns = const [],
    this.showSocialMedia = true,
    this.showCopyright = true,
    this.copyrightText = '',
  });

  factory FooterSettings.fromJson(Map<String, dynamic> json) => _$FooterSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$FooterSettingsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FooterColumn {
  final String title;
  final List<NavigationItem> links;
  final int order;

  const FooterColumn({
    required this.title,
    this.links = const [],
    this.order = 0,
  });

  factory FooterColumn.fromJson(Map<String, dynamic> json) => _$FooterColumnFromJson(json);
  Map<String, dynamic> toJson() => _$FooterColumnToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WebsiteTheme {
  final String name;
  final ColorScheme colors;
  final Typography typography;
  final Spacing spacing;
  final BorderRadius borderRadius;
  final Shadows shadows;
  final String customCSS;

  const WebsiteTheme({
    required this.name,
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.borderRadius,
    required this.shadows,
    this.customCSS = '',
  });

  factory WebsiteTheme.fromJson(Map<String, dynamic> json) => _$WebsiteThemeFromJson(json);
  Map<String, dynamic> toJson() => _$WebsiteThemeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ColorScheme {
  final String primary;
  final String secondary;
  final String accent;
  final String background;
  final String surface;
  final String text;
  final String textSecondary;
  final String border;
  final String error;
  final String success;
  final String warning;
  final String info;

  const ColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
  });

  factory ColorScheme.fromJson(Map<String, dynamic> json) => _$ColorSchemeFromJson(json);
  Map<String, dynamic> toJson() => _$ColorSchemeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Typography {
  final String headingFont;
  final String bodyFont;
  final Map<String, double> fontSizes;
  final Map<String, int> fontWeights;
  final Map<String, double> lineHeights;

  const Typography({
    required this.headingFont,
    required this.bodyFont,
    required this.fontSizes,
    required this.fontWeights,
    required this.lineHeights,
  });

  factory Typography.fromJson(Map<String, dynamic> json) => _$TypographyFromJson(json);
  Map<String, dynamic> toJson() => _$TypographyToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Spacing {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const Spacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  factory Spacing.fromJson(Map<String, dynamic> json) => _$SpacingFromJson(json);
  Map<String, dynamic> toJson() => _$SpacingToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BorderRadius {
  final double sm;
  final double md;
  final double lg;
  final double full;

  const BorderRadius({
    required this.sm,
    required this.md,
    required this.lg,
    required this.full,
  });

  factory BorderRadius.fromJson(Map<String, dynamic> json) => _$BorderRadiusFromJson(json);
  Map<String, dynamic> toJson() => _$BorderRadiusToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Shadows {
  final String sm;
  final String md;
  final String lg;
  final String xl;

  const Shadows({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  factory Shadows.fromJson(Map<String, dynamic> json) => _$ShadowsFromJson(json);
  Map<String, dynamic> toJson() => _$ShadowsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WebsitePage {
  final String id;
  final String websiteId;
  final String title;
  final String slug;
  final PageType type;
  final String metaTitle;
  final String metaDescription;
  final List<String> metaKeywords;
  final LayoutType layout;
  final List<PageComponent> components;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;
  final int order;

  const WebsitePage({
    required this.id,
    required this.websiteId,
    required this.title,
    required this.slug,
    required this.type,
    this.metaTitle = '',
    this.metaDescription = '',
    this.metaKeywords = const [],
    required this.layout,
    this.components = const [],
    this.settings = const {},
    required this.createdAt,
    this.updatedAt,
    this.isPublished = true,
    this.order = 0,
  });

  factory WebsitePage.fromJson(Map<String, dynamic> json) => _$WebsitePageFromJson(json);
  Map<String, dynamic> toJson() => _$WebsitePageToJson(this);

  WebsitePage copyWith({
    String? title,
    String? slug,
    PageType? type,
    String? metaTitle,
    String? metaDescription,
    List<String>? metaKeywords,
    LayoutType? layout,
    List<PageComponent>? components,
    Map<String, dynamic>? settings,
    DateTime? updatedAt,
    bool? isPublished,
    int? order,
  }) {
    return WebsitePage(
      id: id,
      websiteId: websiteId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      metaKeywords: metaKeywords ?? this.metaKeywords,
      layout: layout ?? this.layout,
      components: components ?? this.components,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPublished: isPublished ?? this.isPublished,
      order: order ?? this.order,
    );
  }

  String get effectiveMetaTitle => metaTitle.isNotEmpty ? metaTitle : title;
}

@JsonSerializable(explicitToJson: true)
class PageComponent {
  final String id;
  final ComponentType type;
  final Map<String, dynamic> data;
  final ComponentStyle style;
  final int order;
  final bool isVisible;

  const PageComponent({
    required this.id,
    required this.type,
    this.data = const {},
    required this.style,
    this.order = 0,
    this.isVisible = true,
  });

  factory PageComponent.fromJson(Map<String, dynamic> json) => _$PageComponentFromJson(json);
  Map<String, dynamic> toJson() => _$PageComponentToJson(this);

  PageComponent copyWith({
    ComponentType? type,
    Map<String, dynamic>? data,
    ComponentStyle? style,
    int? order,
    bool? isVisible,
  }) {
    return PageComponent(
      id: id,
      type: type ?? this.type,
      data: data ?? this.data,
      style: style ?? this.style,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ComponentStyle {
  final Map<String, dynamic> padding;
  final Map<String, dynamic> margin;
  final String backgroundColor;
  final String textColor;
  final String borderColor;
  final double borderWidth;
  final double borderRadius;
  final String shadow;
  final Map<String, dynamic> responsive; // breakpoint-specific styles

  const ComponentStyle({
    this.padding = const {},
    this.margin = const {},
    this.backgroundColor = '',
    this.textColor = '',
    this.borderColor = '',
    this.borderWidth = 0,
    this.borderRadius = 0,
    this.shadow = '',
    this.responsive = const {},
  });

  factory ComponentStyle.fromJson(Map<String, dynamic> json) => _$ComponentStyleFromJson(json);
  Map<String, dynamic> toJson() => _$ComponentStyleToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WebsiteSEO {
  final String title;
  final String description;
  final List<String> keywords;
  final String ogImage;
  final String ogTitle;
  final String ogDescription;
  final String twitterCard;
  final String twitterSite;
  final String canonicalUrl;
  final Map<String, String> structuredData;
  final List<String> robots;

  const WebsiteSEO({
    this.title = '',
    this.description = '',
    this.keywords = const [],
    this.ogImage = '',
    this.ogTitle = '',
    this.ogDescription = '',
    this.twitterCard = 'summary_large_image',
    this.twitterSite = '',
    this.canonicalUrl = '',
    this.structuredData = const {},
    this.robots = const ['index', 'follow'],
  });

  factory WebsiteSEO.fromJson(Map<String, dynamic> json) => _$WebsiteSEOFromJson(json);
  Map<String, dynamic> toJson() => _$WebsiteSEOToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WebsiteTemplate {
  final String id;
  final String name;
  final String description;
  final String preview;
  final String category;
  final List<String> tags;
  final List<WebsitePage> pages;
  final WebsiteTheme theme;
  final WebsiteSettings defaultSettings;
  final bool isPremium;
  final double price;
  final DateTime createdAt;
  final bool isActive;

  const WebsiteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.preview,
    required this.category,
    this.tags = const [],
    required this.pages,
    required this.theme,
    required this.defaultSettings,
    this.isPremium = false,
    this.price = 0.0,
    required this.createdAt,
    this.isActive = true,
  });

  factory WebsiteTemplate.fromJson(Map<String, dynamic> json) => _$WebsiteTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$WebsiteTemplateToJson(this);
}