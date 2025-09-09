import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../models/guest.dart';
import '../../providers/event_provider.dart';
import '../../services/invitation_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class SendInvitationsScreen extends StatefulWidget {
  final Event event;
  final List<Guest> guests;

  const SendInvitationsScreen({
    super.key,
    required this.event,
    required this.guests,
  });

  @override
  State<SendInvitationsScreen> createState() => _SendInvitationsScreenState();
}

class _SendInvitationsScreenState extends State<SendInvitationsScreen> {
  final InvitationService _invitationService = InvitationService();
  final _messageController = TextEditingController();
  
  Set<String> _selectedGuestIds = <String>{};
  InvitationType _selectedType = InvitationType.email;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _selectedGuestIds = widget.guests.map((g) => g.id).toSet();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _toggleGuestSelection(String guestId) {
    setState(() {
      if (_selectedGuestIds.contains(guestId)) {
        _selectedGuestIds.remove(guestId);
      } else {
        _selectedGuestIds.add(guestId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedGuestIds = widget.guests.map((g) => g.id).toSet();
    });
  }

  void _selectNone() {
    setState(() {
      _selectedGuestIds.clear();
    });
  }

  void _sendInvitations() async {
    if (_selectedGuestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one guest'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final selectedGuests = widget.guests
        .where((guest) => _selectedGuestIds.contains(guest.id))
        .toList();

    final customMessage = _messageController.text.trim().isNotEmpty 
        ? _messageController.text.trim() 
        : null;

    try {
      final results = await _invitationService.sendBulkInvitations(
        widget.event,
        selectedGuests,
        _selectedType,
        customMessage: customMessage,
      );

      final successCount = results.where((r) => r).length;
      final totalCount = results.length;

      if (mounted) {
        setState(() => _isSending = false);
        
        if (successCount == totalCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All $totalCount invitations sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount of $totalCount invitations sent'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send invitations'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending invitations: $e'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send Invitations'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _sendInvitations,
            child: const Text('Send'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invitation Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<InvitationType>(
                        title: const Text('Email'),
                        value: InvitationType.email,
                        groupValue: _selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<InvitationType>(
                        title: const Text('SMS'),
                        value: InvitationType.sms,
                        groupValue: _selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _messageController,
                  labelText: 'Custom Message (optional)',
                  hintText: 'Add a personal message to your invitation...',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recipients (${_selectedGuestIds.length}/${widget.guests.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _selectAll,
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: _selectNone,
                      child: const Text('Select None'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.guests.length,
              itemBuilder: (context, index) {
                final guest = widget.guests[index];
                final isSelected = _selectedGuestIds.contains(guest.id);
                final canSendSMS = guest.phone?.isNotEmpty == true;

                return Card(
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) => _toggleGuestSelection(guest.id),
                    title: Text(guest.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guest.email),
                        if (guest.phone?.isNotEmpty == true)
                          Text(guest.phone!),
                        if (_selectedType == InvitationType.sms && !canSendSMS)
                          const Text(
                            'No phone number available',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        guest.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    isThreeLine: guest.phone?.isNotEmpty == true,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedType == InvitationType.sms)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SMS invitations will open your default messaging app',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Send ${_selectedGuestIds.length} Invitation${_selectedGuestIds.length == 1 ? '' : 's'}',
                  onPressed: _selectedGuestIds.isEmpty ? null : _sendInvitations,
                  isLoading: _isSending,
                  icon: Icons.send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}