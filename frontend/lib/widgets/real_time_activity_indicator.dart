import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import 'dart:developer';

class RealTimeActivityIndicator extends StatefulWidget {
  const RealTimeActivityIndicator({super.key});

  @override
  State<RealTimeActivityIndicator> createState() =>
      _RealTimeActivityIndicatorState();
}

class _RealTimeActivityIndicatorState extends State<RealTimeActivityIndicator>
    with SingleTickerProviderStateMixin {
  final _webSocketService = WebSocketService();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isConnected = false;
  String _lastActivity = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeActivityTracking();
  }

  Future<void> _initializeActivityTracking() async {
    try {
      await _webSocketService.initialize();
      setState(() {
        _isConnected = _webSocketService.isConnected;
      });

      if (_isConnected) {
        _animationController.repeat(reverse: true);

        // Subscribe to user activity
        await _webSocketService.subscribeToUserActivity((data) {
          if (mounted) {
            _handleUserActivity(data);
          }
        });
      }
    } catch (e) {
      log('Failed to initialize activity tracking: $e');
      setState(() {
        _isConnected = false;
      });
    }
  }

  void _handleUserActivity(dynamic data) {
    if (data == null) return;

    final user = data['user'] as Map<String, dynamic>?;
    final activity = data['activity'] as String?;
    final activityData = data['data'] as Map<String, dynamic>?;

    if (user != null && activity != null) {
      final userName = user['name'] as String?;
      String activityMessage = '';

      switch (activity) {
        case 'created_project':
          final projectName = activityData?['project_name'] as String?;
          activityMessage = '$userName created project "$projectName"';
          break;
        case 'updated_project':
          final projectName = activityData?['project_name'] as String?;
          activityMessage = '$userName updated project "$projectName"';
          break;
        case 'created_task':
          final taskTitle = activityData?['task_title'] as String?;
          activityMessage = '$userName created task "$taskTitle"';
          break;
        case 'updated_task':
          final taskTitle = activityData?['task_title'] as String?;
          activityMessage = '$userName updated task "$taskTitle"';
          break;
        default:
          activityMessage = '$userName performed $activity';
      }

      setState(() {
        _lastActivity = activityMessage;
      });

      // Flash the indicator
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_isConnected ? Colors.green : Colors.red).withOpacity(
                    _animation.value,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Live' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          if (_lastActivity.isNotEmpty) ...[
            const SizedBox(width: 12),
            const Text('•', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _lastActivity,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
