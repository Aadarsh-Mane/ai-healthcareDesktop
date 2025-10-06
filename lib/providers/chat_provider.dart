// providers/chat_provider.dart - FIXED: Messages added at bottom + SharedPreferences auth
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:doctordesktop/model/chat_model.dart';
import 'package:doctordesktop/services/chat_service.dart';
import 'package:doctordesktop/services/socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Chat list state notifier
class ChatListNotifier extends StateNotifier<ChatState> {
  ChatListNotifier(this.ref) : super(const ChatState()) {
    _init();
  }

  final Ref ref;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _onlineUsersSubscription;

  void _init() {
    // Listen to real-time events
    _listenToRealTimeEvents();
    // Load initial chats
    loadChats();
  }

  void _listenToRealTimeEvents() {
    final socketService = ref.read(socketServiceProvider);

    // Listen to new messages
    _messageSubscription = socketService.messageStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      print('=== CHAT LIST RECEIVED EVENT ===');
      print('Type: $type');
      print('Data: $data');

      switch (type) {
        case 'new_message':
          _handleNewMessage(data);
          break;
        case 'message_sent':
          _handleMessageSent(data);
          break;
      }
    });

    // Listen to read receipts
    _readReceiptSubscription = socketService.readReceiptStream.listen((event) {
      _handleReadReceipts(event['data'] as Map<String, dynamic>);
    });

    // Listen to online users
    _onlineUsersSubscription = socketService.onlineUsersStream.listen((users) {
      state = state.copyWith(onlineUsers: users);
    });
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      print('=== CHAT LIST NEW MESSAGE ===');
      print('Raw data: $data');

      // Parse the message
      final message = ChatMessage.fromJson(data);
      final chatId = message.chatId;

      print(
          'Parsed message: ID=${message.id}, Content="${message.content}", ChatId=$chatId');

      // Update the chat with new last message
      final updatedChats = state.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(
            lastMessage: message,
            lastActivity: message.timestamp,
            unreadCount: chat.unreadCount + 1,
          );
        }
        return chat;
      }).toList();

      // If chat doesn't exist, fetch it
      if (!updatedChats.any((chat) => chat.id == chatId)) {
        print('Chat not found in list, fetching chat details...');
        _fetchChatDetails(chatId);
        return;
      }

      // Sort chats by last activity
      updatedChats.sort((a, b) {
        final aTime = a.lastActivity ?? a.createdAt;
        final bTime = b.lastActivity ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      // Update total unread count
      final totalUnread = updatedChats.fold<int>(
        0,
        (sum, chat) => sum + chat.unreadCount,
      );

      state = state.copyWith(
        chats: updatedChats,
        totalUnreadCount: totalUnread,
      );

      print('Updated chat list. Total chats: ${updatedChats.length}');
      print('=== END CHAT LIST MESSAGE ===');
    } catch (e) {
      log('Error handling new message in chat list: $e');
      print('Error details: $e');
      print('Problematic data: $data');
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      print('=== CHAT LIST MESSAGE SENT ===');
      print('Raw data: $data');

      // Refresh chat list to get updated last message
      loadChats();

      print('=== END CHAT LIST SENT ===');
    } catch (e) {
      log('Error handling message sent in chat list: $e');
    }
  }

  void _handleReadReceipts(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] as String?;
      if (chatId == null) return;

      // Mark messages as read in this chat
      final updatedChats = state.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();

      // Update total unread count
      final totalUnread = updatedChats.fold<int>(
        0,
        (sum, chat) => sum + chat.unreadCount,
      );

      state = state.copyWith(
        chats: updatedChats,
        totalUnreadCount: totalUnread,
      );
    } catch (e) {
      log('Error handling read receipts: $e');
    }
  }

  Future<void> _fetchChatDetails(String chatId) async {
    // Simply refresh the entire chat list for now
    await loadChats();
  }

  Future<void> loadChats() async {
    if (state.isLoading) {
      print('Already loading chats, skipping...');
      return;
    }

    print('=== LOADING CHATS ===');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get token directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final chats = await ChatService.getUserChats(
        token: token,
        page: 1,
        limit: 50,
      );

      print('Loaded ${chats.length} chats from API');

      final totalUnread = chats.fold<int>(
        0,
        (sum, chat) => sum + chat.unreadCount,
      );

      state = state.copyWith(
        chats: chats,
        isLoading: false,
        totalUnreadCount: totalUnread,
      );

      print('=== CHATS LOADED SUCCESSFULLY ===');
    } catch (e) {
      log('Error loading chats: $e');
      print('Chat loading error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshChats() async {
    await loadChats();
  }

  Future<Chat?> createChatWithUser(String userId) async {
    try {
      // Get token directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final chat = await ChatService.getOrCreateChat(
        recipientId: userId,
        token: token,
      );

      // Add to chats list if not exists
      final chatExists = state.chats.any((c) => c.id == chat.id);
      if (!chatExists) {
        final updatedChats = [chat, ...state.chats];
        state = state.copyWith(chats: updatedChats);
      }

      return chat;
    } catch (e) {
      log('Error creating chat: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void markChatAsRead(String chatId) {
    final updatedChats = state.chats.map((chat) {
      if (chat.id == chatId) {
        return chat.copyWith(unreadCount: 0);
      }
      return chat;
    }).toList();

    final totalUnread = updatedChats.fold<int>(
      0,
      (sum, chat) => sum + chat.unreadCount,
    );

    state = state.copyWith(
      chats: updatedChats,
      totalUnreadCount: totalUnread,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _onlineUsersSubscription?.cancel();
    super.dispose();
  }
}

// FIXED Chat messages state notifier - Messages added at bottom
class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  ChatMessagesNotifier(this.chatId, this.ref)
      : super(ChatMessagesState(chatId: chatId)) {
    print('=== CREATING CHAT MESSAGES NOTIFIER ===');
    print('Chat ID: $chatId');
    _init();
  }

  final String chatId;
  final Ref ref;
  StreamSubscription? _messageSubscription;
  Timer? _typingTimer;
  ChatUser? _currentUser;

  Future<void> _init() async {
    await _loadUserData();
    _listenToRealTimeMessages();
    loadMessages();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        final userMap = json.decode(userData);
        _currentUser = ChatUser.fromJson(userMap);
      }
    } catch (e) {
      log('Error loading user data: $e');
    }
  }

  void _listenToRealTimeMessages() {
    final socketService = ref.read(socketServiceProvider);

    _messageSubscription = socketService.messageStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      print('=== MESSAGES NOTIFIER RECEIVED EVENT ===');
      print('Type: $type');
      print('Data: $data');
      print('Current chat ID: $chatId');

      if (type == 'new_message') {
        _handleNewMessage(data);
      } else if (type == 'message_sent') {
        _handleMessageSent(data);
      }
    });
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      print('=== MESSAGES NEW MESSAGE ===');
      print('Raw data: $data');

      final message = ChatMessage.fromJson(data);
      print(
          'Parsed message: ID=${message.id}, Content="${message.content}", ChatId=${message.chatId}, SenderId=${message.senderId}');

      // Only handle messages for this specific chat
      if (message.chatId == chatId) {
        print('Message belongs to current chat, processing...');

        // Check if message already exists to prevent duplicates
        final messageExists = state.messages.any((msg) => msg.id == message.id);
        print('Message exists: $messageExists');

        if (!messageExists) {
          // FIXED: Add the new message to the END of the list (bottom)
          final updatedMessages = [...state.messages, message];

          // Sort messages by timestamp to ensure correct chronological order
          updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          print(
              'Adding message to state. Total messages now: ${updatedMessages.length}');
          print(
              'Message timestamps: ${updatedMessages.map((m) => '${m.content}: ${m.timestamp}').toList()}');

          state = state.copyWith(messages: updatedMessages);

          // Auto-mark as read if user is viewing this chat
          _markAsReadIfViewing();
        } else {
          print('Message already exists, skipping...');
        }
      } else {
        print(
            'Message not for current chat (${message.chatId} != $chatId), ignoring...');
      }

      print('=== END MESSAGES NEW MESSAGE ===');
    } catch (e) {
      log('Error handling new message in messages: $e');
      print('Error details: $e');
      print('Problematic data: $data');
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      print('=== MESSAGES MESSAGE SENT ===');
      print('Raw data: $data');

      // Check if this is a success confirmation
      if (data.containsKey('success') && data['success'] == true) {
        print('Message sent successfully, refreshing messages...');

        // Refresh messages to get the latest state including the sent message
        loadMessages();
      } else if (data.containsKey('message')) {
        // Handle direct message data
        final message = ChatMessage.fromJson(data['message']);
        if (message.chatId == chatId) {
          // Check if message already exists
          final messageExists =
              state.messages.any((msg) => msg.id == message.id);
          if (!messageExists) {
            // FIXED: Add sent message to the END of the list
            final updatedMessages = [...state.messages, message];

            // Sort by timestamp to maintain order
            updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

            state = state.copyWith(messages: updatedMessages);
            print('Added sent message to end of list');
          }
        }
      }

      print('=== END MESSAGES SENT ===');
    } catch (e) {
      log('Error handling message sent confirmation: $e');
      print('Error details: $e');
    }
  }

  Future<void> loadMessages({bool loadMore = false}) async {
    if (state.isLoading) {
      print('Already loading messages, skipping...');
      return;
    }

    final page = loadMore ? state.currentPage + 1 : 1;

    print('=== LOADING MESSAGES ===');
    print('Chat ID: $chatId');
    print('Page: $page');
    print('Load more: $loadMore');

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: page,
    );

    try {
      // Get token directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final messages = await ChatService.getChatMessages(
        chatId: chatId,
        token: token,
        page: page,
        limit: 50,
      );

      print('Loaded ${messages.length} messages from API');

      // Debug: Print message order from API
      print('API Messages order:');
      for (int i = 0; i < messages.length; i++) {
        print('  [$i] ${messages[i].content} - ${messages[i].timestamp}');
      }

      final List<ChatMessage> updatedMessages;
      if (loadMore) {
        // FIXED: When loading more (older messages), add them to the BEGINNING
        updatedMessages = [...messages, ...state.messages];
        print('Prepending ${messages.length} older messages');
      } else {
        // FIXED: Initial load - use messages as-is from API
        updatedMessages = messages;
        print('Initial load with ${messages.length} messages');
      }

      // IMPORTANT: Sort messages by timestamp to ensure correct chronological order
      // Older messages first, newer messages last
      updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Debug: Print final message order
      print('Final message order after sorting:');
      for (int i = 0; i < updatedMessages.length; i++) {
        print(
            '  [$i] ${updatedMessages[i].content} - ${updatedMessages[i].timestamp}');
      }

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        hasMoreMessages: messages.length >= 50,
      );

      print('Messages loaded successfully. Total: ${updatedMessages.length}');

      // Mark as read
      _markAsReadIfViewing();

      print('=== MESSAGES LOADED ===');
    } catch (e) {
      log('Error loading messages: $e');
      print('Messages loading error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // FIXED sendMessage method - Add message optimistically to end of list + SharedPreferences
  Future<void> sendMessage({
    required String content,
    String messageType = 'text',
    String? replyToId,
  }) async {
    if (content.trim().isEmpty) {
      print('Cannot send empty message');
      return;
    }

    try {
      print('=== SENDING MESSAGE ===');
      print('Content: "$content"');
      print('Chat ID: $chatId');
      print('Message type: $messageType');

      // Get token and user data directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('userId');

      if (token == null || userId == null) {
        print('No auth token or user ID available');
        throw Exception('Authentication required');
      }

      // Load user data if not already loaded
      if (_currentUser == null) {
        await _loadUserData();
      }

      // FIXED: Create optimistic message and add to END of list
      final optimisticMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        senderId: userId,
        content: content,
        messageType: messageType,
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: false,
        isSent: false, // Will be updated when confirmed
        replyToId: replyToId,
      );

      // Add optimistic message to the END of the list
      final updatedMessages = [...state.messages, optimisticMessage];

      // Sort to maintain chronological order
      updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Update state with optimistic message
      state = state.copyWith(messages: updatedMessages);

      print('Added optimistic message to end of list');

      final socketService = ref.read(socketServiceProvider);

      // Try socket first, then fallback to HTTP
      if (socketService.isConnected) {
        print('Sending via socket...');

        // Send via socket
        await socketService.sendMessage(
          chatId: chatId,
          content: content,
          messageType: messageType,
          replyToId: replyToId,
        );

        print('Socket message sent, waiting for confirmation...');

        // Remove optimistic message after a delay if no confirmation
        Future.delayed(const Duration(seconds: 2), () {
          _removeOptimisticMessage(optimisticMessage.id);
        });
      } else {
        print('Socket not connected, sending via HTTP...');

        // Remove optimistic message before HTTP send
        final messagesWithoutOptimistic = state.messages
            .where((msg) => msg.id != optimisticMessage.id)
            .toList();

        // Fallback to HTTP
        final sentMessage = await ChatService.sendMessage(
          chatId: chatId,
          content: content,
          token: token,
          messageType: messageType,
          replyToId: replyToId,
        );

        print('HTTP message sent successfully');

        // Add the HTTP response message to the END
        final finalMessages = [...messagesWithoutOptimistic, sentMessage];

        // Sort by timestamp
        finalMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        state = state.copyWith(messages: finalMessages);
        print('Added HTTP sent message to end of list');
      }

      print('=== MESSAGE SENDING COMPLETE ===');
    } catch (e) {
      log('Error sending message: $e');
      print('Send message error: $e');

      // Remove optimistic message on error
      final messagesWithoutOptimistic =
          state.messages.where((msg) => !msg.id.startsWith('temp_')).toList();

      state = state.copyWith(
        messages: messagesWithoutOptimistic,
        error: 'Failed to send message: $e',
      );
    }
  }

  void _removeOptimisticMessage(String tempId) {
    final updatedMessages =
        state.messages.where((msg) => msg.id != tempId).toList();
    if (updatedMessages.length != state.messages.length) {
      state = state.copyWith(messages: updatedMessages);
      print('Removed optimistic message: $tempId');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      // Get token directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token available');
      }

      await ChatService.deleteMessage(
        chatId: chatId,
        messageId: messageId,
        token: token,
      );

      // Remove message from local state
      final updatedMessages =
          state.messages.where((msg) => msg.id != messageId).toList();

      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      log('Error deleting message: $e');
      state = state.copyWith(error: 'Failed to delete message');
    }
  }

  void _markAsReadIfViewing() {
    final socketService = ref.read(socketServiceProvider);
    if (socketService.currentChatId == chatId) {
      socketService.markMessagesAsRead(chatId);
      ref.read(chatListProvider.notifier).markChatAsRead(chatId);
    }
  }

  void startTyping() {
    final socketService = ref.read(socketServiceProvider);
    socketService.startTyping(chatId);

    // Auto-stop typing after 3 seconds
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping();
    });
  }

  void stopTyping() {
    _typingTimer?.cancel();
    final socketService = ref.read(socketServiceProvider);
    socketService.stopTyping(chatId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    print('=== DISPOSING CHAT MESSAGES NOTIFIER ===');
    print('Chat ID: $chatId');
    _messageSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}

// Providers
final chatListProvider =
    StateNotifierProvider<ChatListNotifier, ChatState>((ref) {
  return ChatListNotifier(ref);
});

final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    ChatMessagesState, String>((ref, chatId) {
  return ChatMessagesNotifier(chatId, ref);
});

// Helper providers
final totalUnreadCountProvider = Provider<int>((ref) {
  final chatState = ref.watch(chatListProvider);
  return chatState.totalUnreadCount;
});

final chatByIdProvider = Provider.family<Chat?, String>((ref, chatId) {
  final chatState = ref.watch(chatListProvider);
  try {
    return chatState.chats.firstWhere((chat) => chat.id == chatId);
  } catch (e) {
    return null;
  }
});

final isUserOnlineProvider = Provider.family<bool, String>((ref, userId) {
  final chatState = ref.watch(chatListProvider);
  return chatState.onlineUsers.contains(userId);
});

// Current user from SharedPreferences
final currentUserProvider = FutureProvider<ChatUser?>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      return ChatUser.fromJson(json.decode(userData));
    }
    return null;
  } catch (e) {
    log('Error loading user data: $e');
    return null;
  }
});

// Current user ID from SharedPreferences
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
});
