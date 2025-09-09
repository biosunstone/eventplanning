// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Registration _$RegistrationFromJson(Map<String, dynamic> json) => Registration(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      attendeeId: json['attendeeId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      jobTitle: json['jobTitle'] as String?,
      customFields: json['customFields'] as Map<String, dynamic>? ?? const {},
      tickets: (json['tickets'] as List<dynamic>?)
              ?.map((e) => TicketSelection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sessionIds: (json['sessionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
      status:
          $enumDecodeNullable(_$RegistrationStatusEnumMap, json['status']) ??
              RegistrationStatus.pending,
      paymentStatus:
          $enumDecodeNullable(_$PaymentStatusEnumMap, json['paymentStatus']) ??
              PaymentStatus.pending,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      promoCode: json['promoCode'] as String?,
      appliedDiscounts: (json['appliedDiscounts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      approvalDate: json['approvalDate'] == null
          ? null
          : DateTime.parse(json['approvalDate'] as String),
      checkInDate: json['checkInDate'] == null
          ? null
          : DateTime.parse(json['checkInDate'] as String),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$RegistrationToJson(Registration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'attendeeId': instance.attendeeId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'company': instance.company,
      'jobTitle': instance.jobTitle,
      'customFields': instance.customFields,
      'tickets': instance.tickets.map((e) => e.toJson()).toList(),
      'sessionIds': instance.sessionIds,
      'preferences': instance.preferences,
      'status': _$RegistrationStatusEnumMap[instance.status]!,
      'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus]!,
      'totalAmount': instance.totalAmount,
      'discountAmount': instance.discountAmount,
      'finalAmount': instance.finalAmount,
      'promoCode': instance.promoCode,
      'appliedDiscounts': instance.appliedDiscounts,
      'registrationDate': instance.registrationDate.toIso8601String(),
      'approvalDate': instance.approvalDate?.toIso8601String(),
      'checkInDate': instance.checkInDate?.toIso8601String(),
      'notes': instance.notes,
      'metadata': instance.metadata,
    };

const _$RegistrationStatusEnumMap = {
  RegistrationStatus.draft: 'draft',
  RegistrationStatus.pending: 'pending',
  RegistrationStatus.approved: 'approved',
  RegistrationStatus.rejected: 'rejected',
  RegistrationStatus.cancelled: 'cancelled',
  RegistrationStatus.waitlisted: 'waitlisted',
  RegistrationStatus.checked_in: 'checked_in',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.processing: 'processing',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
  PaymentStatus.cancelled: 'cancelled',
};

TicketSelection _$TicketSelectionFromJson(Map<String, dynamic> json) =>
    TicketSelection(
      ticketTypeId: json['ticketTypeId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      customizations:
          json['customizations'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TicketSelectionToJson(TicketSelection instance) =>
    <String, dynamic>{
      'ticketTypeId': instance.ticketTypeId,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'totalPrice': instance.totalPrice,
      'customizations': instance.customizations,
    };

TicketTypeConfig _$TicketTypeConfigFromJson(Map<String, dynamic> json) =>
    TicketTypeConfig(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$TicketTypeEnumMap, json['type']),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      maxQuantity: (json['maxQuantity'] as num?)?.toInt(),
      maxPerPerson: (json['maxPerPerson'] as num?)?.toInt() ?? 1,
      totalAvailable: (json['totalAvailable'] as num).toInt(),
      sold: (json['sold'] as num?)?.toInt() ?? 0,
      saleStartDate: json['saleStartDate'] == null
          ? null
          : DateTime.parse(json['saleStartDate'] as String),
      saleEndDate: json['saleEndDate'] == null
          ? null
          : DateTime.parse(json['saleEndDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      availableFor: (json['availableFor'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      customFields: json['customFields'] as Map<String, dynamic>? ?? const {},
      includedFeatures: (json['includedFeatures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TicketTypeConfigToJson(TicketTypeConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'name': instance.name,
      'description': instance.description,
      'type': _$TicketTypeEnumMap[instance.type]!,
      'price': instance.price,
      'currency': instance.currency,
      'maxQuantity': instance.maxQuantity,
      'maxPerPerson': instance.maxPerPerson,
      'totalAvailable': instance.totalAvailable,
      'sold': instance.sold,
      'saleStartDate': instance.saleStartDate?.toIso8601String(),
      'saleEndDate': instance.saleEndDate?.toIso8601String(),
      'isActive': instance.isActive,
      'requiresApproval': instance.requiresApproval,
      'availableFor': instance.availableFor,
      'customFields': instance.customFields,
      'includedFeatures': instance.includedFeatures,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$TicketTypeEnumMap = {
  TicketType.general: 'general',
  TicketType.vip: 'vip',
  TicketType.early_bird: 'early_bird',
  TicketType.student: 'student',
  TicketType.group: 'group',
  TicketType.speaker: 'speaker',
  TicketType.sponsor: 'sponsor',
  TicketType.press: 'press',
  TicketType.free: 'free',
  TicketType.premium: 'premium',
};

DiscountCode _$DiscountCodeFromJson(Map<String, dynamic> json) => DiscountCode(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$DiscountTypeEnumMap, json['type']),
      value: (json['value'] as num).toDouble(),
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
      usageLimit: (json['usageLimit'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      validFrom: json['validFrom'] == null
          ? null
          : DateTime.parse(json['validFrom'] as String),
      validUntil: json['validUntil'] == null
          ? null
          : DateTime.parse(json['validUntil'] as String),
      applicableTicketTypes: (json['applicableTicketTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? true,
      isPublic: json['isPublic'] as bool? ?? true,
      allowedUserIds: (json['allowedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      conditions: json['conditions'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DiscountCodeToJson(DiscountCode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'type': _$DiscountTypeEnumMap[instance.type]!,
      'value': instance.value,
      'minOrderValue': instance.minOrderValue,
      'maxDiscountAmount': instance.maxDiscountAmount,
      'usageLimit': instance.usageLimit,
      'usedCount': instance.usedCount,
      'validFrom': instance.validFrom?.toIso8601String(),
      'validUntil': instance.validUntil?.toIso8601String(),
      'applicableTicketTypes': instance.applicableTicketTypes,
      'isActive': instance.isActive,
      'isPublic': instance.isPublic,
      'allowedUserIds': instance.allowedUserIds,
      'conditions': instance.conditions,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$DiscountTypeEnumMap = {
  DiscountType.percentage: 'percentage',
  DiscountType.fixed_amount: 'fixed_amount',
  DiscountType.buy_one_get_one: 'buy_one_get_one',
  DiscountType.group_discount: 'group_discount',
  DiscountType.early_bird: 'early_bird',
};

PaymentTransaction _$PaymentTransactionFromJson(Map<String, dynamic> json) =>
    PaymentTransaction(
      id: json['id'] as String,
      registrationId: json['registrationId'] as String,
      eventId: json['eventId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
      status: $enumDecodeNullable(_$PaymentStatusEnumMap, json['status']) ??
          PaymentStatus.pending,
      paymentIntentId: json['paymentIntentId'] as String?,
      transactionId: json['transactionId'] as String?,
      paymentDetails:
          json['paymentDetails'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      failureReason: json['failureReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$PaymentTransactionToJson(PaymentTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'registrationId': instance.registrationId,
      'eventId': instance.eventId,
      'amount': instance.amount,
      'currency': instance.currency,
      'method': _$PaymentMethodEnumMap[instance.method]!,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'paymentIntentId': instance.paymentIntentId,
      'transactionId': instance.transactionId,
      'paymentDetails': instance.paymentDetails,
      'createdAt': instance.createdAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
      'failureReason': instance.failureReason,
      'metadata': instance.metadata,
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.credit_card: 'credit_card',
  PaymentMethod.debit_card: 'debit_card',
  PaymentMethod.paypal: 'paypal',
  PaymentMethod.stripe: 'stripe',
  PaymentMethod.apple_pay: 'apple_pay',
  PaymentMethod.google_pay: 'google_pay',
  PaymentMethod.bank_transfer: 'bank_transfer',
  PaymentMethod.invoice: 'invoice',
};

RegistrationForm _$RegistrationFormFromJson(Map<String, dynamic> json) =>
    RegistrationForm(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => FormField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      settings: json['settings'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RegistrationFormToJson(RegistrationForm instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'name': instance.name,
      'description': instance.description,
      'isDefault': instance.isDefault,
      'isActive': instance.isActive,
      'fields': instance.fields.map((e) => e.toJson()).toList(),
      'settings': instance.settings,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

FormField _$FormFieldFromJson(Map<String, dynamic> json) => FormField(
      id: json['id'] as String,
      name: json['name'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      isRequired: json['isRequired'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      helpText: json['helpText'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      validation: json['validation'] as Map<String, dynamic>? ?? const {},
      order: (json['order'] as num?)?.toInt() ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      conditionalOn: (json['conditionalOn'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$FormFieldToJson(FormField instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'label': instance.label,
      'type': instance.type,
      'isRequired': instance.isRequired,
      'placeholder': instance.placeholder,
      'helpText': instance.helpText,
      'options': instance.options,
      'validation': instance.validation,
      'order': instance.order,
      'isVisible': instance.isVisible,
      'conditionalOn': instance.conditionalOn,
    };
