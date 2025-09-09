import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/registration_service.dart';

class TicketTypeSetupScreen extends StatefulWidget {
  final Event event;
  final TicketTypeConfig? ticketType;

  const TicketTypeSetupScreen({
    super.key,
    required this.event,
    this.ticketType,
  });

  @override
  State<TicketTypeSetupScreen> createState() => _TicketTypeSetupScreenState();
}

class _TicketTypeSetupScreenState extends State<TicketTypeSetupScreen> {
  final RegistrationService _registrationService = RegistrationService();
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _totalAvailableController;
  late final TextEditingController _maxPerPersonController;
  
  TicketType _selectedType = TicketType.general;
  DateTime? _saleStartDate;
  DateTime? _saleEndDate;
  bool _isActive = true;
  bool _requiresApproval = false;
  
  final List<String> _includedFeatures = [];
  final List<String> _availableFor = [];
  final TextEditingController _newFeatureController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    final ticketType = widget.ticketType;
    _nameController = TextEditingController(text: ticketType?.name ?? '');
    _descriptionController = TextEditingController(text: ticketType?.description ?? '');
    _priceController = TextEditingController(text: ticketType?.price.toString() ?? '0.00');
    _totalAvailableController = TextEditingController(text: ticketType?.totalAvailable.toString() ?? '100');
    _maxPerPersonController = TextEditingController(text: ticketType?.maxPerPerson.toString() ?? '1');
    
    if (ticketType != null) {
      _selectedType = ticketType.type;
      _saleStartDate = ticketType.saleStartDate;
      _saleEndDate = ticketType.saleEndDate;
      _isActive = ticketType.isActive;
      _requiresApproval = ticketType.requiresApproval;
      _includedFeatures.addAll(ticketType.includedFeatures);
      _availableFor.addAll(ticketType.availableFor);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _totalAvailableController.dispose();
    _maxPerPersonController.dispose();
    _newFeatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ticketType != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Ticket Type' : 'Create Ticket Type'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTicketType,
            child: Text(
              isEditing ? 'Update' : 'Create',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBasicInfo(),
                  const SizedBox(height: 24),
                  _buildPricingSettings(),
                  const SizedBox(height: 24),
                  _buildAvailabilitySettings(),
                  const SizedBox(height: 24),
                  _buildSalesSettings(),
                  const SizedBox(height: 24),
                  _buildFeaturesSection(),
                  const SizedBox(height: 24),
                  _buildAdvancedSettings(),
                ],
              ),
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ticket Name',
                hintText: 'e.g., Early Bird, General Admission, VIP',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a ticket name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of what\'s included',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TicketType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Ticket Type',
                border: OutlineInputBorder(),
              ),
              items: TicketType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTicketTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$',
                border: OutlineInputBorder(),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (double.tryParse(_priceController.text) == 0.0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will be a free ticket. Attendees won\'t be charged.',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalAvailableController,
                    decoration: const InputDecoration(
                      labelText: 'Total Available',
                      border: OutlineInputBorder(),
                      hintText: '100',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final total = int.tryParse(value);
                      if (total == null || total <= 0) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxPerPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Max Per Person',
                      border: OutlineInputBorder(),
                      hintText: '1',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final max = int.tryParse(value);
                      if (max == null || max <= 0) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Ticket is available for purchase'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Requires Approval'),
              subtitle: const Text('Manual approval needed before confirmation'),
              value: _requiresApproval,
              onChanged: (value) {
                setState(() {
                  _requiresApproval = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Sale Start Date'),
              subtitle: Text(_saleStartDate != null 
                  ? _formatDate(_saleStartDate!) 
                  : 'No start date set (available immediately)'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            const Divider(),
            ListTile(
              title: const Text('Sale End Date'),
              subtitle: Text(_saleEndDate != null 
                  ? _formatDate(_saleEndDate!) 
                  : 'No end date set (available until event)'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            if (_saleStartDate != null || _saleEndDate != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_saleStartDate != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _saleStartDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Start'),
                      ),
                    ),
                  if (_saleEndDate != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _saleEndDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear End'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Included Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newFeatureController,
                    decoration: const InputDecoration(
                      hintText: 'Add a feature...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addFeature,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_includedFeatures.isEmpty)
              const Text(
                'No features added yet',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._includedFeatures.asMap().entries.map((entry) {
                final index = entry.key;
                final feature = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                        IconButton(
                          onPressed: () => _removeFeature(index),
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
            const Text(
              'Available For (User Roles)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRoleChip('General Public', 'general'),
                _buildRoleChip('Students', 'student'),
                _buildRoleChip('Members', 'member'),
                _buildRoleChip('Speakers', 'speaker'),
                _buildRoleChip('Sponsors', 'sponsor'),
                _buildRoleChip('VIP', 'vip'),
              ],
            ),
            if (_availableFor.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Available to all users by default',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, String role) {
    final isSelected = _availableFor.contains(role);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _availableFor.add(role);
          } else {
            _availableFor.remove(role);
          }
        });
      },
    );
  }

  String _getTicketTypeDisplayName(TicketType type) {
    switch (type) {
      case TicketType.general:
        return 'General Admission';
      case TicketType.vip:
        return 'VIP';
      case TicketType.early_bird:
        return 'Early Bird';
      case TicketType.student:
        return 'Student';
      case TicketType.group:
        return 'Group';
      case TicketType.speaker:
        return 'Speaker';
      case TicketType.sponsor:
        return 'Sponsor';
      case TicketType.press:
        return 'Press';
      case TicketType.free:
        return 'Free';
      case TicketType.premium:
        return 'Premium';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate 
        ? (_saleStartDate ?? DateTime.now())
        : (_saleEndDate ?? DateTime.now().add(const Duration(days: 30)));
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _saleStartDate = selectedDate;
        } else {
          _saleEndDate = selectedDate;
        }
      });
    }
  }

  void _addFeature() {
    final feature = _newFeatureController.text.trim();
    if (feature.isNotEmpty && !_includedFeatures.contains(feature)) {
      setState(() {
        _includedFeatures.add(feature);
        _newFeatureController.clear();
      });
    }
  }

  void _removeFeature(int index) {
    setState(() {
      _includedFeatures.removeAt(index);
    });
  }

  Future<void> _saveTicketType() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text);
      final totalAvailable = int.parse(_totalAvailableController.text);
      final maxPerPerson = int.parse(_maxPerPersonController.text);

      if (widget.ticketType == null) {
        // Create new ticket type
        await _registrationService.createTicketType(
          eventId: widget.event.id,
          name: _nameController.text,
          description: _descriptionController.text,
          type: _selectedType,
          price: price,
          totalAvailable: totalAvailable,
          maxPerPerson: maxPerPerson,
          saleStartDate: _saleStartDate,
          saleEndDate: _saleEndDate,
          isActive: _isActive,
          requiresApproval: _requiresApproval,
          availableFor: _availableFor,
          includedFeatures: _includedFeatures,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket type created successfully!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Update existing ticket type
        await _registrationService.updateTicketType(
          widget.ticketType!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          type: _selectedType,
          price: price,
          totalAvailable: totalAvailable,
          maxPerPerson: maxPerPerson,
          saleStartDate: _saleStartDate,
          saleEndDate: _saleEndDate,
          isActive: _isActive,
          requiresApproval: _requiresApproval,
          availableFor: _availableFor,
          includedFeatures: _includedFeatures,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket type updated successfully!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving ticket type: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}