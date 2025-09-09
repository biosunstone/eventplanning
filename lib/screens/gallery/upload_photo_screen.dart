import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/event.dart';
import '../../models/photo_gallery.dart';
import '../../services/photo_gallery_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class UploadPhotoScreen extends StatefulWidget {
  final Event event;

  const UploadPhotoScreen({super.key, required this.event});

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  final PhotoGalleryService _galleryService = PhotoGalleryService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();

  List<String> _selectedImages = [];
  PhotoCategory _selectedCategory = PhotoCategory.attendees;
  PhotoVisibility _selectedVisibility = PhotoVisibility.public;
  DateTime? _capturedDate;
  bool _isUploading = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (images != null) {
      setState(() {
        _selectedImages.addAll(images.map((image) => image.path));
        if (_selectedImages.length > 10) {
          _selectedImages = _selectedImages.take(10).toList();
        }
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(image.path);
      });
    }
  }

  Future<void> _selectCapturedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _capturedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_capturedDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _capturedDate = DateTime(
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

  Future<void> _uploadPhotos() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      for (int i = 0; i < _selectedImages.length; i++) {
        final imagePath = _selectedImages[i];
        
        final photo = PhotoGalleryItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          eventId: widget.event.id,
          uploaderId: _currentUserId,
          uploaderName: 'User $_currentUserId', // In real app, get from profile
          imageUrl: imagePath, // In real app, upload to cloud storage
          thumbnailUrl: imagePath, // In real app, generate thumbnail
          caption: _captionController.text.trim(),
          category: _selectedCategory,
          visibility: _selectedVisibility,
          tags: tags,
          location: _locationController.text.trim().isNotEmpty 
              ? _locationController.text.trim() 
              : null,
          capturedAt: _capturedDate ?? DateTime.now(),
          uploadedAt: DateTime.now(),
        );

        await _galleryService.uploadPhoto(photo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedImages.length} photo(s) uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Photos'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadPhotos,
            child: const Text('Upload'),
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
              _buildImageSelector(),
              const SizedBox(height: 24),
              _buildCaptionField(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildVisibilitySelector(),
              const SizedBox(height: 16),
              _buildLocationField(),
              const SizedBox(height: 16),
              _buildCapturedDateField(),
              const SizedBox(height: 16),
              _buildTagsField(),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Upload ${_selectedImages.length} Photo${_selectedImages.length != 1 ? 's' : ''}',
                onPressed: _selectedImages.isNotEmpty && !_isUploading ? _uploadPhotos : null,
                isLoading: _isUploading,
                icon: Icons.cloud_upload,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photos (${_selectedImages.length}/10)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _selectedImages.length < 10 ? _pickFromCamera : null,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _selectedImages.length < 10 ? _pickImages : null,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isEmpty)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select photos to upload',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from camera or gallery',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final imagePath = _selectedImages[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagePath,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
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
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCaptionField() {
    return CustomTextField(
      controller: _captionController,
      labelText: 'Caption (optional)',
      hintText: 'Describe what\'s happening in the photo...',
      prefixIcon: Icons.chat_bubble_outline,
      maxLines: 3,
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PhotoCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return FilterChip(
              label: Text(_getCategoryLabel(category)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              avatar: Icon(
                _getCategoryIcon(category),
                size: 16,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...PhotoVisibility.values.map((visibility) {
          return RadioListTile<PhotoVisibility>(
            title: Text(_getVisibilityLabel(visibility)),
            subtitle: Text(_getVisibilityDescription(visibility)),
            value: visibility,
            groupValue: _selectedVisibility,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedVisibility = value);
              }
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLocationField() {
    return CustomTextField(
      controller: _locationController,
      labelText: 'Location (optional)',
      hintText: 'Where was this photo taken?',
      prefixIcon: Icons.location_on,
    );
  }

  Widget _buildCapturedDateField() {
    return InkWell(
      onTap: _selectCapturedDate,
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
                _capturedDate != null
                    ? 'Captured: ${_capturedDate!.day}/${_capturedDate!.month}/${_capturedDate!.year} at ${_capturedDate!.hour}:${_capturedDate!.minute.toString().padLeft(2, '0')}'
                    : 'When was this photo taken? (optional)',
                style: TextStyle(
                  color: _capturedDate != null ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
            if (_capturedDate != null)
              IconButton(
                onPressed: () => setState(() => _capturedDate = null),
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
      hintText: 'keynote, networking, fun (comma separated)',
      prefixIcon: Icons.tag,
    );
  }

  String _getCategoryLabel(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.keynote:
        return 'Keynote';
      case PhotoCategory.session:
        return 'Session';
      case PhotoCategory.networking:
        return 'Networking';
      case PhotoCategory.meals:
        return 'Meals';
      case PhotoCategory.venue:
        return 'Venue';
      case PhotoCategory.speakers:
        return 'Speakers';
      case PhotoCategory.attendees:
        return 'Attendees';
      case PhotoCategory.exhibits:
        return 'Exhibits';
      case PhotoCategory.social:
        return 'Social';
      case PhotoCategory.behind_scenes:
        return 'Behind Scenes';
    }
  }

  IconData _getCategoryIcon(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.keynote:
        return Icons.campaign;
      case PhotoCategory.session:
        return Icons.event_note;
      case PhotoCategory.networking:
        return Icons.people;
      case PhotoCategory.meals:
        return Icons.restaurant;
      case PhotoCategory.venue:
        return Icons.location_city;
      case PhotoCategory.speakers:
        return Icons.record_voice_over;
      case PhotoCategory.attendees:
        return Icons.groups;
      case PhotoCategory.exhibits:
        return Icons.store;
      case PhotoCategory.social:
        return Icons.celebration;
      case PhotoCategory.behind_scenes:
        return Icons.camera_alt;
    }
  }

  String _getVisibilityLabel(PhotoVisibility visibility) {
    switch (visibility) {
      case PhotoVisibility.public:
        return 'Public';
      case PhotoVisibility.attendeesOnly:
        return 'Attendees Only';
      case PhotoVisibility.private:
        return 'Private';
    }
  }

  String _getVisibilityDescription(PhotoVisibility visibility) {
    switch (visibility) {
      case PhotoVisibility.public:
        return 'Everyone can see this photo';
      case PhotoVisibility.attendeesOnly:
        return 'Only event attendees can see this photo';
      case PhotoVisibility.private:
        return 'Only you can see this photo';
    }
  }
}