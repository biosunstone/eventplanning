import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/attendee_profile.dart';
import '../../services/messaging_service.dart';
import '../../widgets/custom_text_field.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final Map<String, AttendeeProfile> participantProfiles;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.participantProfiles,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessagingService _messagingService = MessagingService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      _messages = await _messagingService.getConversationMessages(widget.conversation.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _markAsRead() async {
    // TODO: Implement markConversationAsRead
    // try {
    //   await _messagingService.markConversationAsRead(widget.conversation.id, _currentUserId);
    // } catch (e) {
    //   // Silently handle error
    // }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _currentUserId,
        content: text,
        type: MessageType.text,
      );
      _messageController.clear();
      await _loadMessages(); // Refresh messages
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }

    setState(() => _isSending = false);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _getConversationTitle() {
    if (widget.conversation.type == ConversationType.oneOnOne) {
      final otherParticipant = widget.conversation.participantIds
          .firstWhere((id) => id != _currentUserId, orElse: () => '');
      final profile = widget.participantProfiles[otherParticipant];
      return profile?.fullName ?? 'Unknown User';
    } else {
      return widget.conversation.name;
    }
  }

  String _getConversationSubtitle() {
    if (widget.conversation.type == ConversationType.oneOnOne) {
      final otherParticipant = widget.conversation.participantIds
          .firstWhere((id) => id != _currentUserId, orElse: () => '');
      final profile = widget.participantProfiles[otherParticipant];
      return profile?.jobTitle ?? profile?.email ?? '';
    } else {
      return '${widget.conversation.participantIds.length} participants';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getConversationTitle(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_getConversationSubtitle().isNotEmpty)
              Text(
                _getConversationSubtitle(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        actions: [
          if (widget.conversation.type == ConversationType.oneOnOne)
            IconButton(
              onPressed: _showUserProfile,
              icon: const Icon(Icons.person),
              tooltip: 'View Profile',
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(widget.conversation.isMuted ? Icons.volume_up : Icons.volume_off),
                    const SizedBox(width: 8),
                    Text(widget.conversation.isMuted ? 'Unmute' : 'Mute'),
                  ],
                ),
              ),
              if (widget.conversation.type == ConversationType.group)
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info),
                      SizedBox(width: 8),
                      Text('Group Info'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Chat', style: TextStyle(color: Colors.red)),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _currentUserId;
                          final showAvatar = !isMe && 
                              widget.conversation.type == ConversationType.group &&
                              (index == _messages.length - 1 || 
                               _messages[index + 1].senderId != message.senderId);
                          
                          return _buildMessageBubble(message, isMe, showAvatar);
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showAvatar) {
    final profile = widget.participantProfiles[message.senderId];
    final timeFormat = DateFormat('HH:mm');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: profile?.profileImage != null
                  ? NetworkImage(profile!.profileImage!)
                  : null,
              child: profile?.profileImage == null
                  ? Text(
                      profile?.firstName.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && widget.conversation.type == ConversationType.group)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 12),
                    child: Text(
                      profile?.firstName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe 
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: !isMe ? const Radius.circular(4) : null,
                      bottomRight: isMe ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeFormat.format(message.sentAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.readAt != null
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 14,
                              color: message.readAt != null
                                  ? Colors.blue[300]
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
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
            Expanded(
              child: CustomTextField(
                controller: _messageController,
                labelText: '',
                hintText: 'Type a message...',
                maxLines: 5,
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              onPressed: _messageController.text.trim().isNotEmpty && !_isSending
                  ? _sendMessage
                  : null,
              backgroundColor: _messageController.text.trim().isNotEmpty && !_isSending
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              child: _isSending
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
            'No messages yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending your first message',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'mute':
        try {
          await _messagingService.muteConversation(
            widget.conversation.id, 
            !widget.conversation.isMuted,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.conversation.isMuted 
                    ? 'Conversation unmuted' 
                    : 'Conversation muted'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating conversation: $e')),
            );
          }
        }
        break;
      case 'info':
        _showGroupInfo();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showUserProfile() {
    final otherParticipant = widget.conversation.participantIds
        .firstWhere((id) => id != _currentUserId, orElse: () => '');
    final profile = widget.participantProfiles[otherParticipant];
    
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: profile.profileImage != null
                  ? NetworkImage(profile.profileImage!)
                  : null,
              child: profile.profileImage == null
                  ? Text(
                      profile.firstName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (profile.jobTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                profile.jobTitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (profile.company != null) ...[
              const SizedBox(height: 4),
              Text(
                profile.company!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Group Name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(widget.conversation.name),
            const SizedBox(height: 16),
            Text(
              'Participants (${widget.conversation.participantIds.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...widget.conversation.participantIds.map((participantId) {
              final profile = widget.participantProfiles[participantId];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: profile?.profileImage != null
                      ? NetworkImage(profile!.profileImage!)
                      : null,
                  child: profile?.profileImage == null
                      ? Text(profile?.firstName.substring(0, 1).toUpperCase() ?? '?')
                      : null,
                ),
                title: Text(profile?.fullName ?? 'Unknown User'),
                subtitle: Text(profile?.jobTitle ?? profile?.email ?? ''),
                trailing: participantId == _currentUserId
                    ? const Chip(label: Text('You'))
                    : null,
              );
            }).toList(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              try {
                await _messagingService.deleteConversation(widget.conversation.id);
                if (mounted) {
                  Navigator.of(context).pop(true); // Return to conversations with refresh flag
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting conversation: $e')),
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