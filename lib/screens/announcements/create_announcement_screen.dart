import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/event.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final Event event;
  final Announcement? existingAnnouncement;

  const CreateAnnouncementScreen({
    super.key,
    required this.event,
    this.existingAnnouncement,
  });

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _actionButtonTextController = TextEditingController();
  final _actionButtonUrlController = TextEditingController();
  final _tagsController = TextEditingController();

  AnnouncementType _selectedType = AnnouncementType.general;
  AnnouncementPriority _selectedPriority = AnnouncementPriority.normal;
  AnnouncementStatus _selectedStatus = AnnouncementStatus.active;
  bool _sendPushNotification = true;
  bool _sendEmail = false;
  bool _sendSMS = false;
  bool _isPinned = false;
  DateTime? _scheduledAt;
  DateTime? _expiresAt;
  String? _selectedImagePath;
  List<String> _targetAudience = [];
  bool _isLoading = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  final List<String> _audienceOptions = [
    'all',
    'attendees',
    'speakers',
    'sponsors',
    'organizers',
    'vip',
  ];

  bool get _isEditing => widget.existingAnnouncement != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateExistingAnnouncement();
    }
  }

  void _populateExistingAnnouncement() {
    final announcement = widget.existingAnnouncement!;
    _titleController.text = announcement.title;
    _contentController.text = announcement.content;
    _actionButtonTextController.text = announcement.actionButtonText ?? '';
    _actionButtonUrlController.text = announcement.actionButtonUrl ?? '';
    _tagsController.text = announcement.tags.join(', ');
    _selectedType = announcement.type;
    _selectedPriority = announcement.priority;
    _selectedStatus = announcement.status;
    _sendPushNotification = announcement.sendPushNotification;
    _sendEmail = announcement.sendEmail;
    _sendSMS = announcement.sendSMS;
    _isPinned = announcement.isPinned;
    _scheduledAt = announcement.scheduledAt;
    _expiresAt = announcement.expiresAt;
    _selectedImagePath = announcement.imageUrl;
    _targetAudience = List.from(announcement.targetAudience);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _actionButtonTextController.dispose();
    _actionButtonUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _selectScheduledDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _scheduledAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          
          // If scheduling for later, set status to scheduled
          if (_scheduledAt!.isAfter(DateTime.now())) {
            _selectedStatus = AnnouncementStatus.scheduled;
          }
        });
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expiresAt ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _expiresAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final announcement = Announcement(
        id: _isEditing 
            ? widget.existingAnnouncement!.id 
            : DateTime.now().millisecondsSinceEpoch.toString(),
        eventId: widget.event.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        status: _selectedStatus,
        authorId: _currentUserId,
        authorName: 'Organizer', // In real app, get from profile
        createdAt: _isEditing 
            ? widget.existingAnnouncement!.createdAt 
            : DateTime.now(),
        scheduledAt: _scheduledAt,
        expiresAt: _expiresAt,
        targetAudience: _targetAudience,
        tags: tags,
        actionButtonText: _actionButtonTextController.text.trim().isNotEmpty 
            ? _actionButtonTextController.text.trim() 
            : null,
        actionButtonUrl: _actionButtonUrlController.text.trim().isNotEmpty 
            ? _actionButtonUrlController.text.trim() 
            : null,
        imageUrl: _selectedImagePath,
        isPinned: _isPinned,
        sendPushNotification: _sendPushNotification,
        sendEmail: _sendEmail,
        sendSMS: _sendSMS,
      );

      if (_isEditing) {
        await _announcementService.updateAnnouncement(announcement);
      } else {
        await _announcementService.createAnnouncement(announcement);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Announcement updated successfully' 
                : 'Announcement created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Announcement' : 'Create Announcement'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAnnouncement,
            child: Text(_isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildTypeAndPrioritySection(),
              const SizedBox(height: 24),
              _buildSchedulingSection(),
              const SizedBox(height: 24),
              _buildTargetAudienceSection(),
              const SizedBox(height: 24),
              _buildActionButtonSection(),
              const SizedBox(height: 24),
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildNotificationSettingsSection(),
              const SizedBox(height: 24),
              _buildAdvancedSettingsSection(),
              const SizedBox(height: 32),
              CustomButton(
                text: _isEditing ? 'Update Announcement' : 'Create Announcement',
                onPressed: _saveAnnouncement,
                isLoading: _isLoading,
                icon: _isEditing ? Icons.update : Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _titleController,
          labelText: 'Title',
          hintText: 'Enter announcement title',
          prefixIcon: Icons.title,
          validator: (value) {
            if (value?.isEmpty == true) return 'Title is required';
            if (value!.length < 5) return 'Title must be at least 5 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _contentController,
          labelText: 'Content',
          hintText: 'Write your announcement message...',
          prefixIcon: Icons.description,
          maxLines: 8,
          validator: (value) {
            if (value?.isEmpty == true) return 'Content is required';
            if (value!.length < 10) return 'Content must be at least 10 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _tagsController,
          labelText: 'Tags (optional)',
          hintText: 'urgent, schedule, networking (comma separated)',
          prefixIcon: Icons.tag,
        ),
      ],
    );
  }

  Widget _buildTypeAndPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type & Priority',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<AnnouncementType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AnnouncementType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        _getTypeIcon(type),
                        const SizedBox(width: 8),
                        Text(_getTypeLabel(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<AnnouncementPriority>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: const Icon(Icons.priority_high),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AnnouncementPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        _getPriorityIcon(priority),
                        const SizedBox(width: 8),
                        Text(_getPriorityLabel(priority)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPriority = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSchedulingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduling',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AnnouncementStatus>(
          value: _selectedStatus,
          decoration: InputDecoration(
            labelText: 'Status',
            prefixIcon: const Icon(Icons.settings),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            AnnouncementStatus.draft,
            AnnouncementStatus.scheduled,
            AnnouncementStatus.active,
          ].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(_getStatusLabel(status)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedStatus = value!),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectScheduledDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _scheduledAt != null
                        ? 'Send at: ${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                        : 'Send immediately (optional: schedule for later)',
                    style: TextStyle(
                      color: _scheduledAt != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
                if (_scheduledAt != null)
                  IconButton(
                    onPressed: () => setState(() => _scheduledAt = null),
                    icon: const Icon(Icons.clear, size: 20),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectExpiryDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _expiresAt != null
                        ? 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year} ${_expiresAt!.hour}:${_expiresAt!.minute.toString().padLeft(2, '0')}'
                        : 'No expiry (optional)',
                    style: TextStyle(
                      color: _expiresAt != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
                if (_expiresAt != null)
                  IconButton(
                    onPressed: () => setState(() => _expiresAt = null),
                    icon: const Icon(Icons.clear, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAudienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Audience',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Leave empty to send to all attendees',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _audienceOptions.map((audience) {
            final isSelected = _targetAudience.contains(audience);
            return FilterChip(
              label: Text(_getAudienceLabel(audience)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _targetAudience.add(audience);
                  } else {
                    _targetAudience.remove(audience);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Button (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _actionButtonTextController,
          labelText: 'Button Text',
          hintText: 'View Details, Register Now, etc.',
          prefixIcon: Icons.smart_button,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _actionButtonUrlController,
          labelText: 'Button URL/Action',
          hintText: 'https://example.com or internal action',
          prefixIcon: Icons.link,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Image (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(_selectedImagePath != null ? 'Change Image' : 'Add Image'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedImagePath != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _selectedImagePath!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImagePath = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Send Push Notification'),
          subtitle: const Text('Notify users on their devices'),
          value: _sendPushNotification,
          onChanged: (value) => setState(() => _sendPushNotification = value),
        ),
        SwitchListTile(
          title: const Text('Send Email'),
          subtitle: const Text('Send via email'),
          value: _sendEmail,
          onChanged: (value) => setState(() => _sendEmail = value),
        ),
        SwitchListTile(
          title: const Text('Send SMS'),
          subtitle: const Text('Send via text message'),
          value: _sendSMS,
          onChanged: (value) => setState(() => _sendSMS = value),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Pin Announcement'),
          subtitle: const Text('Keep this announcement at the top'),
          value: _isPinned,
          onChanged: (value) => setState(() => _isPinned = value),
        ),
      ],
    );
  }

  Icon _getTypeIcon(AnnouncementType type) {
    IconData iconData;
    Color color = Colors.grey[600]!;

    switch (type) {
      case AnnouncementType.general:
        iconData = Icons.info;
        break;
      case AnnouncementType.urgent:
        iconData = Icons.warning;
        color = Colors.red;
        break;
      case AnnouncementType.schedule_change:
        iconData = Icons.schedule;
        color = Colors.orange;
        break;
      case AnnouncementType.weather:
        iconData = Icons.wb_cloudy;
        color = Colors.blue;
        break;
      case AnnouncementType.emergency:
        iconData = Icons.emergency;
        color = Colors.red;
        break;
      case AnnouncementType.networking:
        iconData = Icons.people;
        color = Colors.green;
        break;
      case AnnouncementType.meal:
        iconData = Icons.restaurant;
        color = Colors.brown;
        break;
      case AnnouncementType.transport:
        iconData = Icons.directions_bus;
        color = Colors.purple;
        break;
      case AnnouncementType.technical:
        iconData = Icons.build;
        color = Colors.indigo;
        break;
      case AnnouncementType.social:
        iconData = Icons.celebration;
        color = Colors.pink;
        break;
    }

    return Icon(iconData, size: 16, color: color);
  }

  String _getTypeLabel(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.general:
        return 'General';
      case AnnouncementType.urgent:
        return 'Urgent';
      case AnnouncementType.schedule_change:
        return 'Schedule Change';
      case AnnouncementType.weather:
        return 'Weather Update';
      case AnnouncementType.emergency:
        return 'Emergency';
      case AnnouncementType.networking:
        return 'Networking';
      case AnnouncementType.meal:
        return 'Meal/Food';
      case AnnouncementType.transport:
        return 'Transportation';
      case AnnouncementType.technical:
        return 'Technical';
      case AnnouncementType.social:
        return 'Social Event';
    }
  }

  Icon _getPriorityIcon(AnnouncementPriority priority) {
    IconData iconData;
    Color color;

    switch (priority) {
      case AnnouncementPriority.low:
        iconData = Icons.keyboard_arrow_down;
        color = Colors.grey;
        break;
      case AnnouncementPriority.normal:
        iconData = Icons.remove;
        color = Colors.blue;
        break;
      case AnnouncementPriority.high:
        iconData = Icons.keyboard_arrow_up;
        color = Colors.orange;
        break;
      case AnnouncementPriority.urgent:
        iconData = Icons.priority_high;
        color = Colors.red;
        break;
      case AnnouncementPriority.critical:
        iconData = Icons.report_problem;
        color = Colors.red;
        break;
    }

    return Icon(iconData, size: 16, color: color);
  }

  String _getPriorityLabel(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return 'Low';
      case AnnouncementPriority.normal:
        return 'Normal';
      case AnnouncementPriority.high:
        return 'High';
      case AnnouncementPriority.urgent:
        return 'Urgent';
      case AnnouncementPriority.critical:
        return 'Critical';
    }
  }

  String _getStatusLabel(AnnouncementStatus status) {
    switch (status) {
      case AnnouncementStatus.draft:
        return 'Draft';
      case AnnouncementStatus.scheduled:
        return 'Scheduled';
      case AnnouncementStatus.active:
        return 'Active';
      case AnnouncementStatus.expired:
        return 'Expired';
      case AnnouncementStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getAudienceLabel(String audience) {
    switch (audience) {
      case 'all':
        return 'All Users';
      case 'attendees':
        return 'Attendees';
      case 'speakers':
        return 'Speakers';
      case 'sponsors':
        return 'Sponsors';
      case 'organizers':
        return 'Organizers';
      case 'vip':
        return 'VIP';
      default:
        return audience;
    }
  }
}