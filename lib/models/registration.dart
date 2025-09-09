import 'package:json_annotation/json_annotation.dart';

part 'registration.g.dart';

enum RegistrationStatus {
  draft,
  pending,
  approved,
  rejected,
  cancelled,
  waitlisted,
  checked_in,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

enum TicketType {
  general,
  vip,
  early_bird,
  student,
  group,
  speaker,
  sponsor,
  press,
  free,
  premium,
}

enum DiscountType {
  percentage,
  fixed_amount,
  buy_one_get_one,
  group_discount,
  early_bird,
}

enum PaymentMethod {
  credit_card,
  debit_card,
  paypal,
  stripe,
  apple_pay,
  google_pay,
  bank_transfer,
  invoice,
}

@JsonSerializable(explicitToJson: true)
class Registration {
  final String id;
  final String eventId;
  final String attendeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? company;
  final String? jobTitle;
  final Map<String, dynamic> customFields;
  final List<TicketSelection> tickets;
  final List<String> sessionIds;
  final Map<String, dynamic> preferences;
  final RegistrationStatus status;
  final PaymentStatus paymentStatus;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? promoCode;
  final List<String> appliedDiscounts;
  final DateTime registrationDate;
  final DateTime? approvalDate;
  final DateTime? checkInDate;
  final String? notes;
  final Map<String, dynamic> metadata;

  const Registration({
    required this.id,
    required this.eventId,
    required this.attendeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.company,
    this.jobTitle,
    this.customFields = const {},
    this.tickets = const [],
    this.sessionIds = const [],
    this.preferences = const {},
    this.status = RegistrationStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    this.finalAmount = 0.0,
    this.promoCode,
    this.appliedDiscounts = const [],
    required this.registrationDate,
    this.approvalDate,
    this.checkInDate,
    this.notes,
    this.metadata = const {},
  });

  factory Registration.fromJson(Map<String, dynamic> json) => _$RegistrationFromJson(json);
  Map<String, dynamic> toJson() => _$RegistrationToJson(this);

  Registration copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    Map<String, dynamic>? customFields,
    List<TicketSelection>? tickets,
    List<String>? sessionIds,
    Map<String, dynamic>? preferences,
    RegistrationStatus? status,
    PaymentStatus? paymentStatus,
    double? totalAmount,
    double? discountAmount,
    double? finalAmount,
    String? promoCode,
    List<String>? appliedDiscounts,
    DateTime? approvalDate,
    DateTime? checkInDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Registration(
      id: id,
      eventId: eventId,
      attendeeId: attendeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      customFields: customFields ?? this.customFields,
      tickets: tickets ?? this.tickets,
      sessionIds: sessionIds ?? this.sessionIds,
      preferences: preferences ?? this.preferences,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      promoCode: promoCode ?? this.promoCode,
      appliedDiscounts: appliedDiscounts ?? this.appliedDiscounts,
      registrationDate: registrationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      checkInDate: checkInDate ?? this.checkInDate,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isApproved => status == RegistrationStatus.approved;
  bool get isPaid => paymentStatus == PaymentStatus.completed;
  bool get isCheckedIn => status == RegistrationStatus.checked_in;
  bool get hasDiscount => discountAmount > 0;
  int get totalTickets => tickets.fold(0, (sum, ticket) => sum + ticket.quantity);
}

@JsonSerializable(explicitToJson: true)
class TicketSelection {
  final String ticketTypeId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic> customizations;

  const TicketSelection({
    required this.ticketTypeId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.customizations = const {},
  });

  factory TicketSelection.fromJson(Map<String, dynamic> json) => _$TicketSelectionFromJson(json);
  Map<String, dynamic> toJson() => _$TicketSelectionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TicketTypeConfig {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final TicketType type;
  final double price;
  final String currency;
  final int? maxQuantity;
  final int? maxPerPerson;
  final int totalAvailable;
  final int sold;
  final DateTime? saleStartDate;
  final DateTime? saleEndDate;
  final bool isActive;
  final bool requiresApproval;
  final List<String> availableFor; // user roles that can purchase
  final Map<String, dynamic> customFields;
  final List<String> includedFeatures;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TicketTypeConfig({
    required this.id,
    required this.eventId,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
    this.currency = 'USD',
    this.maxQuantity,
    this.maxPerPerson = 1,
    required this.totalAvailable,
    this.sold = 0,
    this.saleStartDate,
    this.saleEndDate,
    this.isActive = true,
    this.requiresApproval = false,
    this.availableFor = const [],
    this.customFields = const {},
    this.includedFeatures = const [],
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory TicketTypeConfig.fromJson(Map<String, dynamic> json) => _$TicketTypeConfigFromJson(json);
  Map<String, dynamic> toJson() => _$TicketTypeConfigToJson(this);

  TicketTypeConfig copyWith({
    String? name,
    String? description,
    TicketType? type,
    double? price,
    String? currency,
    int? maxQuantity,
    int? maxPerPerson,
    int? totalAvailable,
    int? sold,
    DateTime? saleStartDate,
    DateTime? saleEndDate,
    bool? isActive,
    bool? requiresApproval,
    List<String>? availableFor,
    Map<String, dynamic>? customFields,
    List<String>? includedFeatures,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return TicketTypeConfig(
      id: id,
      eventId: eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      maxPerPerson: maxPerPerson ?? this.maxPerPerson,
      totalAvailable: totalAvailable ?? this.totalAvailable,
      sold: sold ?? this.sold,
      saleStartDate: saleStartDate ?? this.saleStartDate,
      saleEndDate: saleEndDate ?? this.saleEndDate,
      isActive: isActive ?? this.isActive,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      availableFor: availableFor ?? this.availableFor,
      customFields: customFields ?? this.customFields,
      includedFeatures: includedFeatures ?? this.includedFeatures,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isAvailable {
    if (!isActive) return false;
    if (sold >= totalAvailable) return false;
    
    final now = DateTime.now();
    if (saleStartDate != null && now.isBefore(saleStartDate!)) return false;
    if (saleEndDate != null && now.isAfter(saleEndDate!)) return false;
    
    return true;
  }

  int get remaining => totalAvailable - sold;
  double get soldPercentage => totalAvailable > 0 ? (sold / totalAvailable) * 100 : 0.0;
  bool get isSoldOut => sold >= totalAvailable;
  bool get isEarlyBird => type == TicketType.early_bird;
  bool get isFree => price == 0.0;
}

@JsonSerializable(explicitToJson: true)
class DiscountCode {
  final String id;
  final String eventId;
  final String code;
  final String name;
  final String description;
  final DiscountType type;
  final double value; // percentage (0-100) or fixed amount
  final double? minOrderValue;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final List<String> applicableTicketTypes;
  final bool isActive;
  final bool isPublic; // can be found/searched by users
  final List<String> allowedUserIds; // specific users who can use this code
  final Map<String, dynamic> conditions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DiscountCode({
    required this.id,
    required this.eventId,
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usedCount = 0,
    this.validFrom,
    this.validUntil,
    this.applicableTicketTypes = const [],
    this.isActive = true,
    this.isPublic = true,
    this.allowedUserIds = const [],
    this.conditions = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory DiscountCode.fromJson(Map<String, dynamic> json) => _$DiscountCodeFromJson(json);
  Map<String, dynamic> toJson() => _$DiscountCodeToJson(this);

  DiscountCode copyWith({
    String? code,
    String? name,
    String? description,
    DiscountType? type,
    double? value,
    double? minOrderValue,
    double? maxDiscountAmount,
    int? usageLimit,
    int? usedCount,
    DateTime? validFrom,
    DateTime? validUntil,
    List<String>? applicableTicketTypes,
    bool? isActive,
    bool? isPublic,
    List<String>? allowedUserIds,
    Map<String, dynamic>? conditions,
    DateTime? updatedAt,
  }) {
    return DiscountCode(
      id: id,
      eventId: eventId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      applicableTicketTypes: applicableTicketTypes ?? this.applicableTicketTypes,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      conditions: conditions ?? this.conditions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    
    if (usageLimit != null && usedCount >= usageLimit!) return false;
    
    return true;
  }

  double calculateDiscount(double orderValue, List<TicketSelection> tickets) {
    if (!isValid) return 0.0;
    
    // Check minimum order value
    if (minOrderValue != null && orderValue < minOrderValue!) return 0.0;
    
    double discountAmount = 0.0;
    
    switch (type) {
      case DiscountType.percentage:
        discountAmount = orderValue * (value / 100);
        break;
      case DiscountType.fixed_amount:
        discountAmount = value;
        break;
      case DiscountType.buy_one_get_one:
        // Implementation would depend on specific ticket logic
        discountAmount = 0.0;
        break;
      case DiscountType.group_discount:
        // Implementation would depend on group size conditions
        discountAmount = 0.0;
        break;
      case DiscountType.early_bird:
        discountAmount = orderValue * (value / 100);
        break;
    }
    
    // Apply maximum discount limit
    if (maxDiscountAmount != null && discountAmount > maxDiscountAmount!) {
      discountAmount = maxDiscountAmount!;
    }
    
    // Ensure discount doesn't exceed order value
    if (discountAmount > orderValue) {
      discountAmount = orderValue;
    }
    
    return discountAmount;
  }

  int get remainingUses => usageLimit != null ? (usageLimit! - usedCount) : -1;
  bool get hasUsageLimit => usageLimit != null;
  bool get isExpired => validUntil != null && DateTime.now().isAfter(validUntil!);
  bool get isNotYetValid => validFrom != null && DateTime.now().isBefore(validFrom!);
}

@JsonSerializable(explicitToJson: true)
class PaymentTransaction {
  final String id;
  final String registrationId;
  final String eventId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? paymentIntentId; // Stripe payment intent ID
  final String? transactionId; // Payment processor transaction ID
  final Map<String, dynamic> paymentDetails;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? failureReason;
  final Map<String, dynamic> metadata;

  const PaymentTransaction({
    required this.id,
    required this.registrationId,
    required this.eventId,
    required this.amount,
    this.currency = 'USD',
    required this.method,
    this.status = PaymentStatus.pending,
    this.paymentIntentId,
    this.transactionId,
    this.paymentDetails = const {},
    required this.createdAt,
    this.processedAt,
    this.failureReason,
    this.metadata = const {},
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => _$PaymentTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentTransactionToJson(this);

  PaymentTransaction copyWith({
    PaymentStatus? status,
    String? paymentIntentId,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
    DateTime? processedAt,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransaction(
      id: id,
      registrationId: registrationId,
      eventId: eventId,
      amount: amount,
      currency: currency,
      method: method,
      status: status ?? this.status,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      transactionId: transactionId ?? this.transactionId,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isRefunded => status == PaymentStatus.refunded;
  bool get isPending => status == PaymentStatus.pending;
  bool get isProcessing => status == PaymentStatus.processing;
}

@JsonSerializable(explicitToJson: true)
class RegistrationForm {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final bool isDefault;
  final bool isActive;
  final List<FormField> fields;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RegistrationForm({
    required this.id,
    required this.eventId,
    required this.name,
    required this.description,
    this.isDefault = false,
    this.isActive = true,
    this.fields = const [],
    this.settings = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory RegistrationForm.fromJson(Map<String, dynamic> json) => _$RegistrationFormFromJson(json);
  Map<String, dynamic> toJson() => _$RegistrationFormToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FormField {
  final String id;
  final String name;
  final String label;
  final String type; // text, email, phone, select, checkbox, radio, textarea, file, date
  final bool isRequired;
  final String? placeholder;
  final String? helpText;
  final List<String> options; // for select, radio, checkbox fields
  final Map<String, dynamic> validation;
  final int order;
  final bool isVisible;
  final List<String> conditionalOn; // field IDs that control visibility

  const FormField({
    required this.id,
    required this.name,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.placeholder,
    this.helpText,
    this.options = const [],
    this.validation = const {},
    this.order = 0,
    this.isVisible = true,
    this.conditionalOn = const [],
  });

  factory FormField.fromJson(Map<String, dynamic> json) => _$FormFieldFromJson(json);
  Map<String, dynamic> toJson() => _$FormFieldToJson(this);

  bool get hasOptions => options.isNotEmpty;
  bool get isConditional => conditionalOn.isNotEmpty;
}