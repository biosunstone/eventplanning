import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../models/guest.dart';
import '../../providers/event_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_fab.dart';

class GuestListScreen extends StatefulWidget {
  final Event event;

  const GuestListScreen({super.key, required this.event});

  @override
  State<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends State<GuestListScreen> {
  List<Guest> _guests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  void _loadGuests() async {
    setState(() => _isLoading = true);
    setState(() => _isLoading = false);
  }

  void _showAddGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddGuestDialog(
        onGuestAdded: (guest) {
          _addGuest(guest);
        },
      ),
    );
  }

  void _addGuest(Guest guest) async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final success = await eventProvider.addGuest(widget.event.id, guest);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guest added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadGuests();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eventProvider.error ?? 'Failed to add guest'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateGuestRSVP(Guest guest, RSVPStatus status) async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final success = await eventProvider.updateGuestRSVP(
      widget.event.id,
      guest.id,
      status,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RSVP updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadGuests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guest List'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.import_contacts),
            tooltip: 'Import from Contacts',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _guests.isEmpty
              ? _buildEmptyState()
              : _buildGuestList(),
      floatingActionButton: CustomFAB(
        onPressed: _showAddGuestDialog,
        icon: Icons.person_add,
        label: 'Add Guest',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No guests added yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding guests to your event',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddGuestDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Your First Guest'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestList() {
    final attendingCount = _guests.where((g) => g.rsvpStatus == RSVPStatus.attending).length;
    final notAttendingCount = _guests.where((g) => g.rsvpStatus == RSVPStatus.notAttending).length;
    final pendingCount = _guests.where((g) => g.rsvpStatus == RSVPStatus.pending).length;
    final maybeCount = _guests.where((g) => g.rsvpStatus == RSVPStatus.maybe).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'RSVP Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRSVPSummaryItem('Attending', attendingCount, Colors.green),
                  _buildRSVPSummaryItem('Not Attending', notAttendingCount, Colors.red),
                  _buildRSVPSummaryItem('Pending', pendingCount, Colors.orange),
                  _buildRSVPSummaryItem('Maybe', maybeCount, Colors.blue),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _guests.length,
            itemBuilder: (context, index) {
              final guest = _guests[index];
              return _buildGuestCard(guest);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRSVPSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestCard(Guest guest) {
    Color statusColor;
    IconData statusIcon;
    
    switch (guest.rsvpStatus) {
      case RSVPStatus.attending:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RSVPStatus.notAttending:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case RSVPStatus.maybe:
        statusColor = Colors.blue;
        statusIcon = Icons.help_outline;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            guest.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(guest.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guest.email),
            if (guest.phone?.isNotEmpty == true)
              Text(guest.phone!),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  guest.rsvpStatus.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<RSVPStatus>(
          onSelected: (status) => _updateGuestRSVP(guest, status),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: RSVPStatus.attending,
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Attending'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: RSVPStatus.notAttending,
              child: ListTile(
                leading: Icon(Icons.cancel, color: Colors.red),
                title: Text('Not Attending'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: RSVPStatus.maybe,
              child: ListTile(
                leading: Icon(Icons.help_outline, color: Colors.blue),
                title: Text('Maybe'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: RSVPStatus.pending,
              child: ListTile(
                leading: Icon(Icons.schedule, color: Colors.orange),
                title: Text('Pending'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _AddGuestDialog extends StatefulWidget {
  final Function(Guest) onGuestAdded;

  const _AddGuestDialog({required this.onGuestAdded});

  @override
  State<_AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addGuest() {
    if (_formKey.currentState!.validate()) {
      final guest = Guest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        invitedAt: DateTime.now(),
      );

      widget.onGuestAdded(guest);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Guest'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter guest name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone (optional)',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes (optional)',
                prefixIcon: Icons.note,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addGuest,
          child: const Text('Add Guest'),
        ),
      ],
    );
  }
}