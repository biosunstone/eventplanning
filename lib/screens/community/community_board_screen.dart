import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/community_post.dart';
import '../../services/community_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_fab.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityBoardScreen extends StatefulWidget {
  final Event event;

  const CommunityBoardScreen({super.key, required this.event});

  @override
  State<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

class _CommunityBoardScreenState extends State<CommunityBoardScreen>
    with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<CommunityPost> _allPosts = [];
  List<CommunityPost> _filteredPosts = [];
  List<CommunityPost> _pinnedPosts = [];
  List<CommunityPost> _trendingPosts = [];
  PostType? _selectedFilter;
  bool _isLoading = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      _allPosts = await _communityService.getEventPosts(widget.event.id);
      _filteredPosts = List.from(_allPosts);
      _pinnedPosts = await _communityService.getPinnedPosts(widget.event.id);
      _trendingPosts = await _communityService.getTrendingPosts(widget.event.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _filterPosts({String? query, PostType? type}) {
    setState(() {
      _selectedFilter = type;
      List<CommunityPost> posts = _allPosts;

      // Filter by type
      if (type != null) {
        posts = posts.where((post) => post.type == type).toList();
      }

      // Filter by search query
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        posts = posts.where((post) {
          return post.title.toLowerCase().contains(lowercaseQuery) ||
                 post.content.toLowerCase().contains(lowercaseQuery) ||
                 post.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
        }).toList();
      }

      _filteredPosts = posts;
    });
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(event: widget.event),
      ),
    ).then((_) => _loadPosts());
  }

  void _navigateToPostDetail(CommunityPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          event: widget.event,
          post: post,
        ),
      ),
    ).then((_) => _loadPosts());
  }

  Future<void> _toggleLike(CommunityPost post) async {
    try {
      await _communityService.toggleLike(post.id, _currentUserId);
      _loadPosts(); // Refresh to show updated like count
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
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
            const Text('Community Board'),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToCreatePost,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Post',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Posts', icon: Icon(Icons.forum)),
            Tab(text: 'Pinned', icon: Icon(Icons.push_pin)),
            Tab(text: 'Trending', icon: Icon(Icons.trending_up)),
            Tab(text: 'My Posts', icon: Icon(Icons.person)),
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
                      _buildAllPostsTab(),
                      _buildPinnedPostsTab(),
                      _buildTrendingPostsTab(),
                      _buildMyPostsTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: CustomFAB(
        onPressed: _navigateToCreatePost,
        icon: Icons.add,
        label: 'New Post',
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
            labelText: 'Search posts...',
            prefixIcon: Icons.search,
            onChanged: (query) => _filterPosts(query: query, type: _selectedFilter),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                ...PostType.values.map((type) => _buildFilterChip(_getPostTypeLabel(type), type)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PostType? type) {
    final isSelected = _selectedFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          _filterPosts(
            query: _searchController.text,
            type: selected ? type : null,
          );
        },
      ),
    );
  }

  Widget _buildAllPostsTab() {
    if (_filteredPosts.isEmpty) {
      return _buildEmptyState(
        'No posts found',
        _searchController.text.isNotEmpty || _selectedFilter != null
            ? 'Try adjusting your search or filter'
            : 'Be the first to start a conversation',
        Icons.forum_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredPosts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_filteredPosts[index]);
        },
      ),
    );
  }

  Widget _buildPinnedPostsTab() {
    if (_pinnedPosts.isEmpty) {
      return _buildEmptyState(
        'No pinned posts',
        'Important posts will appear here when pinned',
        Icons.push_pin_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pinnedPosts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_pinnedPosts[index], showPinIcon: true);
      },
    );
  }

  Widget _buildTrendingPostsTab() {
    if (_trendingPosts.isEmpty) {
      return _buildEmptyState(
        'No trending posts',
        'Popular posts will appear here based on engagement',
        Icons.trending_up_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trendingPosts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_trendingPosts[index], showTrendingIcon: true);
      },
    );
  }

  Widget _buildMyPostsTab() {
    return FutureBuilder<List<CommunityPost>>(
      future: _communityService.getUserPosts(widget.event.id, _currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final myPosts = snapshot.data ?? [];
        
        if (myPosts.isEmpty) {
          return _buildEmptyState(
            'No posts yet',
            'Share your thoughts with the community',
            Icons.person_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myPosts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(myPosts[index], showAuthorActions: true);
          },
        );
      },
    );
  }

  Widget _buildPostCard(CommunityPost post, {
    bool showPinIcon = false,
    bool showTrendingIcon = false,
    bool showAuthorActions = false,
  }) {
    final timeFormat = DateFormat('MMM dd, HH:mm');
    final isLiked = post.likedByIds.contains(_currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: post.isPinned ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: post.isPinned 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _navigateToPostDetail(post),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(post.authorId.substring(0, 1).toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ${post.authorId}', // In real app, get from profile
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeFormat.format(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (showPinIcon)
                        Icon(
                          Icons.push_pin,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      if (showTrendingIcon)
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                      _buildPostTypeChip(post.type),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        post.location!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
                    onTap: () => _toggleLike(post),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isLiked ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  InkWell(
                    onTap: () => _navigateToPostDetail(post),
                    child: Row(
                      children: [
                        Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${post.commentsCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (showAuthorActions)
                    PopupMenuButton<String>(
                      onSelected: (action) => _handlePostAction(action, post),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
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
                      child: Icon(Icons.more_vert, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeChip(PostType type) {
    Color color;
    IconData icon;
    
    switch (type) {
      case PostType.announcement:
        color = Colors.red;
        icon = Icons.campaign;
        break;
      case PostType.question:
        color = Colors.blue;
        icon = Icons.help;
        break;
      case PostType.meetup:
        color = Colors.green;
        icon = Icons.people;
        break;
      case PostType.rideshare:
        color = Colors.orange;
        icon = Icons.directions_car;
        break;
      case PostType.jobPosting:
        color = Colors.purple;
        icon = Icons.work;
        break;
      case PostType.recommendation:
        color = Colors.teal;
        icon = Icons.star;
        break;
      case PostType.lostFound:
        color = Colors.amber;
        icon = Icons.search;
        break;
      default:
        color = Colors.grey;
        icon = Icons.forum;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _getPostTypeLabel(type),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
        return 'Job';
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

  void _handlePostAction(String action, CommunityPost post) async {
    switch (action) {
      case 'edit':
        // Navigate to edit post screen
        break;
      case 'delete':
        _showDeleteConfirmation(post);
        break;
    }
  }

  void _showDeleteConfirmation(CommunityPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _communityService.deletePost(post.id);
                _loadPosts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting post: $e')),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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
          ElevatedButton.icon(
            onPressed: _navigateToCreatePost,
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
          ),
        ],
      ),
    );
  }
}