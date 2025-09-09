import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/photo_gallery.dart';
import '../../services/photo_gallery_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final Event event;
  final PhotoGalleryItem photo;
  final List<PhotoGalleryItem> allPhotos;

  const PhotoDetailScreen({
    super.key,
    required this.event,
    required this.photo,
    this.allPhotos = const [],
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final PhotoGalleryService _galleryService = PhotoGalleryService();
  late PhotoGalleryItem _currentPhoto;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showInfo = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.photo;
    _currentIndex = widget.allPhotos.isNotEmpty 
        ? widget.allPhotos.indexWhere((p) => p.id == widget.photo.id)
        : 0;
    if (_currentIndex == -1) _currentIndex = 0;
    
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    try {
      final isLiked = await _galleryService.toggleLike(_currentPhoto.id, _currentUserId);
      
      // Update local state immediately for better UX
      setState(() {
        final likedBy = List<String>.from(_currentPhoto.likedBy);
        if (isLiked) {
          likedBy.add(_currentUserId);
        } else {
          likedBy.remove(_currentUserId);
        }
        _currentPhoto = _currentPhoto.copyWith(likedBy: likedBy);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
        );
      }
    }
  }

  Future<void> _downloadPhoto() async {
    try {
      await _galleryService.incrementDownloadCount(_currentPhoto.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved to gallery'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading photo: $e')),
        );
      }
    }
  }

  void _sharePhoto() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality would be implemented here')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _currentPhoto.likedBy.contains(_currentUserId);
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showInfo = !_showInfo),
            icon: Icon(
              _showInfo ? Icons.info : Icons.info_outline,
              color: Colors.white,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Download'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              if (_currentPhoto.uploaderId == _currentUserId)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Photo viewer
          widget.allPhotos.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  itemCount: widget.allPhotos.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _currentPhoto = widget.allPhotos[index];
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildPhotoView(widget.allPhotos[index]);
                  },
                )
              : _buildPhotoView(_currentPhoto),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _toggleLike,
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 28,
                      ),
                    ),
                    Text(
                      '${_currentPhoto.likesCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: _sharePhoto,
                      icon: const Icon(Icons.share, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    if (widget.allPhotos.isNotEmpty)
                      Text(
                        '${_currentIndex + 1} / ${widget.allPhotos.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Photo info overlay
          if (_showInfo)
            Positioned(
              top: 0,
              right: 0,
              bottom: 100,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60), // Account for app bar
                      _buildPhotoInfo(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoView(PhotoGalleryItem photo) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Center(
        child: Image.network(
          photo.imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotoInfo() {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentPhoto.caption.isNotEmpty) ...[
          Text(
            'Caption',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentPhoto.caption,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
        ],
        
        Text(
          'Details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildInfoRow('Uploaded by', _currentPhoto.uploaderName),
        _buildInfoRow('Category', _getCategoryLabel(_currentPhoto.category)),
        _buildInfoRow('Captured', dateFormat.format(_currentPhoto.capturedAt)),
        _buildInfoRow('Uploaded', dateFormat.format(_currentPhoto.uploadedAt)),
        
        if (_currentPhoto.location != null)
          _buildInfoRow('Location', _currentPhoto.location!),
        
        _buildInfoRow('Visibility', _getVisibilityLabel(_currentPhoto.visibility)),
        _buildInfoRow('Likes', '${_currentPhoto.likesCount}'),
        _buildInfoRow('Downloads', '${_currentPhoto.downloadCount}'),
        
        if (_currentPhoto.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Tags',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentPhoto.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        if (_currentPhoto.taggedPeople.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Tagged People',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...(_currentPhoto.taggedPeople.map((personId) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'User $personId', // In real app, get name from profile
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }).toList()),
        ],
        
        if (_currentPhoto.isHighlighted) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Highlighted Photo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
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

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'download':
        await _downloadPhoto();
        break;
      case 'share':
        _sharePhoto();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              try {
                await _galleryService.deletePhoto(_currentPhoto.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Return to gallery
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting photo: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}