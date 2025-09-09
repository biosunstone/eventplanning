import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../models/attendee_profile.dart';
import '../../services/messaging_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen>
    with SingleTickerProviderStateMixin {
  final MessagingService _messagingService = MessagingService();
  final ProfileService _profileService = ProfileService();
  final _searchController = TextEditingController();
  final _groupNameController = TextEditingController();
  late TabController _tabController;

  List<AttendeeProfile> _allProfiles = [];
  List<AttendeeProfile> _filteredProfiles = [];
  Set<String> _selectedParticipants = <String>{};
  bool _isLoading = false;
  bool _isCreating = false;
  String _currentUserId = 'user1'; // Get from auth provider in real app

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);

    try {
      _allProfiles = await _profileService.getNetworkingEnabledProfiles();
      _allProfiles.removeWhere((profile) => profile.userId == _currentUserId);
      _filteredProfiles = List.from(_allProfiles);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _filterProfiles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProfiles = List.from(_allProfiles);
      } else {
        _filteredProfiles = _allProfiles.where((profile) {
          final searchTerm = query.toLowerCase();
          return profile.fullName.toLowerCase().contains(searchTerm) ||
                 profile.email.toLowerCase().contains(searchTerm) ||
                 (profile.company?.toLowerCase().contains(searchTerm) ?? false) ||
                 (profile.jobTitle?.toLowerCase().contains(searchTerm) ?? false);
        }).toList();
      }
    });
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedParticipants.contains(userId)) {
        _selectedParticipants.remove(userId);
      } else {
        _selectedParticipants.add(userId);
      }
    });
  }

  Future<void> _createOneOnOneConversation() async {
    if (_selectedParticipants.length != 1) return;

    setState(() => _isCreating = true);

    try {
      final otherUserId = _selectedParticipants.first;
      final otherProfile = _allProfiles.firstWhere((p) => p.userId == otherUserId);

      // Check if conversation already exists
      final existingConversation = await _messagingService.findDirectConversation(
        _currentUserId, 
        otherUserId,
      );

      if (existingConversation != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversation already exists')),
          );
          Navigator.of(context).pop(true);
        }
        return;
      }

      final conversation = await _messagingService.createConversation(
        participantIds: [_currentUserId, otherUserId],
        name: otherProfile.fullName,
        type: ConversationType.oneOnOne,
        createdBy: _currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating conversation: $e')),
        );
      }
    }

    setState(() => _isCreating = false);
  }

  Future<void> _createGroupConversation() async {
    if (_selectedParticipants.length < 2 || _groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 participants and enter a group name')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final conversation = await _messagingService.createConversation(
        participantIds: [_currentUserId, ..._selectedParticipants],
        name: _groupNameController.text.trim(),
        type: ConversationType.group,
        createdBy: _currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group conversation created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }

    setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Conversation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Direct Message'),
            Tab(text: 'Group Chat'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              labelText: 'Search people',
              prefixIcon: Icons.search,
              onChanged: _filterProfiles,
            ),
          ),
          if (_selectedParticipants.isNotEmpty)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected (${_selectedParticipants.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedParticipants.length,
                      itemBuilder: (context, index) {
                        final userId = _selectedParticipants.elementAt(index);
                        final profile = _allProfiles.firstWhere((p) => p.userId == userId);
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: profile.profileImage != null
                                        ? NetworkImage(profile.profileImage!)
                                        : null,
                                    child: profile.profileImage == null
                                        ? Text(profile.firstName.substring(0, 1).toUpperCase())
                                        : null,
                                  ),
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: GestureDetector(
                                      onTap: () => _toggleSelection(userId),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  profile.firstName,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDirectMessageTab(),
                _buildGroupChatTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedParticipants.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isCreating ? null : () {
                if (_tabController.index == 0) {
                  _createOneOnOneConversation();
                } else {
                  _createGroupConversation();
                }
              },
              icon: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_tabController.index == 0 ? 'Start Chat' : 'Create Group'),
            )
          : null,
    );
  }

  Widget _buildDirectMessageTab() {
    return Column(
      children: [
        if (_selectedParticipants.length > 1)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For direct messages, please select only one person. Use "Group Chat" for multiple people.',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _buildUserList()),
      ],
    );
  }

  Widget _buildGroupChatTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomTextField(
            controller: _groupNameController,
            labelText: 'Group Name',
            prefixIcon: Icons.group,
            validator: (value) => value?.isEmpty == true ? 'Required' : null,
          ),
        ),
        if (_selectedParticipants.length < 2)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select at least 2 people to create a group chat.',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _buildUserList()),
      ],
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredProfiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty 
                  ? 'No people found'
                  : 'No people available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try a different search term'
                  : 'Check back later for more attendees',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredProfiles.length,
      itemBuilder: (context, index) {
        final profile = _filteredProfiles[index];
        final isSelected = _selectedParticipants.contains(profile.userId);
        final shouldDisableForDM = _tabController.index == 0 && 
                                   _selectedParticipants.isNotEmpty && 
                                   !isSelected;

        return ListTile(
          enabled: !shouldDisableForDM,
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: profile.profileImage != null
                    ? NetworkImage(profile.profileImage!)
                    : null,
                child: profile.profileImage == null
                    ? Text(profile.firstName.substring(0, 1).toUpperCase())
                    : null,
              ),
              if (isSelected)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(profile.fullName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.jobTitle != null)
                Text(profile.jobTitle!),
              if (profile.company != null)
                Text(
                  profile.company!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                )
              : shouldDisableForDM
                  ? const Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey,
                    )
                  : const Icon(Icons.radio_button_unchecked),
          onTap: shouldDisableForDM ? null : () => _toggleSelection(profile.userId),
        );
      },
    );
  }
}