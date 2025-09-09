import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/community_post.dart';
import '../../services/community_service.dart';
import '../../widgets/custom_text_field.dart';

class PostDetailScreen extends StatefulWidget {
  final Event event;
  final CommunityPost post;

  const PostDetailScreen({
    super.key,
    required this.event,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  CommunityPost? _post;
  bool _isLoading = false;
  bool _isCommenting = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadPostDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    setState(() => _isLoading = true);

    try {
      final updatedPost = await _communityService.getPostById(widget.post.id);
      if (updatedPost != null) {
        setState(() => _post = updatedPost);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;

    try {
      final isLiked = await _communityService.toggleLike(_post!.id, _currentUserId);
      
      // Update local state immediately for better UX
      setState(() {
        final likedByIds = List<String>.from(_post!.likedByIds);
        if (isLiked) {
          likedByIds.add(_currentUserId);
        } else {
          likedByIds.remove(_currentUserId);
        }
        _post = _post!.copyWith(
          likedByIds: likedByIds,
          likesCount: likedByIds.length,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_post == null || _commentController.text.trim().isEmpty) return;

    setState(() => _isCommenting = true);

    try {
      // In a real app, you would have a comment service
      // For now, we'll just increment the comment count
      await _communityService.incrementCommentCount(_post!.id);
      
      _commentController.clear();
      await _loadPostDetails(); // Reload to get updated comment count

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    }

    setState(() => _isCommenting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_post == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final timeFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final isLiked = _post!.likedByIds.contains(_currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          if (_post!.authorId == _currentUserId)
            PopupMenuButton<String>(
              onSelected: _handlePostAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Post'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Post', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(),
                  const SizedBox(height: 16),
                  _buildPostContent(),
                  const SizedBox(height: 16),
                  _buildPostDetails(),
                  const SizedBox(height: 16),
                  _buildPostImages(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          child: Text(_post!.authorId.substring(0, 1).toUpperCase()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User ${_post!.authorId}', // In real app, get from profile
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy • HH:mm').format(_post!.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildPostTypeChip(_post!.type),
      ],
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _post!.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _post!.content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildPostDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_post!.location != null) ...[
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _post!.location!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (_post!.eventDate != null) ...[
          Row(
            children: [
              const Icon(Icons.event, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM dd, yyyy • HH:mm').format(_post!.eventDate!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (_post!.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _post!.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPostImages() {
    if (_post!.imageUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _post!.imageUrls.length,
            itemBuilder: (context, index) {
              final imageUrl = _post!.imageUrls[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        InkWell(
          onTap: _toggleLike,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _post!.likedByIds.contains(_currentUserId)
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _post!.likedByIds.contains(_currentUserId) ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _post!.likedByIds.contains(_currentUserId) ? Colors.red : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${_post!.likesCount} ${_post!.likesCount == 1 ? 'Like' : 'Likes'}',
                  style: TextStyle(
                    color: _post!.likedByIds.contains(_currentUserId) ? Colors.red : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${_post!.commentsCount} ${_post!.commentsCount == 1 ? 'Comment' : 'Comments'}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            // Share functionality
          },
          icon: const Icon(Icons.share),
          tooltip: 'Share',
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${_post!.commentsCount})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_post!.commentsCount == 0)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No comments yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share your thoughts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          // In a real app, you would load and display actual comments here
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _post!.commentsCount,
            itemBuilder: (context, index) {
              return _buildCommentItem(index);
            },
          ),
      ],
    );
  }

  Widget _buildCommentItem(int index) {
    // Mock comment data - in real app, load from comment service
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            child: Text('U${index + 1}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'User ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '2h ago',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This is a sample comment. In a real app, this would be loaded from a comment service.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${index * 2 + 1}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {},
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(_currentUserId.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _commentController,
                labelText: '',
                hintText: 'Add a comment...',
                maxLines: 3,
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              onPressed: _commentController.text.trim().isNotEmpty && !_isCommenting
                  ? _addComment
                  : null,
              backgroundColor: _commentController.text.trim().isNotEmpty && !_isCommenting
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              child: _isCommenting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            _getPostTypeLabel(type),
            style: TextStyle(
              color: color,
              fontSize: 12,
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

  void _handlePostAction(String action) async {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
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
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              try {
                await _communityService.deletePost(_post!.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Return to community board
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
}