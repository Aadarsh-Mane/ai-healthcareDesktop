// services/socket_service.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentChatId;

  // Use your specific socket URL - make sure this matches your server
  static const String _socketUrl = 'http://192.168.0.100:5001';

  // Stream controllers for real-time events
  final _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onlineUsersStreamController =
      StreamController<List<String>>.broadcast();
  final _connectionStreamController = StreamController<bool>.broadcast();
  final _readReceiptStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream =>
      _typingStreamController.stream;
  Stream<List<String>> get onlineUsersStream =>
      _onlineUsersStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream =>
      _readReceiptStreamController.stream;

  bool get isConnected => _isConnected;
  String? get currentChatId => _currentChatId;

  Future<void> connect({
    required String token,
    required String userId,
  }) async {
    try {
      if (_socket?.connected == true) {
        await disconnect();
      }

      _currentUserId = userId;

      // ✅ TEST THE SAME TOKEN THAT WORKS FOR HTTP
      log('🔍 Testing token that works for HTTP API:');
      log('🔑 Full token: $token');

      // Remove Bearer prefix for socket
      String socketToken = token;
      if (socketToken.startsWith('Bearer ')) {
        socketToken = socketToken.substring(7).trim();
      }

      log('🔑 Socket token (no Bearer): $socketToken');
      log('🔑 User ID: $userId');
      log('🔌 Connecting to socket server at: $_socketUrl');

      // Validate token before connecting
      if (socketToken.isEmpty) {
        log('❌ Empty token provided');
        _connectionStreamController.add(false);
        return;
      }

      // Check if token has JWT format (should have 3 parts separated by dots)
      if (!socketToken.contains('.') || socketToken.split('.').length != 3) {
        log('❌ Invalid JWT token format');
        _connectionStreamController.add(false);
        return;
      }

      _socket = IO.io(
          _socketUrl,
          IO.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .setAuth({
                'token': socketToken, // Send without Bearer prefix
                'userId': userId,
              })
              .enableReconnection()
              .setReconnectionAttempts(10)
              .setReconnectionDelay(2000)
              .setReconnectionDelayMax(10000)
              .enableAutoConnect()
              .setTimeout(20000)
              .build());

      _setupEventListeners();
      _socket!.connect();

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 1000));
    } catch (e) {
      log('❌ Socket connection error: $e');
      _connectionStreamController.add(false);
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.on('connect', (data) {
      log('✅ Socket connected successfully');
      log('📡 Socket ID: ${_socket!.id}');
      _isConnected = true;
      _connectionStreamController.add(true);

      // Authenticate and get online users on connect
      if (_currentUserId != null) {
        _socket!.emit('authenticate', {'userId': _currentUserId});
        _socket!.emit('get_online_users');
      }
    });

    _socket!.on('disconnect', (data) {
      log('❌ Socket disconnected: $data');
      _isConnected = false;
      _connectionStreamController.add(false);
    });

    _socket!.on('connect_error', (error) {
      log('🔥 Socket connection error: $error');
      _isConnected = false;
      _connectionStreamController.add(false);
    });

    _socket!.on('reconnect', (data) {
      log('🔄 Socket reconnected: $data');
      _isConnected = true;
      _connectionStreamController.add(true);
    });

    _socket!.on('reconnect_error', (error) {
      log('🔥 Socket reconnection error: $error');
    });

    // Chat events - FIXED: Handle nested message structure
    _socket!.on('new_message', (data) {
      log('📨 New message received: $data');
      try {
        // Extract the actual message from the nested structure
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          final messageData = data['message'] as Map<String, dynamic>;
          final chatId = data['chatId'] as String?;

          // Create a properly formatted message object
          final formattedMessage = {
            'id': messageData['_id'],
            'chatId': chatId,
            'senderId': messageData['senderId'],
            'content': messageData['content'],
            'messageType': messageData['messageType'] ?? 'text',
            'timestamp': messageData['createdAt'],
            'isRead': false,
            'isDelivered': true,
            'isSent': true,
            'isDeleted': messageData['isDeleted'] ?? false,
            'readBy': messageData['readBy'] ?? [],
            'replyToMessage': messageData['replyToMessage'],
          };

          _messageStreamController.add({
            'type': 'new_message',
            'data': formattedMessage,
          });
        }
      } catch (e) {
        log('❌ Error processing new_message: $e');
      }
    });

    _socket!.on('message_sent', (data) {
      log('✅ Message sent confirmation: $data');
      try {
        // Handle message_sent confirmation
        if (data is Map<String, dynamic> && data.containsKey('success')) {
          _messageStreamController.add({
            'type': 'message_sent',
            'data': data,
          });
        }
      } catch (e) {
        log('❌ Error processing message_sent: $e');
      }
    });

    _socket!.on('message_delivered', (data) {
      log('📬 Message delivered: $data');
      _messageStreamController.add({
        'type': 'message_delivered',
        'data': data,
      });
    });

    _socket!.on('messages_read', (data) {
      log('👀 Messages read: $data');
      _readReceiptStreamController.add({
        'type': 'messages_read',
        'data': data,
      });
    });

    _socket!.on('message_deleted', (data) {
      log('🗑️ Message deleted: $data');
      _messageStreamController.add({
        'type': 'message_deleted',
        'data': data,
      });
    });

    // Typing events
    _socket!.on('user_typing', (data) {
      log('⌨️ User typing: $data');
      _typingStreamController.add({
        'type': 'user_typing',
        'data': data,
      });
    });

    _socket!.on('user_stopped_typing', (data) {
      log('⏹️ User stopped typing: $data');
      _typingStreamController.add({
        'type': 'user_stopped_typing',
        'data': data,
      });
    });

    // Online status events - FIXED: Handle complex user data structure
    _socket!.on('online_users', (data) {
      log('👥 Online users received: $data');
      try {
        List<String> userIds = [];

        if (data is List) {
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              // Handle complex structure with userId field
              if (item.containsKey('userId')) {
                userIds.add(item['userId'] as String);
              }
              // Handle simple string structure
              else if (item is String) {
                userIds.add(item as String);
              }
            } else if (item is String) {
              userIds.add(item);
            }
          }
        } else if (data is Map && data['users'] is List) {
          final users = data['users'] as List;
          userIds = users.map((u) => u.toString()).toList();
        }

        _onlineUsersStreamController.add(userIds);
        log('👥 Processed online users: $userIds');
      } catch (e) {
        log('❌ Error processing online users: $e');
        _onlineUsersStreamController.add([]);
      }
    });

    _socket!.on('user_online', (data) {
      log('🟢 User came online: $data');
      // Trigger refresh of online users
      _socket!.emit('get_online_users');
    });

    _socket!.on('user_offline', (data) {
      log('🔴 User went offline: $data');
      // Trigger refresh of online users
      _socket!.emit('get_online_users');
    });

    _socket!.on('contact_status_update', (data) {
      log('🟢 Contact status update: $data');
      _socket!.emit('get_online_users');
    });

    // Authentication events
    _socket!.on('authenticated', (data) {
      log('✅ Socket authenticated: $data');
    });

    _socket!.on('authentication_error', (data) {
      log('❌ Socket authentication error: $data');
    });

    // Chat room events
    _socket!.on('joined_chat', (data) {
      log('🚪 Successfully joined chat: $data');
    });

    _socket!.on('left_chat', (data) {
      log('🚪 Successfully left chat: $data');
    });

    // Error events
    _socket!.on('error', (data) {
      log('❌ Socket error: $data');
    });

    // Debug event - remove in production
    _socket!.onAny((event, data) {
      log('🔍 Socket event received: $event with data: $data');
    });
  }

  // Join a chat room
  Future<void> joinChat(String chatId) async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot join chat: Socket not connected');
      return;
    }

    try {
      // Leave current chat if any
      if (_currentChatId != null && _currentChatId != chatId) {
        _socket!.emit('leave_chat', {
          'chatId': _currentChatId,
          'userId': _currentUserId,
        });
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _currentChatId = chatId;
      _socket!.emit('join_chat', {
        'chatId': chatId,
        'userId': _currentUserId,
      });
      log('🚪 Joining chat: $chatId');
    } catch (e) {
      log('❌ Error joining chat: $e');
    }
  }

  // Leave current chat
  Future<void> leaveChat() async {
    if (!_isConnected || _socket == null || _currentChatId == null) {
      log('❌ Cannot leave chat: Socket not connected or no active chat');
      return;
    }

    try {
      _socket!.emit('leave_chat', {
        'chatId': _currentChatId,
        'userId': _currentUserId,
      });
      log('🚪 Left chat: $_currentChatId');
      _currentChatId = null;
    } catch (e) {
      log('❌ Error leaving chat: $e');
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    String messageType = 'text',
    String? replyToId,
  }) async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot send message: Socket not connected');
      return;
    }

    try {
      final messageData = {
        'chatId': chatId,
        'content': content,
        'messageType': messageType,
        'senderId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
        if (replyToId != null) 'replyToId': replyToId,
      };

      log('📤 Sending message: $messageData');
      _socket!.emit('send_message', messageData);
    } catch (e) {
      log('❌ Error sending message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot mark messages as read: Socket not connected');
      return;
    }

    try {
      _socket!.emit('mark_messages_read', {
        'chatId': chatId,
        'userId': _currentUserId,
      });
      log('👀 Marking messages as read for chat: $chatId');
    } catch (e) {
      log('❌ Error marking messages as read: $e');
    }
  }

  // Start typing indicator
  Future<void> startTyping(String chatId) async {
    if (!_isConnected || _socket == null) return;

    try {
      _socket!.emit('typing_start', {
        'chatId': chatId,
        'userId': _currentUserId,
      });
      log('⌨️ Started typing in chat: $chatId');
    } catch (e) {
      log('❌ Error starting typing: $e');
    }
  }

  // Stop typing indicator
  Future<void> stopTyping(String chatId) async {
    if (!_isConnected || _socket == null) return;

    try {
      _socket!.emit('typing_stop', {
        'chatId': chatId,
        'userId': _currentUserId,
      });
      log('⏹️ Stopped typing in chat: $chatId');
    } catch (e) {
      log('❌ Error stopping typing: $e');
    }
  }

  // Update user status
  Future<void> updateStatus(String status) async {
    if (!_isConnected || _socket == null) return;

    try {
      _socket!.emit('update_status', {
        'status': status,
        'userId': _currentUserId,
      });
      log('🔄 Updated status to: $status');
    } catch (e) {
      log('❌ Error updating status: $e');
    }
  }

  // Get online users
  Future<void> getOnlineUsers() async {
    if (!_isConnected || _socket == null) return;

    try {
      _socket!.emit('get_online_users', {
        'userId': _currentUserId,
      });
      log('👥 Requesting online users');
    } catch (e) {
      log('❌ Error getting online users: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId, String chatId) async {
    if (!_isConnected || _socket == null) return;

    try {
      _socket!.emit('delete_message', {
        'messageId': messageId,
        'chatId': chatId,
        'userId': _currentUserId,
      });
      log('🗑️ Deleting message: $messageId');
    } catch (e) {
      log('❌ Error deleting message: $e');
    }
  }

  // Disconnect socket
  Future<void> disconnect() async {
    try {
      if (_currentChatId != null) {
        await leaveChat();
      }

      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _currentUserId = null;
      _currentChatId = null;

      _connectionStreamController.add(false);
      log('🔌 Socket disconnected');
    } catch (e) {
      log('❌ Error disconnecting socket: $e');
    }
  }

  // Check connection status
  bool checkConnection() {
    final connected = _socket?.connected ?? false;
    if (connected != _isConnected) {
      _isConnected = connected;
      _connectionStreamController.add(connected);
    }
    return connected;
  }

  // Force reconnect
  Future<void> forceReconnect() async {
    log('🔄 Force reconnecting socket...');
    _socket?.disconnect();
    await Future.delayed(const Duration(milliseconds: 1000));
    _socket?.connect();
  }

  // Dispose all streams
  void dispose() {
    disconnect();
    _messageStreamController.close();
    _typingStreamController.close();
    _onlineUsersStreamController.close();
    _connectionStreamController.close();
    _readReceiptStreamController.close();
  }
}

// Riverpod provider for socket service
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Provider for socket connection status
final socketConnectionProvider = StreamProvider<bool>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.connectionStream;
});

// Provider for online users
final onlineUsersProvider = StreamProvider<List<String>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onlineUsersStream;
});

// RENAMED: Provider to check if a specific user is online - renamed to avoid conflict
final socketUserOnlineProvider = Provider.family<bool, String>((ref, userId) {
  final onlineUsersAsync = ref.watch(onlineUsersProvider);
  return onlineUsersAsync.when(
    data: (users) => users.contains(userId),
    loading: () => false,
    error: (_, __) => false,
  );
});

// Provider for typing indicators
final typingProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.typingStream;
});

// Provider for real-time messages
final realTimeMessagesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.messageStream;
});

// Provider for read receipts
final readReceiptsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.readReceiptStream;
});
