import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/virtual_event.dart';
import '../../services/virtual_event_service.dart';
import '../../services/gamification_service.dart';

class LiveStreamScreen extends StatefulWidget {
  final Event event;
  final VirtualSession session;

  const LiveStreamScreen({
    super.key,
    required this.event,
    required this.session,
  });

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen>
    with TickerProviderStateMixin {
  final VirtualEventService _virtualEventService = VirtualEventService();
  final GamificationService _gamificationService = GamificationService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  List<StreamMessage> _messages = [];
  List<StreamReaction> _floatingReactions = [];
  Map<String, int> _reactionCounts = {};
  int _currentViewers = 0;
  bool _isLoading = false;
  bool _isChatExpanded = false;
  bool _showReactionPanel = false;
  Timer? _reactionTimer;
  Timer? _updateTimer;
  
  late AnimationController _reactionAnimationController;
  late AnimationController _chatAnimationController;
  
  String _currentUserId = 'user1'; // Get from auth provider in real app
  String _currentUserName = 'John Doe'; // Get from auth provider in real app

  final List<String> _availableReactions = [
    '👏', '❤️', '😂', '😮', '👍', '🔥', '🎉', '💯', '🤔', '😍'
  ];

  @override
  void initState() {
    super.initState();
    
    _reactionAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _chatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _joinSession();
    _loadData();
    _startUpdates();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    _reactionTimer?.cancel();
    _updateTimer?.cancel();
    _reactionAnimationController.dispose();
    _chatAnimationController.dispose();
    _leaveSession();
    super.dispose();
  }

  Future<void> _joinSession() async {
    try {
      await _virtualEventService.joinSession(
        widget.session.id,
        _currentUserId,
        ViewerRole.attendee,
      );
      
      // Award points for joining session
      await _gamificationService.awardPoints(
        _currentUserId,
        widget.event.id,
        'session_checkin',
        metadata: {
          'sessionId': widget.session.id,
          'sessionTitle': widget.session.title,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining session: $e')),
        );
      }
    }
  }

  Future<void> _leaveSession() async {
    try {
      await _virtualEventService.leaveSession(widget.session.id, _currentUserId);
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Generate demo messages if needed
      final existingMessages = await _virtualEventService.getSessionMessages(widget.session.id);
      if (existingMessages.isEmpty) {
        await _virtualEventService.generateDemoMessages(widget.session.id, widget.session.title);
      }

      final results = await Future.wait([
        _virtualEventService.getSessionMessages(widget.session.id),
        _virtualEventService.getReactionCounts(widget.session.id),
        _virtualEventService.getCurrentViewers(widget.session.id),
      ]);

      _messages = results[0] as List<StreamMessage>;
      _reactionCounts = results[1] as Map<String, int>;
      final viewers = results[2] as List<ViewerSession>;
      _currentViewers = viewers.length + Random().nextInt(50) + 20; // Add some simulated viewers

      if (mounted) setState(() {});
      
      // Auto-scroll to bottom of chat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stream data: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _startUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadData();
    });
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final message = StreamMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: widget.session.id,
      userId: _currentUserId,
      userName: _currentUserName,
      message: _chatController.text.trim(),
      timestamp: DateTime.now(),
      type: InteractionType.chat,
    );

    try {
      await _virtualEventService.sendMessage(message);
      
      // Award points for messaging
      await _gamificationService.awardPoints(
        _currentUserId,
        widget.event.id,
        'message_sent',
      );
      
      _chatController.clear();
      _loadData(); // Refresh messages
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _sendReaction(String reaction) async {
    final streamReaction = StreamReaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: widget.session.id,
      userId: _currentUserId,
      reaction: reaction,
      timestamp: DateTime.now(),
      x: Random().nextDouble() * MediaQuery.of(context).size.width * 0.8 + 0.1,
      y: MediaQuery.of(context).size.height * 0.7,
    );

    try {
      await _virtualEventService.addReaction(streamReaction);
      
      // Add floating animation
      setState(() {
        _floatingReactions.add(streamReaction);
        _reactionCounts[reaction] = (_reactionCounts[reaction] ?? 0) + 1;
      });

      // Remove reaction after animation
      _reactionTimer?.cancel();
      _reactionTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _floatingReactions.removeWhere((r) => r.id == streamReaction.id);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reaction: $e')),
        );
      }
    }
  }

  void _toggleChat() {
    setState(() {
      _isChatExpanded = !_isChatExpanded;
    });
    
    if (_isChatExpanded) {
      _chatAnimationController.forward();
    } else {
      _chatAnimationController.reverse();
    }
  }

  void _toggleReactionPanel() {
    setState(() {
      _showReactionPanel = !_showReactionPanel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildVideoPlayer(),
            _buildStreamOverlay(),
            if (_showReactionPanel) _buildReactionPanel(),
            _buildFloatingReactions(),
            if (_isChatExpanded) _buildExpandedChat(),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: const Icon(
                Icons.play_circle_fill,
                size: 100,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Video Player Placeholder',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'In a real app, this would integrate with video streaming SDKs like Agora, WebRTC, or similar',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          _buildStreamHeader(),
          const SizedBox(height: 12),
          _buildStreamStats(),
        ],
      ),
    );
  }

  Widget _buildStreamHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.session.isLive ? Colors.red : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.session.isLive ? Icons.circle : Icons.schedule,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.session.isLive ? 'LIVE' : 'SCHEDULED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.session.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.session.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.session.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '$_currentViewers',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.chat, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${_messages.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_reactionCounts.isNotEmpty) ...[
            const SizedBox(width: 16),
            const Icon(Icons.favorite, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              '${_reactionCounts.values.fold(0, (a, b) => a + b)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingReactions() {
    return Stack(
      children: _floatingReactions.map((reaction) {
        return AnimatedBuilder(
          animation: _reactionAnimationController,
          builder: (context, child) {
            return Positioned(
              left: reaction.x,
              bottom: reaction.y! - (_reactionAnimationController.value * 200),
              child: Opacity(
                opacity: 1.0 - _reactionAnimationController.value,
                child: Transform.scale(
                  scale: 1.0 + (_reactionAnimationController.value * 0.5),
                  child: Text(
                    reaction.reaction,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildReactionPanel() {
    return Positioned(
      bottom: 120,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'React',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableReactions.map((reaction) {
                final count = _reactionCounts[reaction] ?? 0;
                return GestureDetector(
                  onTap: () {
                    _sendReaction(reaction);
                    _toggleReactionPanel();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(reaction, style: const TextStyle(fontSize: 24)),
                        if (count > 0)
                          Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedChat() {
    return Positioned(
      bottom: 70,
      left: 16,
      right: 16,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Live Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleChat,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildChatMessage(_messages[index]);
                },
              ),
            ),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(StreamMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isFromModerator)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'MOD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${message.userName}: ',
                    style: TextStyle(
                      color: message.isFromModerator ? Colors.blue : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: message.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            if (!_isChatExpanded) _buildMiniChat(),
            if (!_isChatExpanded) const Spacer(),
            _buildControlButton(
              icon: Icons.chat,
              onPressed: _toggleChat,
              isActive: _isChatExpanded,
            ),
            const SizedBox(width: 12),
            _buildControlButton(
              icon: Icons.emoji_emotions,
              onPressed: _toggleReactionPanel,
              isActive: _showReactionPanel,
            ),
            const SizedBox(width: 12),
            _buildControlButton(
              icon: Icons.people,
              onPressed: _showParticipants,
            ),
            const SizedBox(width: 12),
            _buildControlButton(
              icon: Icons.more_vert,
              onPressed: _showMoreOptions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChat() {
    if (_messages.isEmpty) return const SizedBox.shrink();
    
    final lastMessage = _messages.last;
    return Expanded(
      child: GestureDetector(
        onTap: _toggleChat,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${lastMessage.userName}: ${lastMessage.message}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Participants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_currentViewers viewers',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: min(_currentViewers, 20), // Show up to 20 participants
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'.substring(0, 1)),
                    ),
                    title: Text('Participant ${index + 1}'),
                    subtitle: const Text('Viewer'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Audio Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video Quality'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.fullscreen),
              title: const Text('Full Screen'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Issue'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}