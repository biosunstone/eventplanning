import '../models/photo_gallery.dart';
import 'database_service.dart';

class PhotoGalleryService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<PhotoGalleryItem>> getEventPhotos(String eventId, {
    PhotoCategory? category,
    PhotoVisibility? visibility,
    String? uploaderId,
  }) async {
    final db = await _databaseService.database;
    
    String whereClause = 'eventId = ? AND isApproved = 1';
    List<dynamic> whereArgs = [eventId];
    
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category.name);
    }
    
    if (visibility != null) {
      whereClause += ' AND visibility = ?';
      whereArgs.add(visibility.name);
    }
    
    if (uploaderId != null) {
      whereClause += ' AND uploaderId = ?';
      whereArgs.add(uploaderId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'photo_gallery',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'capturedAt DESC',
    );

    return List.generate(maps.length, (i) {
      final photoData = maps[i];
      photoData['tags'] = (photoData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      photoData['taggedPeople'] = (photoData['taggedPeople'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      photoData['likedBy'] = (photoData['likedBy'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      photoData['isHighlighted'] = photoData['isHighlighted'] == 1;
      photoData['isApproved'] = photoData['isApproved'] == 1;
      return PhotoGalleryItem.fromJson(photoData);
    });
  }

  Future<PhotoGalleryItem> uploadPhoto(PhotoGalleryItem photo) async {
    final db = await _databaseService.database;
    
    final photoData = photo.toJson();
    photoData['tags'] = photo.tags.join(',');
    photoData['taggedPeople'] = photo.taggedPeople.join(',');
    photoData['likedBy'] = photo.likedBy.join(',');
    photoData['isHighlighted'] = photo.isHighlighted ? 1 : 0;
    photoData['isApproved'] = photo.isApproved ? 1 : 0;

    await db.insert('photo_gallery', photoData);
    return photo;
  }

  Future<PhotoGalleryItem> updatePhoto(PhotoGalleryItem photo) async {
    final db = await _databaseService.database;
    final updatedPhoto = photo.copyWith(uploadedAt: DateTime.now());
    
    final photoData = updatedPhoto.toJson();
    photoData['tags'] = updatedPhoto.tags.join(',');
    photoData['taggedPeople'] = updatedPhoto.taggedPeople.join(',');
    photoData['likedBy'] = updatedPhoto.likedBy.join(',');
    photoData['isHighlighted'] = updatedPhoto.isHighlighted ? 1 : 0;
    photoData['isApproved'] = updatedPhoto.isApproved ? 1 : 0;

    await db.update(
      'photo_gallery',
      photoData,
      where: 'id = ?',
      whereArgs: [photo.id],
    );
    
    return updatedPhoto;
  }

  Future<void> deletePhoto(String photoId) async {
    final db = await _databaseService.database;
    await db.delete(
      'photo_gallery',
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }

  Future<PhotoGalleryItem?> getPhotoById(String photoId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photo_gallery',
      where: 'id = ?',
      whereArgs: [photoId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final photoData = maps.first;
      photoData['tags'] = (photoData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      photoData['taggedPeople'] = (photoData['taggedPeople'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      photoData['likedBy'] = (photoData['likedBy'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      photoData['isHighlighted'] = photoData['isHighlighted'] == 1;
      photoData['isApproved'] = photoData['isApproved'] == 1;
      return PhotoGalleryItem.fromJson(photoData);
    }
    return null;
  }

  Future<bool> toggleLike(String photoId, String userId) async {
    final photo = await getPhotoById(photoId);
    if (photo == null) return false;

    final likedBy = List<String>.from(photo.likedBy);
    bool isLiked = false;

    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
      isLiked = true;
    }

    final updatedPhoto = photo.copyWith(likedBy: likedBy);
    await updatePhoto(updatedPhoto);
    return isLiked;
  }

  Future<List<PhotoGalleryItem>> getHighlightedPhotos(String eventId) async {
    final photos = await getEventPhotos(eventId);
    return photos.where((photo) => photo.isHighlighted).toList();
  }

  Future<List<PhotoGalleryItem>> getRecentPhotos(String eventId, {int limit = 20}) async {
    final photos = await getEventPhotos(eventId);
    return photos.take(limit).toList();
  }

  Future<List<PhotoGalleryItem>> getPopularPhotos(String eventId, {int limit = 20}) async {
    final photos = await getEventPhotos(eventId);
    photos.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    return photos.take(limit).toList();
  }

  Future<List<PhotoGalleryItem>> getUserPhotos(String eventId, String userId) async {
    return getEventPhotos(eventId, uploaderId: userId);
  }

  Future<List<PhotoGalleryItem>> getPhotosWithUser(String eventId, String userId) async {
    final photos = await getEventPhotos(eventId);
    return photos.where((photo) => photo.taggedPeople.contains(userId)).toList();
  }

  Future<List<PhotoGalleryItem>> searchPhotos(String eventId, String query) async {
    final photos = await getEventPhotos(eventId);
    final lowercaseQuery = query.toLowerCase();
    
    return photos.where((photo) {
      return photo.caption.toLowerCase().contains(lowercaseQuery) ||
             photo.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
             photo.location?.toLowerCase().contains(lowercaseQuery) == true;
    }).toList();
  }

  Future<Map<PhotoCategory, int>> getPhotoDistribution(String eventId) async {
    final photos = await getEventPhotos(eventId);
    final Map<PhotoCategory, int> distribution = {};
    
    for (final category in PhotoCategory.values) {
      distribution[category] = 0;
    }
    
    for (final photo in photos) {
      distribution[photo.category] = (distribution[photo.category] ?? 0) + 1;
    }
    
    return distribution;
  }

  Future<void> incrementDownloadCount(String photoId) async {
    final photo = await getPhotoById(photoId);
    if (photo != null) {
      final updatedPhoto = photo.copyWith(downloadCount: photo.downloadCount + 1);
      await updatePhoto(updatedPhoto);
    }
  }

  // Album Management
  Future<List<PhotoAlbum>> getEventAlbums(String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photo_albums',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      final albumData = maps[i];
      albumData['photoIds'] = (albumData['photoIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      albumData['isAutoGenerated'] = albumData['isAutoGenerated'] == 1;
      return PhotoAlbum.fromJson(albumData);
    });
  }

  Future<PhotoAlbum> createAlbum(PhotoAlbum album) async {
    final db = await _databaseService.database;
    
    final albumData = album.toJson();
    albumData['photoIds'] = album.photoIds.join(',');
    albumData['isAutoGenerated'] = album.isAutoGenerated ? 1 : 0;

    await db.insert('photo_albums', albumData);
    return album;
  }

  Future<PhotoAlbum> updateAlbum(PhotoAlbum album) async {
    final db = await _databaseService.database;
    final updatedAlbum = album.copyWith(updatedAt: DateTime.now());
    
    final albumData = updatedAlbum.toJson();
    albumData['photoIds'] = updatedAlbum.photoIds.join(',');
    albumData['isAutoGenerated'] = updatedAlbum.isAutoGenerated ? 1 : 0;

    await db.update(
      'photo_albums',
      albumData,
      where: 'id = ?',
      whereArgs: [album.id],
    );
    
    return updatedAlbum;
  }

  Future<void> deleteAlbum(String albumId) async {
    final db = await _databaseService.database;
    await db.delete(
      'photo_albums',
      where: 'id = ?',
      whereArgs: [albumId],
    );
  }

  Future<PhotoAlbum?> getAlbumById(String albumId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photo_albums',
      where: 'id = ?',
      whereArgs: [albumId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final albumData = maps.first;
      albumData['photoIds'] = (albumData['photoIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      albumData['isAutoGenerated'] = albumData['isAutoGenerated'] == 1;
      return PhotoAlbum.fromJson(albumData);
    }
    return null;
  }

  Future<List<PhotoGalleryItem>> getAlbumPhotos(String albumId) async {
    final album = await getAlbumById(albumId);
    if (album == null) return [];

    final List<PhotoGalleryItem> photos = [];
    for (final photoId in album.photoIds) {
      final photo = await getPhotoById(photoId);
      if (photo != null) {
        photos.add(photo);
      }
    }
    
    // Sort by captured date
    photos.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return photos;
  }

  Future<void> addPhotoToAlbum(String albumId, String photoId) async {
    final album = await getAlbumById(albumId);
    if (album != null && !album.photoIds.contains(photoId)) {
      final updatedPhotoIds = [...album.photoIds, photoId];
      final updatedAlbum = album.copyWith(photoIds: updatedPhotoIds);
      await updateAlbum(updatedAlbum);
    }
  }

  Future<void> removePhotoFromAlbum(String albumId, String photoId) async {
    final album = await getAlbumById(albumId);
    if (album != null) {
      final updatedPhotoIds = album.photoIds.where((id) => id != photoId).toList();
      final updatedAlbum = album.copyWith(photoIds: updatedPhotoIds);
      await updateAlbum(updatedAlbum);
    }
  }

  // Auto-generate albums by category
  Future<void> generateCategoryAlbums(String eventId) async {
    final photos = await getEventPhotos(eventId);
    final photosByCategory = <PhotoCategory, List<PhotoGalleryItem>>{};
    
    // Group photos by category
    for (final photo in photos) {
      photosByCategory.putIfAbsent(photo.category, () => []).add(photo);
    }
    
    // Create albums for categories with photos
    for (final entry in photosByCategory.entries) {
      if (entry.value.isNotEmpty) {
        final album = PhotoAlbum(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          eventId: eventId,
          name: _getCategoryDisplayName(entry.key),
          description: 'Auto-generated album for ${_getCategoryDisplayName(entry.key).toLowerCase()} photos',
          coverImageUrl: entry.value.first.thumbnailUrl ?? entry.value.first.imageUrl,
          createdBy: 'system',
          photoIds: entry.value.map((p) => p.id).toList(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isAutoGenerated: true,
          category: entry.key,
        );
        
        await createAlbum(album);
      }
    }
  }

  String _getCategoryDisplayName(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.keynote:
        return 'Keynote';
      case PhotoCategory.session:
        return 'Sessions';
      case PhotoCategory.networking:
        return 'Networking';
      case PhotoCategory.meals:
        return 'Meals & Breaks';
      case PhotoCategory.venue:
        return 'Venue';
      case PhotoCategory.speakers:
        return 'Speakers';
      case PhotoCategory.attendees:
        return 'Attendees';
      case PhotoCategory.exhibits:
        return 'Exhibits';
      case PhotoCategory.social:
        return 'Social Events';
      case PhotoCategory.behind_scenes:
        return 'Behind the Scenes';
    }
  }

  Future<Map<String, dynamic>> getGalleryStats(String eventId) async {
    final photos = await getEventPhotos(eventId);
    final albums = await getEventAlbums(eventId);
    
    int totalLikes = 0;
    int totalDownloads = 0;
    final Set<String> contributors = <String>{};
    final Map<String, int> tagCounts = {};
    
    for (final photo in photos) {
      totalLikes += photo.likesCount;
      totalDownloads += photo.downloadCount;
      contributors.add(photo.uploaderId);
      
      for (final tag in photo.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    final popularTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'totalPhotos': photos.length,
      'totalAlbums': albums.length,
      'totalLikes': totalLikes,
      'totalDownloads': totalDownloads,
      'totalContributors': contributors.length,
      'averageLikesPerPhoto': photos.isEmpty ? 0.0 : totalLikes / photos.length,
      'popularTags': popularTags.take(10).map((e) => e.key).toList(),
      'categoryDistribution': await getPhotoDistribution(eventId),
      'mostLikedPhoto': photos.isNotEmpty 
          ? photos.reduce((a, b) => a.likesCount > b.likesCount ? a : b).id
          : null,
      'mostDownloadedPhoto': photos.isNotEmpty 
          ? photos.reduce((a, b) => a.downloadCount > b.downloadCount ? a : b).id
          : null,
    };
  }

  Future<List<String>> getPopularTags(String eventId, {int limit = 20}) async {
    final photos = await getEventPhotos(eventId);
    final Map<String, int> tagCounts = {};
    
    for (final photo in photos) {
      for (final tag in photo.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTags.take(limit).map((e) => e.key).toList();
  }

  Future<void> highlightPhoto(String photoId, bool highlight) async {
    final photo = await getPhotoById(photoId);
    if (photo != null) {
      final updatedPhoto = photo.copyWith(isHighlighted: highlight);
      await updatePhoto(updatedPhoto);
    }
  }

  Future<void> moderatePhoto(String photoId, bool approve) async {
    final photo = await getPhotoById(photoId);
    if (photo != null) {
      final updatedPhoto = photo.copyWith(isApproved: approve);
      await updatePhoto(updatedPhoto);
    }
  }
}