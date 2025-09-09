import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/registration_service.dart';

class DiscountCodeScreen extends StatefulWidget {
  final Event event;

  const DiscountCodeScreen({super.key, required this.event});

  @override
  State<DiscountCodeScreen> createState() => _DiscountCodeScreenState();
}

class _DiscountCodeScreenState extends State<DiscountCodeScreen>
    with SingleTickerProviderStateMixin {
  final RegistrationService _registrationService = RegistrationService();
  
  late TabController _tabController;
  List<DiscountCode> _discountCodes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDiscountCodes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscountCodes() async {
    setState(() => _isLoading = true);
    
    try {
      _discountCodes = await _registrationService.getDiscountCodes(widget.event.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading discount codes: $e')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Codes'),
        actions: [
          IconButton(
            onPressed: _loadDiscountCodes,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Discount Codes', icon: Icon(Icons.local_offer)),
            Tab(text: 'Create New', icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscountCodesTab(),
          _buildCreateDiscountTab(),
        ],
      ),
    );
  }

  Widget _buildDiscountCodesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_discountCodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No discount codes yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first discount code to boost sales',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _discountCodes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDiscountCodeCard(_discountCodes[index]),
        );
      },
    );
  }

  Widget _buildDiscountCodeCard(DiscountCode discountCode) {
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              discountCode.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: discountCode.isActive ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              discountCode.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        discountCode.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        discountCode.description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getDiscountValueText(discountCode),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDiscountTypeText(discountCode.type),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDiscountStat(
                    'Used',
                    '${discountCode.usedCount}${discountCode.hasUsageLimit ? ' / ${discountCode.usageLimit}' : ''}',
                  ),
                ),
                Expanded(
                  child: _buildDiscountStat(
                    'Remaining',
                    discountCode.hasUsageLimit 
                        ? '${discountCode.remainingUses}' 
                        : 'Unlimited',
                  ),
                ),
                Expanded(
                  child: _buildDiscountStat(
                    'Valid Until',
                    discountCode.validUntil != null 
                        ? _formatDate(discountCode.validUntil!) 
                        : 'No expiry',
                  ),
                ),
              ],
            ),
            if (discountCode.minOrderValue != null || discountCode.maxDiscountAmount != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (discountCode.minOrderValue != null)
                    Expanded(
                      child: _buildDiscountStat(
                        'Min Order',
                        '\$${discountCode.minOrderValue!.toStringAsFixed(2)}',
                      ),
                    ),
                  if (discountCode.maxDiscountAmount != null)
                    Expanded(
                      child: _buildDiscountStat(
                        'Max Discount',
                        '\$${discountCode.maxDiscountAmount!.toStringAsFixed(2)}',
                      ),
                    ),
                ],
              ),
            ],
            if (!discountCode.isValid) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getInvalidReason(discountCode),
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
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

  Widget _buildDiscountStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateDiscountTab() {
    return const _CreateDiscountCodeForm();
  }

  String _getDiscountValueText(DiscountCode discount) {
    switch (discount.type) {
      case DiscountType.percentage:
        return '${discount.value.toStringAsFixed(0)}%';
      case DiscountType.fixed_amount:
        return '\$${discount.value.toStringAsFixed(0)}';
      case DiscountType.buy_one_get_one:
        return 'BOGO';
      case DiscountType.group_discount:
        return 'Group';
      case DiscountType.early_bird:
        return '${discount.value.toStringAsFixed(0)}%';
    }
  }

  String _getDiscountTypeText(DiscountType type) {
    switch (type) {
      case DiscountType.percentage:
        return 'Percentage';
      case DiscountType.fixed_amount:
        return 'Fixed Amount';
      case DiscountType.buy_one_get_one:
        return 'Buy One Get One';
      case DiscountType.group_discount:
        return 'Group Discount';
      case DiscountType.early_bird:
        return 'Early Bird';
    }
  }

  String _getInvalidReason(DiscountCode discount) {
    if (!discount.isActive) return 'Discount code is inactive';
    if (discount.isExpired) return 'Discount code has expired';
    if (discount.isNotYetValid) return 'Discount code is not yet valid';
    if (discount.hasUsageLimit && discount.usedCount >= discount.usageLimit!) {
      return 'Usage limit reached';
    }
    return 'Discount code is invalid';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _CreateDiscountCodeForm extends StatefulWidget {
  const _CreateDiscountCodeForm();

  @override
  State<_CreateDiscountCodeForm> createState() => _CreateDiscountCodeFormState();
}

class _CreateDiscountCodeFormState extends State<_CreateDiscountCodeForm> {
  final RegistrationService _registrationService = RegistrationService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _minOrderController = TextEditingController();
  final TextEditingController _maxDiscountController = TextEditingController();
  final TextEditingController _usageLimitController = TextEditingController();
  
  DiscountType _selectedType = DiscountType.percentage;
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _isActive = true;
  bool _isPublic = true;
  bool _hasUsageLimit = false;
  bool _hasMinOrder = false;
  bool _hasMaxDiscount = false;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBasicInfo(),
          const SizedBox(height: 24),
          _buildDiscountSettings(),
          const SizedBox(height: 24),
          _buildValiditySettings(),
          const SizedBox(height: 24),
          _buildAdvancedSettings(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _createDiscountCode,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Create Discount Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Discount Code',
                hintText: 'e.g., SAVE20, EARLYBIRD',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a discount code';
                }
                if (value.length < 3) {
                  return 'Code must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Display name for the discount',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of the discount',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discount Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DiscountType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Discount Type',
                border: OutlineInputBorder(),
              ),
              items: DiscountType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getDiscountTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: _getValueLabel(),
                border: const OutlineInputBorder(),
                prefixText: _selectedType == DiscountType.fixed_amount ? '\$' : null,
                suffixText: _selectedType == DiscountType.percentage || _selectedType == DiscountType.early_bird ? '%' : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                final numValue = double.tryParse(value);
                if (numValue == null || numValue <= 0) {
                  return 'Please enter a valid value';
                }
                if ((_selectedType == DiscountType.percentage || _selectedType == DiscountType.early_bird) && numValue > 100) {
                  return 'Percentage cannot exceed 100%';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValiditySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Validity Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Valid From'),
              subtitle: Text(_validFrom != null 
                  ? _formatDate(_validFrom!) 
                  : 'Valid immediately'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(true),
            ),
            const Divider(),
            ListTile(
              title: const Text('Valid Until'),
              subtitle: Text(_validUntil != null 
                  ? _formatDate(_validUntil!) 
                  : 'No expiry date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Usage Limit'),
              subtitle: const Text('Limit how many times this code can be used'),
              value: _hasUsageLimit,
              onChanged: (value) {
                setState(() {
                  _hasUsageLimit = value;
                  if (!value) {
                    _usageLimitController.clear();
                  }
                });
              },
            ),
            if (_hasUsageLimit) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _usageLimitController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Uses',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: _hasUsageLimit ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter usage limit';
                  }
                  final limit = int.tryParse(value);
                  if (limit == null || limit <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                } : null,
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Minimum Order Value'),
              subtitle: const Text('Require a minimum order amount'),
              value: _hasMinOrder,
              onChanged: (value) {
                setState(() {
                  _hasMinOrder = value;
                  if (!value) {
                    _minOrderController.clear();
                  }
                });
              },
            ),
            if (_hasMinOrder) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _minOrderController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Order Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _hasMinOrder ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter minimum order amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                } : null,
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Maximum Discount Amount'),
              subtitle: const Text('Cap the total discount amount'),
              value: _hasMaxDiscount,
              onChanged: (value) {
                setState(() {
                  _hasMaxDiscount = value;
                  if (!value) {
                    _maxDiscountController.clear();
                  }
                });
              },
            ),
            if (_hasMaxDiscount) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxDiscountController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Discount Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _hasMaxDiscount ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter maximum discount amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                } : null,
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Make this discount code available for use'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Public'),
              subtitle: const Text('Allow users to search and find this code'),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getDiscountTypeDisplayName(DiscountType type) {
    switch (type) {
      case DiscountType.percentage:
        return 'Percentage Discount';
      case DiscountType.fixed_amount:
        return 'Fixed Amount Discount';
      case DiscountType.buy_one_get_one:
        return 'Buy One Get One';
      case DiscountType.group_discount:
        return 'Group Discount';
      case DiscountType.early_bird:
        return 'Early Bird Discount';
    }
  }

  String _getValueLabel() {
    switch (_selectedType) {
      case DiscountType.percentage:
      case DiscountType.early_bird:
        return 'Percentage';
      case DiscountType.fixed_amount:
        return 'Amount';
      case DiscountType.buy_one_get_one:
        return 'Buy Quantity';
      case DiscountType.group_discount:
        return 'Group Size';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectDate(bool isFromDate) async {
    final initialDate = isFromDate 
        ? (_validFrom ?? DateTime.now())
        : (_validUntil ?? DateTime.now().add(const Duration(days: 30)));
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (selectedDate != null) {
      setState(() {
        if (isFromDate) {
          _validFrom = selectedDate;
        } else {
          _validUntil = selectedDate;
        }
      });
    }
  }

  Future<void> _createDiscountCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final event = context.findAncestorStateOfType<_DiscountCodeScreenState>()?.widget.event;
      if (event == null) throw Exception('Event not found');

      await _registrationService.createDiscountCode(
        eventId: event.id,
        code: _codeController.text.toUpperCase(),
        name: _nameController.text,
        description: _descriptionController.text,
        type: _selectedType,
        value: double.parse(_valueController.text),
        minOrderValue: _hasMinOrder ? double.parse(_minOrderController.text) : null,
        maxDiscountAmount: _hasMaxDiscount ? double.parse(_maxDiscountController.text) : null,
        usageLimit: _hasUsageLimit ? int.parse(_usageLimitController.text) : null,
        validFrom: _validFrom,
        validUntil: _validUntil,
        isActive: _isActive,
        isPublic: _isPublic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discount code created successfully!')),
        );
        
        // Clear form
        _formKey.currentState!.reset();
        _codeController.clear();
        _nameController.clear();
        _descriptionController.clear();
        _valueController.clear();
        _minOrderController.clear();
        _maxDiscountController.clear();
        _usageLimitController.clear();
        
        setState(() {
          _selectedType = DiscountType.percentage;
          _validFrom = null;
          _validUntil = null;
          _isActive = true;
          _isPublic = true;
          _hasUsageLimit = false;
          _hasMinOrder = false;
          _hasMaxDiscount = false;
        });
        
        // Refresh the discount codes list
        final parentState = context.findAncestorStateOfType<_DiscountCodeScreenState>();
        parentState?._loadDiscountCodes();
        
        // Switch to first tab
        final tabController = context.findAncestorStateOfType<_DiscountCodeScreenState>()?._tabController;
        tabController?.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating discount code: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}