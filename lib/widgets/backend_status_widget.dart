import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BackendStatusWidget extends StatefulWidget {
  const BackendStatusWidget({super.key});

  @override
  State<BackendStatusWidget> createState() => _BackendStatusWidgetState();
}

class _BackendStatusWidgetState extends State<BackendStatusWidget> {
  bool _isConnected = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    setState(() => _isChecking = true);
    
    try {
      final isHealthy = await ApiService.checkHealth();
      setState(() {
        _isConnected = isHealthy;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Checking Backend...',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _checkBackendStatus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isConnected 
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.error,
              size: 12,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 6),
            Text(
              _isConnected ? 'Backend Online' : 'Backend Offline',
              style: TextStyle(
                fontSize: 12,
                color: _isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}