import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/attendee_profile.dart';
import 'database_service.dart';

class MessagingService {
  final DatabaseService _databaseService = DatabaseService();
  
  static final _key = Key.fromSecureRandom(32);
  static final _encrypter = Encrypter(AES(_key));

  Future<List<Conversation>> getUserConversations(String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'participantIds LIKE ?',
      whereArgs: ['%$userId%'],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Conversation.fromJson(maps[i]);
    });
  }

  Future<Conversation> createConversation({
    required List<String> participantIds,
    required String name,
    String? description,
    required ConversationType type,
    String? eventId,
    String? sessionId,
    String? createdBy,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      eventId: eventId,
      sessionId: sessionId,
      name: name,
      description: description,
      type: type,
      participantIds: participantIds,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    final conversationData = conversation.toJson();
    conversationData['participantIds'] = jsonEncode(participantIds);

    await db.insert('conversations', conversationData);
    return conversation;
  }

  Future<List<Message>> getConversationMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'sentAt DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      final messageData = maps[i];
      if (messageData['content'] != null) {
        messageData['content'] = _decryptMessage(messageData['content']);
      }
      return Message.fromJson(messageData);
    }).reversed.toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    String? recipientId,
    required String content,
    MessageType type = MessageType.text,
    String? fileUrl,
    String? fileName,
    Map<String, dynamic>? metadata,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      type: type,
      fileUrl: fileUrl,
      fileName: fileName,
      metadata: metadata ?? {},
      sentAt: now,
    );

    final messageData = message.toJson();
    messageData['content'] = _encryptMessage(content);
    messageData['metadata'] = jsonEncode(metadata ?? {});

    await db.insert('messages', messageData);

    await db.update(
      'conversations',
      {
        'updatedAt': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return message;
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final db = await _databaseService.database;
    final now = DateTime.now();

    await db.update(
      'messages',
      {
        'status': MessageStatus.read.toString().split('.').last,
        'readAt': now.toIso8601String(),
      },
      where: 'conversationId = ? AND senderId != ? AND status != ?',
      whereArgs: [conversationId, userId, MessageStatus.read.toString().split('.').last],
    );

    await db.update(
      'conversations',
      {'unreadCount': 0},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await _databaseService.database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final db = await _databaseService.database;
    await db.update(
      'messages',
      {
        'content': _encryptMessage(newContent),
        'isEdited': 1,
        'editedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<Conversation?> findDirectConversation(String userId1, String userId2) async {
    final conversations = await getUserConversations(userId1);
    
    for (final conversation in conversations) {
      if (conversation.type == ConversationType.oneOnOne &&
          conversation.participantIds.length == 2 &&
          conversation.participantIds.contains(userId1) &&
          conversation.participantIds.contains(userId2)) {
        return conversation;
      }
    }
    
    return null;
  }

  Future<Conversation> getOrCreateDirectConversation(
    String userId1, 
    String userId2,
    AttendeeProfile profile1,
    AttendeeProfile profile2,
  ) async {
    final existingConversation = await findDirectConversation(userId1, userId2);
    if (existingConversation != null) {
      return existingConversation;
    }

    return createConversation(
      participantIds: [userId1, userId2],
      name: '${profile1.firstName} & ${profile2.firstName}',
      type: ConversationType.oneOnOne,
      createdBy: userId1,
    );
  }

  Future<void> addParticipantToConversation(String conversationId, String userId) async {
    final db = await _databaseService.database;
    
    final conversation = await getConversationById(conversationId);
    if (conversation != null && !conversation.participantIds.contains(userId)) {
      final updatedParticipants = [...conversation.participantIds, userId];
      
      await db.update(
        'conversations',
        {
          'participantIds': jsonEncode(updatedParticipants),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    }
  }

  Future<void> removeParticipantFromConversation(String conversationId, String userId) async {
    final db = await _databaseService.database;
    
    final conversation = await getConversationById(conversationId);
    if (conversation != null) {
      final updatedParticipants = conversation.participantIds.where((id) => id != userId).toList();
      
      await db.update(
        'conversations',
        {
          'participantIds': jsonEncode(updatedParticipants),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    }
  }

  Future<Conversation?> getConversationById(String conversationId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Conversation.fromJson(maps.first);
    }
    return null;
  }

  Future<int> getUnreadMessagesCount(String userId) async {
    final conversations = await getUserConversations(userId);
    return conversations.fold<int>(0, (sum, conversation) => sum + conversation.unreadCount);
  }

  Future<List<Message>> searchMessages(String query, String userId) async {
    final db = await _databaseService.database;
    final conversations = await getUserConversations(userId);
    final conversationIds = conversations.map((c) => c.id).toList();
    
    if (conversationIds.isEmpty) return [];
    
    final placeholders = conversationIds.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversationId IN ($placeholders) AND content LIKE ?',
      whereArgs: [...conversationIds, '%$query%'],
      orderBy: 'sentAt DESC',
      limit: 100,
    );

    return List.generate(maps.length, (i) {
      final messageData = maps[i];
      if (messageData['content'] != null) {
        messageData['content'] = _decryptMessage(messageData['content']);
      }
      return Message.fromJson(messageData);
    });
  }

  String _encryptMessage(String content) {
    try {
      final encrypted = _encrypter.encrypt(content);
      return encrypted.base64;
    } catch (e) {
      return content;
    }
  }

  String _decryptMessage(String encryptedContent) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedContent);
      return _encrypter.decrypt(encrypted);
    } catch (e) {
      return encryptedContent;
    }
  }

  Future<void> muteConversation(String conversationId, bool mute) async {
    final db = await _databaseService.database;
    await db.update(
      'conversations',
      {'isMuted': mute ? 1 : 0},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    final db = await _databaseService.database;
    
    await db.transaction((txn) async {
      await txn.delete(
        'messages',
        where: 'conversationId = ?',
        whereArgs: [conversationId],
      );
      
      await txn.delete(
        'conversations',
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    });
  }
}