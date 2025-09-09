import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreateEventScreen extends StatefulWidget {
  final Event? event;

  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  EventCategory _selectedCategory = EventCategory.other;
  EventStatus _selectedStatus = EventStatus.planning;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final event = widget.event!;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location;
    _budgetController.text = event.budget > 0 ? event.budget.toString() : '';
    _selectedDate = DateTime(
      event.dateTime.year,
      event.dateTime.month,
      event.dateTime.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(event.dateTime);
    _selectedCategory = event.category;
    _selectedStatus = event.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      if (authProvider.user == null) return;

      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final event = Event(
        id: _isEditing ? widget.event!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: dateTime,
        location: _locationController.text.trim(),
        category: _selectedCategory,
        status: _selectedStatus,
        organizerId: authProvider.user!.id,
        budget: double.tryParse(_budgetController.text) ?? 0.0,
        createdAt: _isEditing ? widget.event!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_isEditing) {
        success = await eventProvider.updateEvent(event);
      } else {
        success = await eventProvider.createEvent(event);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Event updated successfully' : 'Event created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(eventProvider.error ?? 'Failed to save event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
        actions: [
          Consumer<EventProvider>(
            builder: (context, eventProvider, child) {
              return TextButton(
                onPressed: eventProvider.isLoading ? null : _handleSave,
                child: Text(_isEditing ? 'Update' : 'Save'),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Event Title',
                prefixIcon: Icons.event,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectDate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Time'),
                        subtitle: Text(_selectedTime.format(context)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectTime,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _locationController,
                labelText: 'Location',
                prefixIcon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: EventCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryDisplayName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventStatus>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: EventStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusDisplayName(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _budgetController,
                labelText: 'Budget (optional)',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty == true) {
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Consumer<EventProvider>(
                builder: (context, eventProvider, child) {
                  return CustomButton(
                    text: _isEditing ? 'Update Event' : 'Create Event',
                    isLoading: eventProvider.isLoading,
                    onPressed: _handleSave,
                    icon: _isEditing ? Icons.update : Icons.add,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.wedding:
        return 'Wedding';
      case EventCategory.birthday:
        return 'Birthday';
      case EventCategory.corporate:
        return 'Corporate';
      case EventCategory.social:
        return 'Social';
      case EventCategory.educational:
        return 'Educational';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.other:
        return 'Other';
    }
  }

  String _getStatusDisplayName(EventStatus status) {
    switch (status) {
      case EventStatus.planning:
        return 'Planning';
      case EventStatus.confirmed:
        return 'Confirmed';
      case EventStatus.ongoing:
        return 'Ongoing';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }
}