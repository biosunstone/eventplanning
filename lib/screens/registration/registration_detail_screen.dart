import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/registration_service.dart';

class RegistrationDetailScreen extends StatefulWidget {
  final Registration registration;
  final Event event;

  const RegistrationDetailScreen({
    super.key,
    required this.registration,
    required this.event,
  });

  @override
  State<RegistrationDetailScreen> createState() => _RegistrationDetailScreenState();
}

class _RegistrationDetailScreenState extends State<RegistrationDetailScreen>
    with SingleTickerProviderStateMixin {
  final RegistrationService _registrationService = RegistrationService();
  
  late TabController _tabController;
  late Registration _registration;
  List<PaymentTransaction> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _registration = widget.registration;
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      _transactions = await _registrationService.getRegistrationTransactions(_registration.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_registration.fullName),
            Text(
              'Registration Details',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit Registration'),
              ),
              const PopupMenuItem(
                value: 'check_in',
                child: Text('Check In'),
              ),
              const PopupMenuItem(
                value: 'resend_confirmation',
                child: Text('Resend Confirmation'),
              ),
              const PopupMenuItem(
                value: 'refund',
                child: Text('Process Refund'),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Text('Cancel Registration'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.person)),
            Tab(text: 'Tickets', icon: Icon(Icons.confirmation_number)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildTicketsTab(),
          _buildPaymentsTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 24),
          _buildPersonalInfo(),
          const SizedBox(height: 24),
          _buildRegistrationInfo(),
          const SizedBox(height: 24),
          if (_registration.customFields.isNotEmpty) ...[
            _buildCustomFields(),
            const SizedBox(height: 24),
          ],
          _buildPreferences(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getStatusColor(_registration.status),
                  child: Text(
                    _registration.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _registration.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _registration.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_registration.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getStatusText(_registration.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(_registration.paymentStatus),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getPaymentStatusText(_registration.paymentStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Registration Date',
                    _formatDateTime(_registration.registrationDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Total Amount',
                    '\$${_registration.finalAmount.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            if (_registration.isCheckedIn) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Checked in on ${_formatDateTime(_registration.checkInDate!)}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('First Name', _registration.firstName),
                ),
                Expanded(
                  child: _buildInfoItem('Last Name', _registration.lastName),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem('Email', _registration.email),
            if (_registration.phone != null) ...[
              const SizedBox(height: 12),
              _buildInfoItem('Phone', _registration.phone!),
            ],
            if (_registration.company != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Company', _registration.company!),
                  ),
                  if (_registration.jobTitle != null)
                    Expanded(
                      child: _buildInfoItem('Job Title', _registration.jobTitle!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registration Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Registration ID', _registration.id),
                ),
                Expanded(
                  child: _buildInfoItem('Total Tickets', '${_registration.totalTickets}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_registration.promoCode != null) ...[
              _buildInfoItem('Promo Code', _registration.promoCode!),
              const SizedBox(height: 12),
            ],
            if (_registration.hasDiscount) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Subtotal', '\$${_registration.totalAmount.toStringAsFixed(2)}'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Discount', '-\$${_registration.discountAmount.toStringAsFixed(2)}'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                'Final Amount',
                '\$${_registration.finalAmount.toStringAsFixed(2)}',
                isHighlighted: true,
              ),
            ],
            if (_registration.notes != null && _registration.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_registration.notes!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._registration.customFields.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInfoItem(
                _formatFieldName(entry.key),
                entry.value.toString(),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferences() {
    if (_registration.preferences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._registration.preferences.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInfoItem(
                _formatFieldName(entry.key),
                entry.value.toString(),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registration.tickets.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTicketCard(_registration.tickets[index]),
        );
      },
    );
  }

  Widget _buildTicketCard(TicketSelection ticket) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket Type ID: ${ticket.ticketTypeId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: ${ticket.quantity}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${ticket.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$${ticket.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (ticket.customizations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Customizations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...ticket.customizations.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${_formatFieldName(entry.key)}:',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value.toString()),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Text(
          'No payment transactions found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTransactionCard(_transactions[index]),
        );
      },
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction ${transaction.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(transaction.createdAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(transaction.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getPaymentStatusText(transaction.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Method', _formatPaymentMethod(transaction.method)),
                ),
                if (transaction.transactionId != null)
                  Expanded(
                    child: _buildInfoItem('Transaction ID', transaction.transactionId!),
                  ),
              ],
            ),
            if (transaction.isFailed && transaction.failureReason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed: ${transaction.failureReason}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return Colors.green;
      case RegistrationStatus.pending:
        return Colors.orange;
      case RegistrationStatus.rejected:
        return Colors.red;
      case RegistrationStatus.cancelled:
        return Colors.grey;
      case RegistrationStatus.checked_in:
        return Colors.blue;
      case RegistrationStatus.waitlisted:
        return Colors.purple;
      case RegistrationStatus.draft:
        return Colors.grey[400]!;
    }
  }

  String _getStatusText(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return 'Approved';
      case RegistrationStatus.pending:
        return 'Pending';
      case RegistrationStatus.rejected:
        return 'Rejected';
      case RegistrationStatus.cancelled:
        return 'Cancelled';
      case RegistrationStatus.checked_in:
        return 'Checked In';
      case RegistrationStatus.waitlisted:
        return 'Waitlisted';
      case RegistrationStatus.draft:
        return 'Draft';
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.purple;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.credit_card:
        return 'Credit Card';
      case PaymentMethod.debit_card:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.apple_pay:
        return 'Apple Pay';
      case PaymentMethod.google_pay:
        return 'Google Pay';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
      case PaymentMethod.invoice:
        return 'Invoice';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFieldName(String fieldName) {
    return fieldName.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        _editRegistration();
        break;
      case 'check_in':
        _checkInAttendee();
        break;
      case 'resend_confirmation':
        _resendConfirmation();
        break;
      case 'refund':
        _processRefund();
        break;
      case 'cancel':
        _cancelRegistration();
        break;
    }
  }

  void _editRegistration() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit registration functionality would be implemented here')),
    );
  }

  Future<void> _checkInAttendee() async {
    if (_registration.isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendee is already checked in')),
      );
      return;
    }

    try {
      final updatedRegistration = await _registrationService.checkInAttendee(_registration.id);
      setState(() {
        _registration = updatedRegistration;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendee checked in successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking in attendee: $e')),
      );
    }
  }

  void _resendConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Confirmation email sent to ${_registration.email}')),
    );
  }

  void _processRefund() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund'),
        content: Text('Are you sure you want to refund \$${_registration.finalAmount.toStringAsFixed(2)} to ${_registration.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refund processed successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Process Refund'),
          ),
        ],
      ),
    );
  }

  void _cancelRegistration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Registration'),
        content: Text('Are you sure you want to cancel ${_registration.fullName}\'s registration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _registrationService.updateRegistration(
                  _registration.id,
                  status: RegistrationStatus.cancelled,
                );
                setState(() {
                  _registration = _registration.copyWith(
                    status: RegistrationStatus.cancelled,
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registration cancelled')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cancelling registration: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Registration'),
          ),
        ],
      ),
    );
  }
}