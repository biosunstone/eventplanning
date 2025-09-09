import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/session.dart';
import '../../services/checkin_service.dart';
import '../../widgets/custom_button.dart';

class CheckInScreen extends StatefulWidget {
  final Event event;
  final Session? session;

  const CheckInScreen({
    super.key,
    required this.event,
    this.session,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with SingleTickerProviderStateMixin {
  final CheckInService _checkInService = CheckInService();
  late TabController _tabController;
  
  String? _qrCode;
  String? _attendeeQRCode;
  bool _isLoading = false;
  bool _isCheckedIn = false;
  String _currentUserId = 'user1'; // In real app, get from auth provider
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateQRCodes();
    _checkCurrentStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateQRCodes() async {
    setState(() => _isLoading = true);

    try {
      _qrCode = await _checkInService.generateQRCode(
        eventId: widget.event.id,
        sessionId: widget.session?.id,
        type: widget.session != null ? CheckInType.session : CheckInType.event,
      );

      _attendeeQRCode = await _checkInService.generateAttendeeQRCode(
        _currentUserId,
        widget.event.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating QR codes: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkCurrentStatus() async {
    final isCheckedIn = await _checkInService.isAttendeeCheckedIn(
      attendeeId: _currentUserId,
      eventId: widget.event.id,
      sessionId: widget.session?.id,
      type: widget.session != null ? CheckInType.session : CheckInType.event,
    );

    setState(() => _isCheckedIn = isCheckedIn);
  }

  Future<void> _handleManualCheckIn() async {
    setState(() => _isLoading = true);

    try {
      await _checkInService.checkIn(
        eventId: widget.event.id,
        sessionId: widget.session?.id,
        attendeeId: _currentUserId,
        type: widget.session != null ? CheckInType.session : CheckInType.event,
      );

      setState(() => _isCheckedIn = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully checked in!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _onQRScanned(String data) async {
    try {
      final checkIn = await _checkInService.processQRScan(
        qrData: data,
        attendeeId: _currentUserId,
      );

      if (checkIn != null && mounted) {
        setState(() => _isCheckedIn = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully checked in!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR code')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
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
            const Text('Check-In'),
            Text(
              widget.session?.title ?? widget.event.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My QR', icon: Icon(Icons.qr_code)),
            Tab(text: 'Scan', icon: Icon(Icons.qr_code_scanner)),
            Tab(text: 'Manual', icon: Icon(Icons.touch_app)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyQRTab(),
                _buildScanTab(),
                _buildManualTab(),
              ],
            ),
    );
  }

  Widget _buildMyQRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isCheckedIn)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Checked In',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.session != null
                              ? 'You are checked into this session'
                              : 'You are checked into this event',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Your Attendee QR Code',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Show this QR code to organizers for quick check-in',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_attendeeQRCode != null)
                    Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'QR Code',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _attendeeQRCode!.substring(0, 12) + '...',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Icon(
                            Icons.event,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Event',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (widget.session != null)
                        Column(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Session',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      Column(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Attendee',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'QR Code Scanner',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'QR code scanning requires camera permissions and additional packages.\n\nFor demonstration purposes, use Manual Check-in instead.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Use Manual Check-in',
            onPressed: () => _tabController.animateTo(2),
            icon: Icons.touch_app,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Simulate QR Scan',
            onPressed: () => _onQRScanned('demo_qr_code_${widget.event.id}'),
            isOutlined: true,
            icon: Icons.qr_code_scanner,
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCheckedIn ? Icons.check_circle : Icons.touch_app,
            size: 80,
            color: _isCheckedIn ? Colors.green : Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            _isCheckedIn ? 'You\'re Checked In!' : 'Manual Check-In',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isCheckedIn ? Colors.green : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isCheckedIn
                ? widget.session != null
                    ? 'You have successfully checked into this session'
                    : 'You have successfully checked into this event'
                : widget.session != null
                    ? 'Tap the button below to check into this session'
                    : 'Tap the button below to check into this event',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (!_isCheckedIn)
            CustomButton(
              text: widget.session != null ? 'Check Into Session' : 'Check Into Event',
              onPressed: _handleManualCheckIn,
              isLoading: _isLoading,
              icon: Icons.touch_app,
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.event.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.session != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Session',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                widget.session!.title,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.session?.location ?? widget.event.location,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}