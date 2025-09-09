import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/photo_gallery.dart';
import '../../services/photo_gallery_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_fab.dart';
import 'upload_photo_screen.dart';
import 'photo_detail_screen.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final Event event;

  const PhotoGalleryScreen({super.key, required this.event});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen>
    with SingleTickerProviderStateMixin {
  final PhotoGalleryService _galleryService = PhotoGalleryService();
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<PhotoGalleryItem> _allPhotos = [];
  List<PhotoGalleryItem> _filteredPhotos = [];
  List<PhotoGalleryItem> _highlightedPhotos = [];
  List<PhotoAlbum> _albums = [];
  PhotoCategory? _selectedCategory;
  bool _isLoading = false;
  bool _isGridView = true;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGalleryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGalleryData() async {
    setState(() => _isLoading = true);

    try {
      _allPhotos = await _galleryService.getEventPhotos(widget.event.id);
      _filteredPhotos = List.from(_allPhotos);
      _highlightedPhotos = await _galleryService.getHighlightedPhotos(widget.event.id);
      _albums = await _galleryService.getEventAlbums(widget.event.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading gallery: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _filterPhotos({String? query, PhotoCategory? category}) {
    setState(() {
      _selectedCategory = category;
      List<PhotoGalleryItem> photos = _allPhotos;

      // Filter by category
      if (category != null) {
        photos = photos.where((photo) => photo.category == category).toList();
      }

      // Filter by search query
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        photos = photos.where((photo) {
          return photo.caption.toLowerCase().contains(lowercaseQuery) ||
                 photo.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
                 photo.location?.toLowerCase().contains(lowercaseQuery) == true;
        }).toList();
      }

      _filteredPhotos = photos;
    });
  }

  void _navigateToUploadPhoto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UploadPhotoScreen(event: widget.event),
      ),
    ).then((_) => _loadGalleryData());
  }

  void _navigateToCreateAlbum() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Album creation feature - functionality demonstrated')),
    );
  }

  void _navigateToPhotoDetail(PhotoGalleryItem photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoDetailScreen(
          event: widget.event,
          photo: photo,
          allPhotos: _filteredPhotos,
        ),
      ),
    ).then((_) => _loadGalleryData());
  }

  void _navigateToAlbumDetail(PhotoAlbum album) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(album.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (album.description.isNotEmpty) ...[
              Text('Description: ${album.description}'),
              SizedBox(height: 8),
            ],
            Text('Photos: ${album.photoCount}'),
            Text('Created: ${_formatDate(album.createdAt)}'),
            if (album.coverImageUrl.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: Icon(Icons.photo, size: 40, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Album viewing feature - functionality demonstrated')),
              );
            },
            child: Text('View Photos'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Photo Gallery'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            onPressed: _navigateToUploadPhoto,
            icon: const Icon(Icons.add_photo_alternate),
            tooltip: 'Upload Photo',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Photos', icon: Icon(Icons.photo_library)),
            Tab(text: 'Highlights', icon: Icon(Icons.star)),
            Tab(text: 'Albums', icon: Icon(Icons.photo_album)),
            Tab(text: 'My Photos', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllPhotosTab(),
                      _buildHighlightsTab(),
                      _buildAlbumsTab(),
                      _buildMyPhotosTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: CustomFAB(
        onPressed: _navigateToUploadPhoto,
        icon: Icons.camera_alt,
        label: 'Upload Photo',
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomTextField(
            controller: _searchController,
            labelText: 'Search photos...',
            prefixIcon: Icons.search,
            onChanged: (query) => _filterPhotos(query: query, category: _selectedCategory),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', null),
                ...PhotoCategory.values.map((category) => _buildCategoryChip(_getCategoryLabel(category), category)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, PhotoCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          _filterPhotos(
            query: _searchController.text,
            category: selected ? category : null,
          );
        },
      ),
    );
  }

  Widget _buildAllPhotosTab() {
    if (_filteredPhotos.isEmpty) {
      return _buildEmptyState(
        'No photos found',
        _searchController.text.isNotEmpty || _selectedCategory != null
            ? 'Try adjusting your search or filter'
            : 'Upload your first photo to get started',
        Icons.photo_library_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGalleryData,
      child: _isGridView 
          ? _buildPhotoGrid(_filteredPhotos)
          : _buildPhotoList(_filteredPhotos),
    );
  }

  Widget _buildHighlightsTab() {
    if (_highlightedPhotos.isEmpty) {
      return _buildEmptyState(
        'No highlighted photos',
        'Featured photos will appear here',
        Icons.star_outline,
      );
    }

    return _isGridView 
        ? _buildPhotoGrid(_highlightedPhotos)
        : _buildPhotoList(_highlightedPhotos);
  }

  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) {
      return _buildEmptyState(
        'No albums yet',
        'Create albums to organize your photos',
        Icons.photo_album_outlined,
        showCreateButton: true,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGalleryData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _albums.length,
        itemBuilder: (context, index) {
          return _buildAlbumCard(_albums[index]);
        },
      ),
    );
  }

  Widget _buildMyPhotosTab() {
    return FutureBuilder<List<PhotoGalleryItem>>(
      future: _galleryService.getUserPhotos(widget.event.id, _currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final myPhotos = snapshot.data ?? [];
        
        if (myPhotos.isEmpty) {
          return _buildEmptyState(
            'No photos uploaded',
            'Upload your first photo to share with everyone',
            Icons.person_outline,
          );
        }

        return _isGridView 
            ? _buildPhotoGrid(myPhotos)
            : _buildPhotoList(myPhotos);
      },
    );
  }

  Widget _buildPhotoGrid(List<PhotoGalleryItem> photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return _buildPhotoGridItem(photos[index]);
      },
    );
  }

  Widget _buildPhotoList(List<PhotoGalleryItem> photos) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return _buildPhotoListItem(photos[index]);
      },
    );
  }

  Widget _buildPhotoGridItem(PhotoGalleryItem photo) {
    return GestureDetector(
      onTap: () => _navigateToPhotoDetail(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photo.thumbnailUrl ?? photo.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            if (photo.isHighlighted)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            if (photo.likesCount > 0)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${photo.likesCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildCategoryIcon(photo.category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoListItem(PhotoGalleryItem photo) {
    final timeFormat = DateFormat('MMM dd, HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToPhotoDetail(photo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photo.thumbnailUrl ?? photo.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photo.caption.isNotEmpty)
                      Text(
                        photo.caption,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text(photo.uploaderId.substring(0, 1).toUpperCase()),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          photo.uploaderName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeFormat.format(photo.capturedAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${photo.likesCount}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        _buildCategoryIcon(photo.category),
                        const SizedBox(width: 4),
                        Text(
                          _getCategoryLabel(photo.category),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumCard(PhotoAlbum album) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToAlbumDetail(album),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  album.coverImageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.photo_album,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${album.photoCount} photos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (album.isAutoGenerated) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Auto',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(PhotoCategory category) {
    Color color;
    IconData icon;

    switch (category) {
      case PhotoCategory.keynote:
        color = Colors.purple;
        icon = Icons.campaign;
        break;
      case PhotoCategory.session:
        color = Colors.blue;
        icon = Icons.event_note;
        break;
      case PhotoCategory.networking:
        color = Colors.green;
        icon = Icons.people;
        break;
      case PhotoCategory.meals:
        color = Colors.orange;
        icon = Icons.restaurant;
        break;
      case PhotoCategory.venue:
        color = Colors.brown;
        icon = Icons.location_city;
        break;
      case PhotoCategory.speakers:
        color = Colors.indigo;
        icon = Icons.record_voice_over;
        break;
      case PhotoCategory.attendees:
        color = Colors.teal;
        icon = Icons.groups;
        break;
      case PhotoCategory.exhibits:
        color = Colors.amber;
        icon = Icons.store;
        break;
      case PhotoCategory.social:
        color = Colors.pink;
        icon = Icons.celebration;
        break;
      case PhotoCategory.behind_scenes:
        color = Colors.grey;
        icon = Icons.camera_alt;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon, {bool showCreateButton = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _navigateToUploadPhoto,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Upload Photo'),
              ),
              if (showCreateButton) ...[
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _navigateToCreateAlbum,
                  icon: const Icon(Icons.photo_album),
                  label: const Text('Create Album'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}