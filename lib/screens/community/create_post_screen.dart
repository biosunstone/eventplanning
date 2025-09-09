import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/event.dart';
import '../../models/community_post.dart';
import '../../services/community_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreatePostScreen extends StatefulWidget {
  final Event event;
  final CommunityPost? existingPost;

  const CreatePostScreen({
    super.key,
    required this.event,
    this.existingPost,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final CommunityService _communityService = CommunityService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();

  PostType _selectedType = PostType.general;
  List<String> _selectedImages = [];
  DateTime? _eventDate;
  bool _isLoading = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  bool get _isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateExistingPost();
    }
  }

  void _populateExistingPost() {
    final post = widget.existingPost!;
    _titleController.text = post.title;
    _contentController.text = post.content;
    _locationController.text = post.location ?? '';
    _tagsController.text = post.tags.join(', ');
    _selectedType = post.type;
    _selectedImages = List.from(post.imageUrls);
    _eventDate = post.eventDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _imagePicker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (images != null) {
      setState(() {
        _selectedImages.addAll(images.map((image) => image.path));
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.take(5).toList();
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _eventDate = DateTime(
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

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final post = CommunityPost(
        id: _isEditing ? widget.existingPost!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        eventId: widget.event.id,
        authorId: _currentUserId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        status: PostStatus.active,
        tags: tags,
        imageUrls: _selectedImages,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        eventDate: _eventDate,
        createdAt: _isEditing ? widget.existingPost!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await _communityService.updatePost(post);
      } else {
        await _communityService.createPost(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Post updated successfully' : 'Post created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving post: $e'),
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
        title: Text(_isEditing ? 'Edit Post' : 'Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePost,
            child: Text(_isEditing ? 'Update' : 'Post'),
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
              _buildPostTypeSelector(),
              const SizedBox(height: 24),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildContentField(),
              const SizedBox(height: 16),
              if (_needsLocation()) ...[
                _buildLocationField(),
                const SizedBox(height: 16),
              ],
              if (_needsEventDate()) ...[
                _buildEventDateField(),
                const SizedBox(height: 16),
              ],
              _buildTagsField(),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 32),
              CustomButton(
                text: _isEditing ? 'Update Post' : 'Create Post',
                onPressed: _savePost,
                isLoading: _isLoading,
                icon: _isEditing ? Icons.update : Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PostType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(_getPostTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = type);
                }
              },
              avatar: Icon(
                _getPostTypeIcon(type),
                size: 16,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getPostTypeDescription(_selectedType),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return CustomTextField(
      controller: _titleController,
      labelText: 'Title',
      hintText: _getTitleHint(_selectedType),
      prefixIcon: Icons.title,
      validator: (value) {
        if (value?.isEmpty == true) return 'Title is required';
        if (value!.length < 5) return 'Title must be at least 5 characters';
        return null;
      },
    );
  }

  Widget _buildContentField() {
    return CustomTextField(
      controller: _contentController,
      labelText: 'Content',
      hintText: _getContentHint(_selectedType),
      prefixIcon: Icons.description,
      maxLines: 8,
      validator: (value) {
        if (value?.isEmpty == true) return 'Content is required';
        if (value!.length < 10) return 'Content must be at least 10 characters';
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return CustomTextField(
      controller: _locationController,
      labelText: 'Location (optional)',
      hintText: 'Where is this happening?',
      prefixIcon: Icons.location_on,
    );
  }

  Widget _buildEventDateField() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _eventDate != null
                    ? 'Date: ${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year} at ${_eventDate!.hour}:${_eventDate!.minute.toString().padLeft(2, '0')}'
                    : 'Select date and time',
                style: TextStyle(
                  color: _eventDate != null ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
            if (_eventDate != null)
              IconButton(
                onPressed: () => setState(() => _eventDate = null),
                icon: const Icon(Icons.clear, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsField() {
    return CustomTextField(
      controller: _tagsController,
      labelText: 'Tags (optional)',
      hintText: 'networking, flutter, startup (comma separated)',
      prefixIcon: Icons.tag,
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Images (${_selectedImages.length}/5)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _selectedImages.length < 5 ? _pickImages : null,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final imagePath = _selectedImages[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagePath,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
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
                );
              },
            ),
          ),
      ],
    );
  }

  bool _needsLocation() {
    return _selectedType == PostType.meetup || 
           _selectedType == PostType.rideshare ||
           _selectedType == PostType.lostFound;
  }

  bool _needsEventDate() {
    return _selectedType == PostType.meetup || _selectedType == PostType.rideshare;
  }

  String _getPostTypeLabel(PostType type) {
    switch (type) {
      case PostType.general:
        return 'General';
      case PostType.rideshare:
        return 'Rideshare';
      case PostType.meetup:
        return 'Meetup';
      case PostType.jobPosting:
        return 'Job Posting';
      case PostType.lostFound:
        return 'Lost & Found';
      case PostType.recommendation:
        return 'Recommendation';
      case PostType.question:
        return 'Question';
      case PostType.announcement:
        return 'Announcement';
    }
  }

  IconData _getPostTypeIcon(PostType type) {
    switch (type) {
      case PostType.general:
        return Icons.forum;
      case PostType.rideshare:
        return Icons.directions_car;
      case PostType.meetup:
        return Icons.people;
      case PostType.jobPosting:
        return Icons.work;
      case PostType.lostFound:
        return Icons.search;
      case PostType.recommendation:
        return Icons.star;
      case PostType.question:
        return Icons.help;
      case PostType.announcement:
        return Icons.campaign;
    }
  }

  String _getPostTypeDescription(PostType type) {
    switch (type) {
      case PostType.general:
        return 'Share general thoughts, discussions, or updates';
      case PostType.rideshare:
        return 'Find people to share rides to/from the event';
      case PostType.meetup:
        return 'Organize informal meetups during the event';
      case PostType.jobPosting:
        return 'Share job opportunities or career-related content';
      case PostType.lostFound:
        return 'Help find lost items or report found items';
      case PostType.recommendation:
        return 'Recommend restaurants, places, or services';
      case PostType.question:
        return 'Ask questions to the community';
      case PostType.announcement:
        return 'Important announcements (organizers only)';
    }
  }

  String _getTitleHint(PostType type) {
    switch (type) {
      case PostType.general:
        return 'What would you like to share?';
      case PostType.rideshare:
        return 'Need a ride to/from the venue?';
      case PostType.meetup:
        return 'Coffee meetup after Day 1?';
      case PostType.jobPosting:
        return 'Software Engineer Position Available';
      case PostType.lostFound:
        return 'Lost: Black iPhone 13 Pro';
      case PostType.recommendation:
        return 'Best coffee shop near venue';
      case PostType.question:
        return 'Which sessions are you most excited about?';
      case PostType.announcement:
        return 'Important: Schedule Update';
    }
  }

  String _getContentHint(PostType type) {
    switch (type) {
      case PostType.general:
        return 'Share your thoughts, experiences, or start a discussion...';
      case PostType.rideshare:
        return 'Looking for 2-3 people to share an Uber from downtown. Leaving at 8 AM...';
      case PostType.meetup:
        return 'Anyone interested in grabbing coffee after the keynote? Let\'s meet at...';
      case PostType.jobPosting:
        return 'We\'re hiring! Looking for experienced developers to join our team...';
      case PostType.lostFound:
        return 'Lost my phone during the networking session. It has a blue case...';
      case PostType.recommendation:
        return 'Just discovered this amazing place for lunch. Great food and close to venue...';
      case PostType.question:
        return 'I\'m torn between the AI workshop and the startup panel. What would you choose?';
      case PostType.announcement:
        return 'Due to unexpected circumstances, the morning keynote has been moved...';
    }
  }
}