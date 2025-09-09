// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'website.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventWebsite _$EventWebsiteFromJson(Map<String, dynamic> json) => EventWebsite(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      domain: json['domain'] as String,
      customDomain: json['customDomain'] as String?,
      settings:
          WebsiteSettings.fromJson(json['settings'] as Map<String, dynamic>),
      theme: WebsiteTheme.fromJson(json['theme'] as Map<String, dynamic>),
      pages: (json['pages'] as List<dynamic>?)
              ?.map((e) => WebsitePage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      seo: WebsiteSEO.fromJson(json['seo'] as Map<String, dynamic>),
      analytics: json['analytics'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      isPublished: json['isPublished'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$EventWebsiteToJson(EventWebsite instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'title': instance.title,
      'description': instance.description,
      'domain': instance.domain,
      'customDomain': instance.customDomain,
      'settings': instance.settings.toJson(),
      'theme': instance.theme.toJson(),
      'pages': instance.pages.map((e) => e.toJson()).toList(),
      'seo': instance.seo.toJson(),
      'analytics': instance.analytics,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'publishedAt': instance.publishedAt?.toIso8601String(),
      'isPublished': instance.isPublished,
      'isActive': instance.isActive,
    };

WebsiteSettings _$WebsiteSettingsFromJson(Map<String, dynamic> json) =>
    WebsiteSettings(
      favicon: json['favicon'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      socialMedia: (json['socialMedia'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      contactInfo:
          ContactInfo.fromJson(json['contactInfo'] as Map<String, dynamic>),
      navigation: NavigationSettings.fromJson(
          json['navigation'] as Map<String, dynamic>),
      footer: FooterSettings.fromJson(json['footer'] as Map<String, dynamic>),
      integrations: json['integrations'] as Map<String, dynamic>? ?? const {},
      enableCookieConsent: json['enableCookieConsent'] as bool? ?? true,
      enableRightClick: json['enableRightClick'] as bool? ?? true,
      enableTextSelection: json['enableTextSelection'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'UTC',
    );

Map<String, dynamic> _$WebsiteSettingsToJson(WebsiteSettings instance) =>
    <String, dynamic>{
      'favicon': instance.favicon,
      'logo': instance.logo,
      'socialMedia': instance.socialMedia,
      'contactInfo': instance.contactInfo.toJson(),
      'navigation': instance.navigation.toJson(),
      'footer': instance.footer.toJson(),
      'integrations': instance.integrations,
      'enableCookieConsent': instance.enableCookieConsent,
      'enableRightClick': instance.enableRightClick,
      'enableTextSelection': instance.enableTextSelection,
      'language': instance.language,
      'timezone': instance.timezone,
    };

ContactInfo _$ContactInfoFromJson(Map<String, dynamic> json) => ContactInfo(
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      website: json['website'] as String? ?? '',
    );

Map<String, dynamic> _$ContactInfoToJson(ContactInfo instance) =>
    <String, dynamic>{
      'email': instance.email,
      'phone': instance.phone,
      'address': instance.address,
      'website': instance.website,
    };

NavigationSettings _$NavigationSettingsFromJson(Map<String, dynamic> json) =>
    NavigationSettings(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => NavigationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      style: json['style'] as String? ?? 'horizontal',
      showLogo: json['showLogo'] as bool? ?? true,
      sticky: json['sticky'] as bool? ?? true,
      position: json['position'] as String? ?? 'top',
    );

Map<String, dynamic> _$NavigationSettingsToJson(NavigationSettings instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'style': instance.style,
      'showLogo': instance.showLogo,
      'sticky': instance.sticky,
      'position': instance.position,
    };

NavigationItem _$NavigationItemFromJson(Map<String, dynamic> json) =>
    NavigationItem(
      label: json['label'] as String,
      url: json['url'] as String,
      pageId: json['pageId'] as String?,
      icon: json['icon'] as String?,
      openInNewTab: json['openInNewTab'] as bool? ?? false,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => NavigationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NavigationItemToJson(NavigationItem instance) =>
    <String, dynamic>{
      'label': instance.label,
      'url': instance.url,
      'pageId': instance.pageId,
      'icon': instance.icon,
      'openInNewTab': instance.openInNewTab,
      'children': instance.children.map((e) => e.toJson()).toList(),
      'order': instance.order,
    };

FooterSettings _$FooterSettingsFromJson(Map<String, dynamic> json) =>
    FooterSettings(
      content: json['content'] as String? ?? '',
      columns: (json['columns'] as List<dynamic>?)
              ?.map((e) => FooterColumn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      showSocialMedia: json['showSocialMedia'] as bool? ?? true,
      showCopyright: json['showCopyright'] as bool? ?? true,
      copyrightText: json['copyrightText'] as String? ?? '',
    );

Map<String, dynamic> _$FooterSettingsToJson(FooterSettings instance) =>
    <String, dynamic>{
      'content': instance.content,
      'columns': instance.columns.map((e) => e.toJson()).toList(),
      'showSocialMedia': instance.showSocialMedia,
      'showCopyright': instance.showCopyright,
      'copyrightText': instance.copyrightText,
    };

FooterColumn _$FooterColumnFromJson(Map<String, dynamic> json) => FooterColumn(
      title: json['title'] as String,
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => NavigationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FooterColumnToJson(FooterColumn instance) =>
    <String, dynamic>{
      'title': instance.title,
      'links': instance.links.map((e) => e.toJson()).toList(),
      'order': instance.order,
    };

WebsiteTheme _$WebsiteThemeFromJson(Map<String, dynamic> json) => WebsiteTheme(
      name: json['name'] as String,
      colors: ColorScheme.fromJson(json['colors'] as Map<String, dynamic>),
      typography:
          Typography.fromJson(json['typography'] as Map<String, dynamic>),
      spacing: Spacing.fromJson(json['spacing'] as Map<String, dynamic>),
      borderRadius:
          BorderRadius.fromJson(json['borderRadius'] as Map<String, dynamic>),
      shadows: Shadows.fromJson(json['shadows'] as Map<String, dynamic>),
      customCSS: json['customCSS'] as String? ?? '',
    );

Map<String, dynamic> _$WebsiteThemeToJson(WebsiteTheme instance) =>
    <String, dynamic>{
      'name': instance.name,
      'colors': instance.colors.toJson(),
      'typography': instance.typography.toJson(),
      'spacing': instance.spacing.toJson(),
      'borderRadius': instance.borderRadius.toJson(),
      'shadows': instance.shadows.toJson(),
      'customCSS': instance.customCSS,
    };

ColorScheme _$ColorSchemeFromJson(Map<String, dynamic> json) => ColorScheme(
      primary: json['primary'] as String,
      secondary: json['secondary'] as String,
      accent: json['accent'] as String,
      background: json['background'] as String,
      surface: json['surface'] as String,
      text: json['text'] as String,
      textSecondary: json['textSecondary'] as String,
      border: json['border'] as String,
      error: json['error'] as String,
      success: json['success'] as String,
      warning: json['warning'] as String,
      info: json['info'] as String,
    );

Map<String, dynamic> _$ColorSchemeToJson(ColorScheme instance) =>
    <String, dynamic>{
      'primary': instance.primary,
      'secondary': instance.secondary,
      'accent': instance.accent,
      'background': instance.background,
      'surface': instance.surface,
      'text': instance.text,
      'textSecondary': instance.textSecondary,
      'border': instance.border,
      'error': instance.error,
      'success': instance.success,
      'warning': instance.warning,
      'info': instance.info,
    };

Typography _$TypographyFromJson(Map<String, dynamic> json) => Typography(
      headingFont: json['headingFont'] as String,
      bodyFont: json['bodyFont'] as String,
      fontSizes: (json['fontSizes'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      fontWeights: Map<String, int>.from(json['fontWeights'] as Map),
      lineHeights: (json['lineHeights'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$TypographyToJson(Typography instance) =>
    <String, dynamic>{
      'headingFont': instance.headingFont,
      'bodyFont': instance.bodyFont,
      'fontSizes': instance.fontSizes,
      'fontWeights': instance.fontWeights,
      'lineHeights': instance.lineHeights,
    };

Spacing _$SpacingFromJson(Map<String, dynamic> json) => Spacing(
      xs: (json['xs'] as num).toDouble(),
      sm: (json['sm'] as num).toDouble(),
      md: (json['md'] as num).toDouble(),
      lg: (json['lg'] as num).toDouble(),
      xl: (json['xl'] as num).toDouble(),
    );

Map<String, dynamic> _$SpacingToJson(Spacing instance) => <String, dynamic>{
      'xs': instance.xs,
      'sm': instance.sm,
      'md': instance.md,
      'lg': instance.lg,
      'xl': instance.xl,
    };

BorderRadius _$BorderRadiusFromJson(Map<String, dynamic> json) => BorderRadius(
      sm: (json['sm'] as num).toDouble(),
      md: (json['md'] as num).toDouble(),
      lg: (json['lg'] as num).toDouble(),
      full: (json['full'] as num).toDouble(),
    );

Map<String, dynamic> _$BorderRadiusToJson(BorderRadius instance) =>
    <String, dynamic>{
      'sm': instance.sm,
      'md': instance.md,
      'lg': instance.lg,
      'full': instance.full,
    };

Shadows _$ShadowsFromJson(Map<String, dynamic> json) => Shadows(
      sm: json['sm'] as String,
      md: json['md'] as String,
      lg: json['lg'] as String,
      xl: json['xl'] as String,
    );

Map<String, dynamic> _$ShadowsToJson(Shadows instance) => <String, dynamic>{
      'sm': instance.sm,
      'md': instance.md,
      'lg': instance.lg,
      'xl': instance.xl,
    };

WebsitePage _$WebsitePageFromJson(Map<String, dynamic> json) => WebsitePage(
      id: json['id'] as String,
      websiteId: json['websiteId'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      type: $enumDecode(_$PageTypeEnumMap, json['type']),
      metaTitle: json['metaTitle'] as String? ?? '',
      metaDescription: json['metaDescription'] as String? ?? '',
      metaKeywords: (json['metaKeywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      layout: $enumDecode(_$LayoutTypeEnumMap, json['layout']),
      components: (json['components'] as List<dynamic>?)
              ?.map((e) => PageComponent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      settings: json['settings'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isPublished: json['isPublished'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WebsitePageToJson(WebsitePage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'websiteId': instance.websiteId,
      'title': instance.title,
      'slug': instance.slug,
      'type': _$PageTypeEnumMap[instance.type]!,
      'metaTitle': instance.metaTitle,
      'metaDescription': instance.metaDescription,
      'metaKeywords': instance.metaKeywords,
      'layout': _$LayoutTypeEnumMap[instance.layout]!,
      'components': instance.components.map((e) => e.toJson()).toList(),
      'settings': instance.settings,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isPublished': instance.isPublished,
      'order': instance.order,
    };

const _$PageTypeEnumMap = {
  PageType.homepage: 'homepage',
  PageType.about: 'about',
  PageType.agenda: 'agenda',
  PageType.speakers: 'speakers',
  PageType.sponsors: 'sponsors',
  PageType.venue: 'venue',
  PageType.registration: 'registration',
  PageType.contact: 'contact',
  PageType.custom: 'custom',
};

const _$LayoutTypeEnumMap = {
  LayoutType.single_column: 'single_column',
  LayoutType.two_column: 'two_column',
  LayoutType.three_column: 'three_column',
  LayoutType.sidebar_left: 'sidebar_left',
  LayoutType.sidebar_right: 'sidebar_right',
  LayoutType.grid: 'grid',
  LayoutType.full_width: 'full_width',
};

PageComponent _$PageComponentFromJson(Map<String, dynamic> json) =>
    PageComponent(
      id: json['id'] as String,
      type: $enumDecode(_$ComponentTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>? ?? const {},
      style: ComponentStyle.fromJson(json['style'] as Map<String, dynamic>),
      order: (json['order'] as num?)?.toInt() ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
    );

Map<String, dynamic> _$PageComponentToJson(PageComponent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ComponentTypeEnumMap[instance.type]!,
      'data': instance.data,
      'style': instance.style.toJson(),
      'order': instance.order,
      'isVisible': instance.isVisible,
    };

const _$ComponentTypeEnumMap = {
  ComponentType.hero: 'hero',
  ComponentType.text: 'text',
  ComponentType.image: 'image',
  ComponentType.gallery: 'gallery',
  ComponentType.speakers_grid: 'speakers_grid',
  ComponentType.agenda_schedule: 'agenda_schedule',
  ComponentType.sponsors_grid: 'sponsors_grid',
  ComponentType.registration_form: 'registration_form',
  ComponentType.contact_form: 'contact_form',
  ComponentType.map: 'map',
  ComponentType.video: 'video',
  ComponentType.countdown: 'countdown',
  ComponentType.testimonials: 'testimonials',
  ComponentType.faq: 'faq',
  ComponentType.social_media: 'social_media',
  ComponentType.custom_html: 'custom_html',
};

ComponentStyle _$ComponentStyleFromJson(Map<String, dynamic> json) =>
    ComponentStyle(
      padding: json['padding'] as Map<String, dynamic>? ?? const {},
      margin: json['margin'] as Map<String, dynamic>? ?? const {},
      backgroundColor: json['backgroundColor'] as String? ?? '',
      textColor: json['textColor'] as String? ?? '',
      borderColor: json['borderColor'] as String? ?? '',
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 0,
      shadow: json['shadow'] as String? ?? '',
      responsive: json['responsive'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ComponentStyleToJson(ComponentStyle instance) =>
    <String, dynamic>{
      'padding': instance.padding,
      'margin': instance.margin,
      'backgroundColor': instance.backgroundColor,
      'textColor': instance.textColor,
      'borderColor': instance.borderColor,
      'borderWidth': instance.borderWidth,
      'borderRadius': instance.borderRadius,
      'shadow': instance.shadow,
      'responsive': instance.responsive,
    };

WebsiteSEO _$WebsiteSEOFromJson(Map<String, dynamic> json) => WebsiteSEO(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      ogImage: json['ogImage'] as String? ?? '',
      ogTitle: json['ogTitle'] as String? ?? '',
      ogDescription: json['ogDescription'] as String? ?? '',
      twitterCard: json['twitterCard'] as String? ?? 'summary_large_image',
      twitterSite: json['twitterSite'] as String? ?? '',
      canonicalUrl: json['canonicalUrl'] as String? ?? '',
      structuredData: (json['structuredData'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      robots: (json['robots'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['index', 'follow'],
    );

Map<String, dynamic> _$WebsiteSEOToJson(WebsiteSEO instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'keywords': instance.keywords,
      'ogImage': instance.ogImage,
      'ogTitle': instance.ogTitle,
      'ogDescription': instance.ogDescription,
      'twitterCard': instance.twitterCard,
      'twitterSite': instance.twitterSite,
      'canonicalUrl': instance.canonicalUrl,
      'structuredData': instance.structuredData,
      'robots': instance.robots,
    };

WebsiteTemplate _$WebsiteTemplateFromJson(Map<String, dynamic> json) =>
    WebsiteTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      preview: json['preview'] as String,
      category: json['category'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      pages: (json['pages'] as List<dynamic>)
          .map((e) => WebsitePage.fromJson(e as Map<String, dynamic>))
          .toList(),
      theme: WebsiteTheme.fromJson(json['theme'] as Map<String, dynamic>),
      defaultSettings: WebsiteSettings.fromJson(
          json['defaultSettings'] as Map<String, dynamic>),
      isPremium: json['isPremium'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$WebsiteTemplateToJson(WebsiteTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'preview': instance.preview,
      'category': instance.category,
      'tags': instance.tags,
      'pages': instance.pages.map((e) => e.toJson()).toList(),
      'theme': instance.theme.toJson(),
      'defaultSettings': instance.defaultSettings.toJson(),
      'isPremium': instance.isPremium,
      'price': instance.price,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
    };
