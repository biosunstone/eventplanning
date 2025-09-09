import 'dart:math';
import '../models/registration.dart';
import '../models/event.dart';

class RegistrationService {
  static final RegistrationService _instance = RegistrationService._internal();
  factory RegistrationService() => _instance;
  RegistrationService._internal();

  final List<Registration> _registrations = [];
  final List<TicketTypeConfig> _ticketTypes = [];
  final List<DiscountCode> _discountCodes = [];
  final List<PaymentTransaction> _transactions = [];
  final List<RegistrationForm> _forms = [];

  // Registration Management
  Future<List<Registration>> getEventRegistrations(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _registrations.where((reg) => reg.eventId == eventId).toList();
  }

  Future<Registration?> getRegistration(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _registrations.firstWhere((reg) => reg.id == registrationId);
    } catch (e) {
      return null;
    }
  }

  Future<Registration> createRegistration({
    required String eventId,
    required String attendeeId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? company,
    String? jobTitle,
    Map<String, dynamic> customFields = const {},
    List<TicketSelection> tickets = const [],
    List<String> sessionIds = const [],
    Map<String, dynamic> preferences = const {},
    String? promoCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Calculate pricing
    double totalAmount = 0;
    double discountAmount = 0;
    List<String> appliedDiscounts = [];

    // Calculate total from tickets
    for (final ticket in tickets) {
      totalAmount += ticket.totalPrice;
    }

    // Apply discount codes
    if (promoCode != null && promoCode.isNotEmpty) {
      final discount = await getDiscountCode(eventId, promoCode);
      if (discount != null && discount.isValid) {
        discountAmount = discount.calculateDiscount(totalAmount, tickets);
        if (discountAmount > 0) {
          appliedDiscounts.add(discount.id);
          // Update discount usage
          await _updateDiscountUsage(discount.id);
        }
      }
    }

    final registration = Registration(
      id: _generateId(),
      eventId: eventId,
      attendeeId: attendeeId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      company: company,
      jobTitle: jobTitle,
      customFields: customFields,
      tickets: tickets,
      sessionIds: sessionIds,
      preferences: preferences,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: totalAmount - discountAmount,
      promoCode: promoCode,
      appliedDiscounts: appliedDiscounts,
      registrationDate: DateTime.now(),
    );

    _registrations.add(registration);
    return registration;
  }

  Future<Registration> updateRegistration(String registrationId, {
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
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _registrations.indexWhere((reg) => reg.id == registrationId);
    if (index == -1) throw Exception('Registration not found');

    final registration = _registrations[index];
    final updatedRegistration = registration.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      company: company,
      jobTitle: jobTitle,
      customFields: customFields,
      tickets: tickets,
      sessionIds: sessionIds,
      preferences: preferences,
      status: status,
      paymentStatus: paymentStatus,
      notes: notes,
      metadata: metadata,
    );

    _registrations[index] = updatedRegistration;
    return updatedRegistration;
  }

  Future<void> deleteRegistration(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _registrations.removeWhere((reg) => reg.id == registrationId);
  }

  Future<Registration> checkInAttendee(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final registration = await updateRegistration(
      registrationId,
      status: RegistrationStatus.checked_in,
      metadata: {'checkInTime': DateTime.now().toIso8601String()},
    );

    return registration;
  }

  // Ticket Type Management
  Future<List<TicketTypeConfig>> getTicketTypes(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _ticketTypes.where((ticket) => ticket.eventId == eventId).toList();
  }

  Future<TicketTypeConfig> createTicketType({
    required String eventId,
    required String name,
    required String description,
    required TicketType type,
    required double price,
    String currency = 'USD',
    int? maxQuantity,
    int maxPerPerson = 1,
    required int totalAvailable,
    DateTime? saleStartDate,
    DateTime? saleEndDate,
    bool isActive = true,
    bool requiresApproval = false,
    List<String> availableFor = const [],
    Map<String, dynamic> customFields = const {},
    List<String> includedFeatures = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final ticketType = TicketTypeConfig(
      id: _generateId(),
      eventId: eventId,
      name: name,
      description: description,
      type: type,
      price: price,
      currency: currency,
      maxQuantity: maxQuantity,
      maxPerPerson: maxPerPerson,
      totalAvailable: totalAvailable,
      saleStartDate: saleStartDate,
      saleEndDate: saleEndDate,
      isActive: isActive,
      requiresApproval: requiresApproval,
      availableFor: availableFor,
      customFields: customFields,
      includedFeatures: includedFeatures,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    _ticketTypes.add(ticketType);
    return ticketType;
  }

  Future<TicketTypeConfig> updateTicketType(String ticketTypeId, {
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _ticketTypes.indexWhere((ticket) => ticket.id == ticketTypeId);
    if (index == -1) throw Exception('Ticket type not found');

    final ticketType = _ticketTypes[index];
    final updatedTicketType = ticketType.copyWith(
      name: name,
      description: description,
      type: type,
      price: price,
      currency: currency,
      maxQuantity: maxQuantity,
      maxPerPerson: maxPerPerson,
      totalAvailable: totalAvailable,
      sold: sold,
      saleStartDate: saleStartDate,
      saleEndDate: saleEndDate,
      isActive: isActive,
      requiresApproval: requiresApproval,
      availableFor: availableFor,
      customFields: customFields,
      includedFeatures: includedFeatures,
      metadata: metadata,
      updatedAt: DateTime.now(),
    );

    _ticketTypes[index] = updatedTicketType;
    return updatedTicketType;
  }

  // Discount Management
  Future<List<DiscountCode>> getDiscountCodes(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _discountCodes.where((discount) => discount.eventId == eventId).toList();
  }

  Future<DiscountCode?> getDiscountCode(String eventId, String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _discountCodes.firstWhere(
        (discount) => discount.eventId == eventId && discount.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<DiscountCode> createDiscountCode({
    required String eventId,
    required String code,
    required String name,
    required String description,
    required DiscountType type,
    required double value,
    double? minOrderValue,
    double? maxDiscountAmount,
    int? usageLimit,
    DateTime? validFrom,
    DateTime? validUntil,
    List<String> applicableTicketTypes = const [],
    bool isActive = true,
    bool isPublic = true,
    List<String> allowedUserIds = const [],
    Map<String, dynamic> conditions = const {},
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final discountCode = DiscountCode(
      id: _generateId(),
      eventId: eventId,
      code: code.toUpperCase(),
      name: name,
      description: description,
      type: type,
      value: value,
      minOrderValue: minOrderValue,
      maxDiscountAmount: maxDiscountAmount,
      usageLimit: usageLimit,
      validFrom: validFrom,
      validUntil: validUntil,
      applicableTicketTypes: applicableTicketTypes,
      isActive: isActive,
      isPublic: isPublic,
      allowedUserIds: allowedUserIds,
      conditions: conditions,
      createdAt: DateTime.now(),
    );

    _discountCodes.add(discountCode);
    return discountCode;
  }

  Future<void> _updateDiscountUsage(String discountId) async {
    final index = _discountCodes.indexWhere((discount) => discount.id == discountId);
    if (index != -1) {
      final discount = _discountCodes[index];
      _discountCodes[index] = discount.copyWith(
        usedCount: discount.usedCount + 1,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Payment Processing
  Future<PaymentTransaction> createPaymentTransaction({
    required String registrationId,
    required String eventId,
    required double amount,
    String currency = 'USD',
    required PaymentMethod method,
    Map<String, dynamic> paymentDetails = const {},
    Map<String, dynamic> metadata = const {},
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final transaction = PaymentTransaction(
      id: _generateId(),
      registrationId: registrationId,
      eventId: eventId,
      amount: amount,
      currency: currency,
      method: method,
      paymentDetails: paymentDetails,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    _transactions.add(transaction);
    return transaction;
  }

  Future<PaymentTransaction> processPayment(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 2000)); // Simulate processing

    final index = _transactions.indexWhere((tx) => tx.id == transactionId);
    if (index == -1) throw Exception('Transaction not found');

    final transaction = _transactions[index];
    
    // Simulate payment processing (90% success rate)
    final isSuccess = Random().nextDouble() > 0.1;
    
    final updatedTransaction = transaction.copyWith(
      status: isSuccess ? PaymentStatus.completed : PaymentStatus.failed,
      processedAt: DateTime.now(),
      failureReason: isSuccess ? null : 'Payment declined by bank',
      transactionId: isSuccess ? 'tx_${_generateId()}' : null,
    );

    _transactions[index] = updatedTransaction;

    // Update registration payment status
    if (isSuccess) {
      await updateRegistration(
        transaction.registrationId,
        paymentStatus: PaymentStatus.completed,
      );
    }

    return updatedTransaction;
  }

  Future<List<PaymentTransaction>> getRegistrationTransactions(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _transactions.where((tx) => tx.registrationId == registrationId).toList();
  }

  // Registration Form Management
  Future<List<RegistrationForm>> getRegistrationForms(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _forms.where((form) => form.eventId == eventId).toList();
  }

  Future<RegistrationForm> createRegistrationForm({
    required String eventId,
    required String name,
    required String description,
    bool isDefault = false,
    bool isActive = true,
    List<FormField> fields = const [],
    Map<String, dynamic> settings = const {},
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final form = RegistrationForm(
      id: _generateId(),
      eventId: eventId,
      name: name,
      description: description,
      isDefault: isDefault,
      isActive: isActive,
      fields: fields,
      settings: settings,
      createdAt: DateTime.now(),
    );

    _forms.add(form);
    return form;
  }

  // Analytics and Reporting
  Future<Map<String, dynamic>> getRegistrationAnalytics(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final eventRegistrations = await getEventRegistrations(eventId);
    final eventTicketTypes = await getTicketTypes(eventId);

    final totalRegistrations = eventRegistrations.length;
    final paidRegistrations = eventRegistrations.where((reg) => reg.isPaid).length;
    final checkedInCount = eventRegistrations.where((reg) => reg.isCheckedIn).length;

    final totalRevenue = eventRegistrations.fold<double>(
      0, (sum, reg) => sum + reg.finalAmount,
    );

    final averageOrderValue = totalRegistrations > 0 ? totalRevenue / totalRegistrations : 0.0;

    // Registration status breakdown
    final statusBreakdown = <String, int>{};
    for (final status in RegistrationStatus.values) {
      statusBreakdown[status.name] = eventRegistrations
          .where((reg) => reg.status == status).length;
    }

    // Payment method breakdown
    final paymentMethodBreakdown = <String, int>{};
    for (final reg in eventRegistrations) {
      final transactions = await getRegistrationTransactions(reg.id);
      for (final transaction in transactions.where((tx) => tx.isCompleted)) {
        final method = transaction.method.name;
        paymentMethodBreakdown[method] = (paymentMethodBreakdown[method] ?? 0) + 1;
      }
    }

    // Ticket type sales
    final ticketTypeSales = <String, Map<String, dynamic>>{};
    for (final ticketType in eventTicketTypes) {
      final sold = eventRegistrations.fold<int>(0, (sum, reg) {
        return sum + reg.tickets
            .where((ticket) => ticket.ticketTypeId == ticketType.id)
            .fold<int>(0, (ticketSum, ticket) => ticketSum + ticket.quantity);
      });
      
      ticketTypeSales[ticketType.name] = {
        'sold': sold,
        'available': ticketType.totalAvailable,
        'revenue': sold * ticketType.price,
      };
    }

    return {
      'totalRegistrations': totalRegistrations,
      'paidRegistrations': paidRegistrations,
      'checkedInCount': checkedInCount,
      'checkedInRate': totalRegistrations > 0 ? checkedInCount / totalRegistrations : 0.0,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'statusBreakdown': statusBreakdown,
      'paymentMethodBreakdown': paymentMethodBreakdown,
      'ticketTypeSales': ticketTypeSales,
      'registrationTrend': _generateRegistrationTrend(eventRegistrations),
    };
  }

  List<Map<String, dynamic>> _generateRegistrationTrend(List<Registration> registrations) {
    final trend = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.month}/${date.day}';
      
      final count = registrations.where((reg) {
        final regDate = reg.registrationDate;
        return regDate.year == date.year &&
               regDate.month == date.month &&
               regDate.day == date.day;
      }).length;
      
      trend.add({
        'date': dateStr,
        'registrations': count,
      });
    }
    
    return trend;
  }

  // Demo data generation
  Future<void> generateDemoData(String eventId) async {
    if (_ticketTypes.any((ticket) => ticket.eventId == eventId)) return;

    // Create demo ticket types
    await createTicketType(
      eventId: eventId,
      name: 'Early Bird',
      description: 'Limited time early bird pricing',
      type: TicketType.early_bird,
      price: 99.00,
      totalAvailable: 100,
      saleEndDate: DateTime.now().add(const Duration(days: 30)),
      includedFeatures: ['Welcome package', 'All sessions', 'Lunch included'],
    );

    await createTicketType(
      eventId: eventId,
      name: 'General Admission',
      description: 'Standard event access',
      type: TicketType.general,
      price: 149.00,
      totalAvailable: 500,
      includedFeatures: ['All sessions', 'Lunch included', 'Networking events'],
    );

    await createTicketType(
      eventId: eventId,
      name: 'VIP Experience',
      description: 'Premium access with exclusive perks',
      type: TicketType.vip,
      price: 299.00,
      totalAvailable: 50,
      includedFeatures: [
        'VIP seating',
        'Meet & greet with speakers',
        'Premium lunch',
        'Welcome gift bag',
        'Exclusive networking session'
      ],
    );

    await createTicketType(
      eventId: eventId,
      name: 'Student',
      description: 'Discounted rate for students',
      type: TicketType.student,
      price: 49.00,
      totalAvailable: 100,
      requiresApproval: true,
      includedFeatures: ['All sessions', 'Lunch included'],
    );

    // Create demo discount codes
    await createDiscountCode(
      eventId: eventId,
      code: 'WELCOME2024',
      name: 'Welcome Discount',
      description: '10% off for new attendees',
      type: DiscountType.percentage,
      value: 10.0,
      usageLimit: 100,
      validUntil: DateTime.now().add(const Duration(days: 60)),
    );

    await createDiscountCode(
      eventId: eventId,
      code: 'GROUP5',
      name: 'Group Discount',
      description: '\$50 off for groups of 5 or more',
      type: DiscountType.fixed_amount,
      value: 50.0,
      minOrderValue: 500.0,
      conditions: {'minimumQuantity': 5},
    );

    // Create demo registration form
    await createRegistrationForm(
      eventId: eventId,
      name: 'Standard Registration',
      description: 'Default registration form for the event',
      isDefault: true,
      fields: [
        const FormField(
          id: 'dietary_restrictions',
          name: 'dietary_restrictions',
          label: 'Dietary Restrictions',
          type: 'select',
          options: ['None', 'Vegetarian', 'Vegan', 'Gluten-free', 'Other'],
          order: 1,
        ),
        const FormField(
          id: 'company_size',
          name: 'company_size',
          label: 'Company Size',
          type: 'select',
          options: ['1-10', '11-50', '51-200', '201-1000', '1000+'],
          order: 2,
        ),
        const FormField(
          id: 'experience_level',
          name: 'experience_level',
          label: 'Experience Level',
          type: 'radio',
          options: ['Beginner', 'Intermediate', 'Advanced'],
          isRequired: true,
          order: 3,
        ),
        const FormField(
          id: 'interests',
          name: 'interests',
          label: 'Areas of Interest',
          type: 'checkbox',
          options: ['AI/ML', 'Web Development', 'Mobile', 'DevOps', 'Design'],
          order: 4,
        ),
      ],
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString().padLeft(3, '0');
  }
}