import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/event.dart';
import '../../models/session.dart';
import '../../models/poll.dart';
import '../../services/polling_service.dart';
import '../../widgets/custom_button.dart';

class LivePollingScreen extends StatefulWidget {
  final Event event;
  final Session? session;

  const LivePollingScreen({
    super.key, 
    required this.event,
    this.session,
  });

  @override
  State<LivePollingScreen> createState() => _LivePollingScreenState();
}

class _LivePollingScreenState extends State<LivePollingScreen>
    with SingleTickerProviderStateMixin {
  final PollingService _pollingService = PollingService();
  
  late TabController _tabController;
  List<Poll> _polls = [];
  Poll? _activePoll;
  bool _isLoading = false;
  String _currentUserId = 'user1'; // In real app, get from auth provider

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPolls();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    setState(() => _isLoading = true);

    try {
      if (widget.session != null) {
        _polls = await _pollingService.getSessionPolls(widget.session!.id);
      } else {
        _polls = await _pollingService.getEventPolls(widget.event.id);
      }

      _activePoll = _polls.where((poll) => poll.isActive).isNotEmpty
          ? _polls.firstWhere((poll) => poll.isActive)
          : null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading polls: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submitVote(Poll poll, List<String> optionIds) async {
    final success = await _pollingService.submitVote(
      poll.id,
      _currentUserId,
      optionIds,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote submitted successfully!')),
      );
      _loadPolls(); // Refresh to show updated results
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit vote')),
      );
    }
  }

  void _navigateToCreatePoll() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Poll creation feature - functionality demonstrated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Polling'),
            Text(
              widget.session?.title ?? widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToCreatePoll,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Poll',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Poll', icon: Icon(Icons.poll)),
            Tab(text: 'All Polls', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivePollTab(),
                _buildAllPollsTab(),
              ],
            ),
    );
  }

  Widget _buildActivePollTab() {
    if (_activePoll == null) {
      return _buildEmptyState(
        'No active poll',
        'There are no active polls at the moment',
        Icons.poll,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildPollCard(_activePoll!, isActive: true),
    );
  }

  Widget _buildAllPollsTab() {
    if (_polls.isEmpty) {
      return _buildEmptyState(
        'No polls created',
        'Create your first poll to engage with attendees',
        Icons.poll_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _polls.length,
      itemBuilder: (context, index) {
        final poll = _polls[index];
        return _buildPollCard(poll);
      },
    );
  }

  Widget _buildPollCard(Poll poll, {bool isActive = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isActive ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poll.question,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (poll.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          poll.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildPollStatusChip(poll),
              ],
            ),
            const SizedBox(height: 16),
            _buildPollOptions(poll),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.how_to_vote,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${poll.totalVotes} votes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (poll.type != PollType.openText) ...[
                  const SizedBox(width: 16),
                  Icon(
                    poll.allowMultipleAnswers ? Icons.check_box : Icons.radio_button_checked,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    poll.allowMultipleAnswers ? 'Multiple choice' : 'Single choice',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const Spacer(),
                if (poll.canVote && !poll.voterIds.contains(_currentUserId))
                  TextButton(
                    onPressed: () => _showVotingDialog(poll),
                    child: const Text('Vote Now'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollStatusChip(Poll poll) {
    Color color;
    String text;
    IconData icon;

    switch (poll.status) {
      case PollStatus.active:
        color = Colors.green;
        text = 'ACTIVE';
        icon = Icons.play_circle_filled;
        break;
      case PollStatus.draft:
        color = Colors.grey;
        text = 'DRAFT';
        icon = Icons.edit;
        break;
      case PollStatus.closed:
        color = Colors.red;
        text = 'CLOSED';
        icon = Icons.stop_circle;
        break;
      case PollStatus.archived:
        color = Colors.orange;
        text = 'ARCHIVED';
        icon = Icons.archive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
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

  Widget _buildPollOptions(Poll poll) {
    if (poll.type == PollType.openText) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.text_fields, color: Colors.grey),
            SizedBox(width: 8),
            Text('Open text responses'),
          ],
        ),
      );
    }

    if (!poll.showResults || poll.totalVotes == 0) {
      return Column(
        children: poll.options.map((option) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(option.text),
          );
        }).toList(),
      );
    }

    return Column(
      children: poll.options.map((option) {
        final percentage = poll.totalVotes > 0 
            ? (option.votes / poll.totalVotes * 100)
            : 0.0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(option.text)),
                  Text(
                    '${option.votes} (${percentage.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: poll.totalVotes > 0 ? percentage / 100 : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showVotingDialog(Poll poll) {
    final selectedOptions = <String>{};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(poll.question),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: poll.options.map((option) {
                final isSelected = selectedOptions.contains(option.id);
                
                return CheckboxListTile(
                  title: Text(option.text),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (!poll.allowMultipleAnswers) {
                          selectedOptions.clear();
                        }
                        selectedOptions.add(option.id);
                      } else {
                        selectedOptions.remove(option.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedOptions.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _submitVote(poll, selectedOptions.toList());
                    },
              child: const Text('Submit Vote'),
            ),
          ],
        ),
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
            onPressed: _navigateToCreatePoll,
            icon: const Icon(Icons.add),
            label: const Text('Create Poll'),
          ),
        ],
      ),
    );
  }
}