import 'dart:convert';
import 'dart:developer';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../services/auth_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  PusherChannelsFlutter? _pusher;
  final Map<String, Function(dynamic)> _eventHandlers = {};
  bool _isConnected = false;
  String? _userId;

  // Configuration - Update these with your Pusher credentials
  static const String _appKey = 'your-pusher-app-key';
  static const String _cluster = 'mt1'; // or your cluster
  // static const String _hostUrl = 'ws://localhost:6001'; // For local Laravel WebSocket server

  Future<void> initialize() async {
    try {
      // Get current user for private channels
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      _userId = user?.id.toString();

      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: _appKey,
        cluster: _cluster,
        // For local development, you might want to use Laravel WebSocket instead
        // wsHost: '127.0.0.1',
        // wsPort: 6001,
        // encrypted: false,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onAuthorizer: _onAuthorizer,
      );

      await _pusher!.connect();
      log('WebSocket service initialized');
    } catch (e) {
      log('Failed to initialize WebSocket service: $e');
    }
  }

  // Subscribe to public channels
  Future<void> subscribeToChannel(
    String channelName, {
    Map<String, Function(dynamic)>? eventHandlers,
  }) async {
    if (_pusher == null || !_isConnected) {
      log('WebSocket not connected, cannot subscribe to $channelName');
      return;
    }

    try {
      await _pusher!.subscribe(channelName: channelName);

      if (eventHandlers != null) {
        eventHandlers.forEach((event, handler) {
          final key = '${channelName}:$event';
          _eventHandlers[key] = handler;
        });
      }

      log('Subscribed to channel: $channelName');
    } catch (e) {
      log('Failed to subscribe to channel $channelName: $e');
    }
  }

  // Subscribe to private channels
  Future<void> subscribeToPrivateChannel(
    String channelName, {
    Map<String, Function(dynamic)>? eventHandlers,
  }) async {
    if (_pusher == null || !_isConnected) {
      log('WebSocket not connected, cannot subscribe to private-$channelName');
      return;
    }

    try {
      await _pusher!.subscribe(channelName: 'private-$channelName');

      if (eventHandlers != null) {
        eventHandlers.forEach((event, handler) {
          final key = 'private-${channelName}:$event';
          _eventHandlers[key] = handler;
        });
      }

      log('Subscribed to private channel: private-$channelName');
    } catch (e) {
      log('Failed to subscribe to private channel $channelName: $e');
    }
  }

  // Unsubscribe from channel
  Future<void> unsubscribeFromChannel(String channelName) async {
    if (_pusher == null) return;

    try {
      await _pusher!.unsubscribe(channelName: channelName);

      // Remove event handlers for this channel
      _eventHandlers.removeWhere((key, _) => key.startsWith('$channelName:'));

      log('Unsubscribed from channel: $channelName');
    } catch (e) {
      log('Failed to unsubscribe from channel $channelName: $e');
    }
  }

  // Subscribe to project-specific updates
  Future<void> subscribeToProjectUpdates(
    Function(dynamic) onProjectUpdate,
  ) async {
    await subscribeToChannel(
      'projects',
      eventHandlers: {'project.updated': onProjectUpdate},
    );
  }

  // Subscribe to task updates
  Future<void> subscribeToTaskUpdates(Function(dynamic) onTaskUpdate) async {
    await subscribeToChannel(
      'tasks',
      eventHandlers: {'task.updated': onTaskUpdate},
    );
  }

  // Subscribe to specific project tasks
  Future<void> subscribeToProjectTaskUpdates(
    String projectId,
    Function(dynamic) onTaskUpdate,
  ) async {
    await subscribeToChannel(
      'project.$projectId',
      eventHandlers: {'task.updated': onTaskUpdate},
    );
  }

  // Subscribe to user activity
  Future<void> subscribeToUserActivity(Function(dynamic) onUserActivity) async {
    await subscribeToChannel(
      'user-activity',
      eventHandlers: {'user.activity': onUserActivity},
    );
  }

  // Subscribe to personal notifications
  Future<void> subscribeToPersonalNotifications(
    Function(dynamic) onNotification,
  ) async {
    if (_userId != null) {
      await subscribeToPrivateChannel(
        'user.$_userId',
        eventHandlers: {
          'project.updated': onNotification,
          'task.updated': onNotification,
        },
      );
    }
  }

  // Event handlers
  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    log('Connection state changed: $previousState -> $currentState');
    _isConnected = currentState == 'CONNECTED';
  }

  void _onError(String message, int? code, dynamic e) {
    log('WebSocket error: $message (code: $code)');
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    log('Successfully subscribed to: $channelName');
  }

  void _onEvent(PusherEvent event) {
    log('Received event: ${event.eventName} on ${event.channelName}');

    final key = '${event.channelName}:${event.eventName}';
    final handler = _eventHandlers[key];

    if (handler != null) {
      try {
        final data = event.data != null ? jsonDecode(event.data!) : null;
        handler(data);
      } catch (e) {
        log('Error handling event $key: $e');
      }
    }
  }

  void _onSubscriptionError(String message, dynamic e) {
    log('Subscription error: $message');
  }

  void _onDecryptionFailure(String event, String reason) {
    log('Decryption failure: $event - $reason');
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    log('Member added to $channelName: ${member.userId}');
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    log('Member removed from $channelName: ${member.userId}');
  }

  dynamic _onAuthorizer(String channelName, String socketId, dynamic options) {
    // For private channels, you need to implement authorization
    // This should make a request to your Laravel backend's /broadcasting/auth endpoint
    return {
      'auth':
          'your-auth-signature', // This should be obtained from your backend
    };
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    if (_pusher != null) {
      await _pusher!.disconnect();
      _eventHandlers.clear();
      _isConnected = false;
      log('WebSocket disconnected');
    }
  }

  bool get isConnected => _isConnected;
}
