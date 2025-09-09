import '../models/community_post.dart';
import 'database_service.dart';

class CommunityService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<CommunityPost>> getEventPosts(String eventId, {PostType? filterType}) async {
    final db = await _databaseService.database;
    
    String whereClause = 'eventId = ?';
    List<dynamic> whereArgs = [eventId];
    
    if (filterType != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(filterType.toString().split('.').last);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'community_posts',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'isPinned DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      final postData = maps[i];
      postData['tags'] = (postData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['imageUrls'] = (postData['imageUrls'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['likedByIds'] = (postData['likedByIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['isPinned'] = postData['isPinned'] == 1;
      return CommunityPost.fromJson(postData);
    });
  }

  Future<CommunityPost> createPost(CommunityPost post) async {
    final db = await _databaseService.database;
    
    final postData = post.toJson();
    postData['tags'] = post.tags.join(',');
    postData['imageUrls'] = post.imageUrls.join(',');
    postData['likedByIds'] = post.likedByIds.join(',');
    postData['isPinned'] = post.isPinned ? 1 : 0;

    await db.insert('community_posts', postData);
    return post;
  }

  Future<CommunityPost> updatePost(CommunityPost post) async {
    final db = await _databaseService.database;
    final updatedPost = post.copyWith(updatedAt: DateTime.now());
    
    final postData = updatedPost.toJson();
    postData['tags'] = updatedPost.tags.join(',');
    postData['imageUrls'] = updatedPost.imageUrls.join(',');
    postData['likedByIds'] = updatedPost.likedByIds.join(',');
    postData['isPinned'] = updatedPost.isPinned ? 1 : 0;

    await db.update(
      'community_posts',
      postData,
      where: 'id = ?',
      whereArgs: [post.id],
    );
    
    return updatedPost;
  }

  Future<void> deletePost(String postId) async {
    final db = await _databaseService.database;
    await db.delete(
      'community_posts',
      where: 'id = ?',
      whereArgs: [postId],
    );
  }

  Future<CommunityPost?> getPostById(String postId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'community_posts',
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final postData = maps.first;
      postData['tags'] = (postData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['imageUrls'] = (postData['imageUrls'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['likedByIds'] = (postData['likedByIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['isPinned'] = postData['isPinned'] == 1;
      return CommunityPost.fromJson(postData);
    }
    return null;
  }

  Future<bool> toggleLike(String postId, String userId) async {
    final post = await getPostById(postId);
    if (post == null) return false;

    final likedByIds = List<String>.from(post.likedByIds);
    bool isLiked = false;

    if (likedByIds.contains(userId)) {
      likedByIds.remove(userId);
    } else {
      likedByIds.add(userId);
      isLiked = true;
    }

    final updatedPost = post.copyWith(
      likedByIds: likedByIds,
      likesCount: likedByIds.length,
    );

    await updatePost(updatedPost);
    return isLiked;
  }

  Future<bool> togglePin(String postId) async {
    final post = await getPostById(postId);
    if (post == null) return false;

    final updatedPost = post.copyWith(isPinned: !post.isPinned);
    await updatePost(updatedPost);
    return updatedPost.isPinned;
  }

  Future<List<CommunityPost>> searchPosts(String eventId, String query) async {
    final posts = await getEventPosts(eventId);
    final lowercaseQuery = query.toLowerCase();
    
    return posts.where((post) {
      return post.title.toLowerCase().contains(lowercaseQuery) ||
             post.content.toLowerCase().contains(lowercaseQuery) ||
             post.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<List<CommunityPost>> getUserPosts(String eventId, String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'community_posts',
      where: 'eventId = ? AND authorId = ?',
      whereArgs: [eventId, userId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      final postData = maps[i];
      postData['tags'] = (postData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['imageUrls'] = (postData['imageUrls'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['likedByIds'] = (postData['likedByIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['isPinned'] = postData['isPinned'] == 1;
      return CommunityPost.fromJson(postData);
    });
  }

  Future<List<CommunityPost>> getPinnedPosts(String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'community_posts',
      where: 'eventId = ? AND isPinned = 1',
      whereArgs: [eventId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      final postData = maps[i];
      postData['tags'] = (postData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['imageUrls'] = (postData['imageUrls'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['likedByIds'] = (postData['likedByIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      postData['isPinned'] = postData['isPinned'] == 1;
      return CommunityPost.fromJson(postData);
    });
  }

  Future<List<CommunityPost>> getPopularPosts(String eventId, {int limit = 10}) async {
    final posts = await getEventPosts(eventId);
    posts.sort((a, b) {
      final aScore = a.likesCount * 2 + a.commentsCount;
      final bScore = b.likesCount * 2 + b.commentsCount;
      return bScore.compareTo(aScore);
    });
    return posts.take(limit).toList();
  }

  Future<List<CommunityPost>> getTrendingPosts(String eventId, {int limit = 10}) async {
    final posts = await getEventPosts(eventId);
    final now = DateTime.now();
    
    // Calculate trending score based on engagement and recency
    posts.sort((a, b) {
      final aHoursAgo = now.difference(a.createdAt).inHours + 1;
      final bHoursAgo = now.difference(b.createdAt).inHours + 1;
      
      final aScore = (a.likesCount * 2 + a.commentsCount) / aHoursAgo;
      final bScore = (b.likesCount * 2 + b.commentsCount) / bHoursAgo;
      
      return bScore.compareTo(aScore);
    });
    
    return posts.take(limit).toList();
  }

  Future<Map<PostType, int>> getPostTypeDistribution(String eventId) async {
    final posts = await getEventPosts(eventId);
    final Map<PostType, int> distribution = {};
    
    for (final type in PostType.values) {
      distribution[type] = 0;
    }
    
    for (final post in posts) {
      distribution[post.type] = (distribution[post.type] ?? 0) + 1;
    }
    
    return distribution;
  }

  Future<Map<String, dynamic>> getCommunityStats(String eventId) async {
    final posts = await getEventPosts(eventId);
    
    int totalLikes = 0;
    int totalComments = 0;
    int activePosts = 0;
    int pinnedPosts = 0;
    
    final Set<String> activeUsers = <String>{};
    final Map<String, int> tagCounts = {};
    
    for (final post in posts) {
      totalLikes += post.likesCount;
      totalComments += post.commentsCount;
      activeUsers.add(post.authorId);
      
      if (post.isActive) activePosts++;
      if (post.isPinned) pinnedPosts++;
      
      for (final tag in post.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    final popularTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'totalPosts': posts.length,
      'activePosts': activePosts,
      'pinnedPosts': pinnedPosts,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'activeUsers': activeUsers.length,
      'averageLikesPerPost': posts.isEmpty ? 0.0 : totalLikes / posts.length,
      'averageCommentsPerPost': posts.isEmpty ? 0.0 : totalComments / posts.length,
      'popularTags': popularTags.take(10).map((e) => e.key).toList(),
      'engagementRate': posts.isEmpty ? 0.0 : (totalLikes + totalComments) / posts.length,
    };
  }

  Future<void> moderatePost(String postId, PostStatus newStatus) async {
    final post = await getPostById(postId);
    if (post != null) {
      final updatedPost = post.copyWith(status: newStatus);
      await updatePost(updatedPost);
    }
  }

  Future<List<String>> getPopularTags(String eventId, {int limit = 20}) async {
    final posts = await getEventPosts(eventId);
    final Map<String, int> tagCounts = {};
    
    for (final post in posts) {
      for (final tag in post.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTags.take(limit).map((e) => e.key).toList();
  }

  Future<List<CommunityPost>> getPostsByTag(String eventId, String tag) async {
    final posts = await getEventPosts(eventId);
    return posts.where((post) => post.tags.contains(tag)).toList();
  }

  Future<List<CommunityPost>> getRecentPosts(String eventId, {int hours = 24, int limit = 50}) async {
    final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
    final posts = await getEventPosts(eventId);
    
    return posts
        .where((post) => post.createdAt.isAfter(cutoffTime))
        .take(limit)
        .toList();
  }

  Future<bool> reportPost(String postId, String userId, String reason) async {
    // In a real app, this would create a report record
    // For now, we'll just moderate the post if it gets multiple reports
    final post = await getPostById(postId);
    if (post != null && post.status == PostStatus.active) {
      // Simple auto-moderation: hide posts that are reported
      await moderatePost(postId, PostStatus.hidden);
      return true;
    }
    return false;
  }

  Future<void> incrementCommentCount(String postId) async {
    final post = await getPostById(postId);
    if (post != null) {
      final updatedPost = post.copyWith(commentsCount: post.commentsCount + 1);
      await updatePost(updatedPost);
    }
  }

  Future<void> decrementCommentCount(String postId) async {
    final post = await getPostById(postId);
    if (post != null && post.commentsCount > 0) {
      final updatedPost = post.copyWith(commentsCount: post.commentsCount - 1);
      await updatePost(updatedPost);
    }
  }
}