import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/conversation.dart';
import '../../models/attendee_profile.dart';
import '../../services/messaging_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_text_field.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessagingService _messagingService = MessagingService();
  final ProfileService _profileService = ProfileService();
  final _searchController = TextEditingController();
  
  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  Map<String, AttendeeProfile> _profilesCache = {};
  bool _isLoading = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      _conversations = await _messagingService.getUserConversations(_currentUserId);
      _filteredConversations = _conversations;
      await _loadProfilesForConversations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadProfilesForConversations() async {
    final userIds = <String>{};
    
    for (final conversation in _conversations) {
      userIds.addAll(conversation.participantIds);
    }
    
    userIds.remove(_currentUserId); // Don't load current user's profile
    
    for (final userId in userIds) {
      if (!_profilesCache.containsKey(userId)) {
        final profile = await _profileService.getProfileByUserId(userId);
        if (profile != null) {
          _profilesCache[userId] = profile;
        }
      }
    }
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conversation) {
          // Search by conversation name
          if (conversation.name.toLowerCase().contains(query.toLowerCase())) {
            return true;
          }
          
          // Search by participant names
          for (final participantId in conversation.participantIds) {
            if (participantId == _currentUserId) continue;
            final profile = _profilesCache[participantId];
            if (profile != null) {
              if (profile.fullName.toLowerCase().contains(query.toLowerCase())) {
                return true;
              }
            }
          }
          
          // Search by last message content
          if (conversation.lastMessage != null) {
            return conversation.lastMessage!.content.toLowerCase().contains(query.toLowerCase());
          }
          
          return false;
        }).toList();
      }
    });
  }

  void _navigateToChat(Conversation conversation) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversation: conversation,
          participantProfiles: _profilesCache,
        ),
      ),
    );
    
    if (result == true) {
      _loadConversations(); // Refresh if there were changes
    }
  }

  void _navigateToNewConversation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewConversationScreen(),
      ),
    );
    
    if (result == true) {
      _loadConversations(); // Refresh if a new conversation was created
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete "${conversation.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _messagingService.deleteConversation(conversation.id);
        _loadConversations();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversation deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting conversation: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: _navigateToNewConversation,
            icon: const Icon(Icons.add_comment),
            tooltip: 'New Message',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              labelText: 'Search conversations',
              prefixIcon: Icons.search,
              onChanged: _filterConversations,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.builder(
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredConversations[index];
                            return _buildConversationTile(conversation);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewConversation,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final otherParticipants = conversation.participantIds
        .where((id) => id != _currentUserId)
        .toList();
    
    String displayName = conversation.name;
    String subtitle = '';
    Widget? leading;

    if (conversation.type == ConversationType.oneOnOne && otherParticipants.isNotEmpty) {
      final otherProfile = _profilesCache[otherParticipants.first];
      if (otherProfile != null) {
        displayName = otherProfile.fullName;
        subtitle = otherProfile.jobTitle ?? otherProfile.email;
        
        leading = CircleAvatar(
          backgroundImage: otherProfile.profileImage != null
              ? NetworkImage(otherProfile.profileImage!)
              : null,
          child: otherProfile.profileImage == null
              ? Text(
                  otherProfile.firstName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        );
      }
    } else if (conversation.type == ConversationType.group) {
      subtitle = '${conversation.participantIds.length} participants';
      leading = CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          Icons.group,
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    final lastMessageTime = conversation.lastMessage?.sentAt;
    final timeString = lastMessageTime != null
        ? DateFormat('HH:mm').format(lastMessageTime)
        : '';

    return Dismissible(
      key: Key(conversation.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: const Text('Are you sure you want to delete this conversation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteConversation(conversation);
      },
      child: ListTile(
        leading: leading ?? const CircleAvatar(child: Icon(Icons.person)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontWeight: conversation.unreadCount > 0 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            if (conversation.lastMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  conversation.lastMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: conversation.unreadCount > 0 
                        ? Colors.black87
                        : Colors.grey[600],
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timeString.isNotEmpty)
              Text(
                timeString,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            if (conversation.isMuted)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.volume_off,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        onTap: () => _navigateToChat(conversation),
        onLongPress: () => _showConversationOptions(conversation),
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(conversation.isMuted ? Icons.volume_up : Icons.volume_off),
              title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
              onTap: () async {
                Navigator.of(context).pop();
                try {
                  await _messagingService.muteConversation(conversation.id, !conversation.isMuted);
                  _loadConversations();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating conversation: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _deleteConversation(conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start networking by sending your first message',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToNewConversation,
            icon: const Icon(Icons.add_comment),
            label: const Text('Start Conversation'),
          ),
        ],
      ),
    );
  }
}