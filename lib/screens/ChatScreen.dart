import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/chat_model.dart';
import 'package:doctordesktop/providers/chat_provider.dart';
import 'package:doctordesktop/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreenDesktop extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatScreenDesktop({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<ChatScreenDesktop> createState() => _ChatScreenDesktopState();
}

class _ChatScreenDesktopState extends ConsumerState<ChatScreenDesktop>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isTyping = false;
  ChatMessage? _selectedReplyMessage;

  // Auth data from SharedPreferences
  String? _currentUserId;
  bool _isLoadingAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load auth data from SharedPreferences
    _loadAuthData().then((_) {
      _initializeChat();
      _scrollToBottom();
      _listenToSocketEvents();
    });

    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onMessageTextChanged);
  }

  Future<void> _loadAuthData() async {
    setState(() {
      _isLoadingAuth = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentUserId = prefs.getString('userId');
        _isLoadingAuth = false;
      });

      print('=== AUTH DATA LOADED ===');
      print('Current user ID: $_currentUserId');
    } catch (e) {
      print('Error loading auth data: $e');
      setState(() {
        _isLoadingAuth = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();

    // Leave chat room when disposing
    final socketService = ref.read(socketServiceProvider);
    socketService.leaveChat();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final socketService = ref.read(socketServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        socketService.updateStatus('online');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        socketService.updateStatus('away');
        break;
      case AppLifecycleState.detached:
        socketService.updateStatus('offline');
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _debugChatInfo() {
    print('=== CHAT DEBUG INFO ===');
    print('Chat ID: ${widget.chat.id}');
    print('Chat participants: ${widget.chat.participants}');
    print(
        'Chat participant details: ${widget.chat.participantDetails.map((p) => '${p.id}: ${p.displayName}').toList()}');
    print('Current user ID: $_currentUserId');
    print('=== END DEBUG INFO ===');
  }

  void _initializeChat() {
    _debugChatInfo();

    final socketService = ref.read(socketServiceProvider);
    socketService.joinChat(widget.chat.id);

    // Mark messages as read
    socketService.markMessagesAsRead(widget.chat.id);
  }

  void _listenToSocketEvents() {
    // Listen to real-time messages
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      realTimeMessagesProvider,
      (previous, next) {
        next.whenData((eventData) {
          _handleSocketMessage(eventData);
        });
      },
    );

    // Listen to socket connection status
    ref.listen<AsyncValue<bool>>(
      socketConnectionProvider,
      (previous, next) {
        next.whenData((isConnected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isConnected ? 'Connected' : 'Connection lost',
                ),
                backgroundColor:
                    isConnected ? HospitalTheme.success : HospitalTheme.error,
                duration: Duration(seconds: isConnected ? 1 : 3),
              ),
            );
          }
        });
      },
    );

    // Listen to typing indicators
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      typingProvider,
      (previous, next) {
        next.whenData((typingData) {
          _handleTypingIndicator(typingData);
        });
      },
    );

    // Listen to read receipts
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      readReceiptsProvider,
      (previous, next) {
        next.whenData((receiptData) {
          _handleReadReceipt(receiptData);
        });
      },
    );
  }

  void _handleSocketMessage(Map<String, dynamic> eventData) {
    final type = eventData['type'] as String?;
    final data = eventData['data'] as Map<String, dynamic>?;

    if (data == null) return;

    switch (type) {
      case 'new_message':
        _handleNewMessage(data);
        break;
      case 'message_sent':
        _handleMessageSent(data);
        break;
      case 'message_delivered':
        _handleMessageDelivered(data);
        break;
      case 'message_deleted':
        _handleMessageDeleted(data);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    final senderId = data['senderId'] as String?;

    // Only process messages for current chat and not from current user
    if (chatId == widget.chat.id && senderId != _currentUserId) {
      print('📨 Handling new message: ${data['content']}');

      // Refresh messages list
      ref.read(chatMessagesProvider(widget.chat.id).notifier).loadMessages();

      // Mark as read since user is viewing the chat
      final socketService = ref.read(socketServiceProvider);
      socketService.markMessagesAsRead(widget.chat.id);

      // Scroll to bottom for new messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;

    if (chatId == widget.chat.id) {
      print('✅ Message sent confirmation received');

      // Refresh messages to show the sent message
      ref.read(chatMessagesProvider(widget.chat.id).notifier).loadMessages();

      // Scroll to bottom immediately after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _handleMessageDelivered(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;

    if (chatId == widget.chat.id) {
      print('📬 Message delivery confirmation');
      // Update message status if needed
      ref.read(chatMessagesProvider(widget.chat.id).notifier).loadMessages();
    }
  }

  void _handleMessageDeleted(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;

    if (chatId == widget.chat.id) {
      print('🗑️ Message deleted');
      // Refresh messages list
      ref.read(chatMessagesProvider(widget.chat.id).notifier).loadMessages();
    }
  }

  void _handleTypingIndicator(Map<String, dynamic> typingData) {
    final type = typingData['type'] as String?;
    final data = typingData['data'] as Map<String, dynamic>?;

    if (data == null) return;

    final chatId = data['chatId'] as String?;
    final userId = data['userId'] as String?;

    // Only show typing for other users in current chat
    if (chatId == widget.chat.id && userId != _currentUserId) {
      switch (type) {
        case 'user_typing':
          print('⌨️ Other user is typing');
          // You can show typing indicator in UI here
          break;
        case 'user_stopped_typing':
          print('⏹️ Other user stopped typing');
          // Hide typing indicator
          break;
      }
    }
  }

  void _handleReadReceipt(Map<String, dynamic> receiptData) {
    final type = receiptData['type'] as String?;
    final data = receiptData['data'] as Map<String, dynamic>?;

    if (data == null) return;

    final chatId = data['chatId'] as String?;

    if (chatId == widget.chat.id && type == 'messages_read') {
      print('👀 Messages marked as read');
      // Update read status in UI if needed
      ref.read(chatMessagesProvider(widget.chat.id).notifier).loadMessages();
    }
  }

  void _onScroll() {
    final chatMessagesNotifier =
        ref.read(chatMessagesProvider(widget.chat.id).notifier);

    // Load more messages when reaching top
    if (_scrollController.position.pixels <= 100) {
      final state = ref.read(chatMessagesProvider(widget.chat.id));
      if (!state.isLoading && state.hasMoreMessages) {
        chatMessagesNotifier.loadMessages(loadMore: true);
      }
    }
  }

  void _onMessageTextChanged() {
    final text = _messageController.text.trim();
    final chatMessagesNotifier =
        ref.read(chatMessagesProvider(widget.chat.id).notifier);

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      chatMessagesNotifier.startTyping();
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      chatMessagesNotifier.stopTyping();
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    print('=== SENDING MESSAGE FROM UI ===');
    print('Content: "$content"');
    print('Chat ID: ${widget.chat.id}');

    final chatMessagesNotifier =
        ref.read(chatMessagesProvider(widget.chat.id).notifier);

    chatMessagesNotifier.sendMessage(
      content: content,
      replyToId: _selectedReplyMessage?.id,
    );

    _messageController.clear();
    _selectedReplyMessage = null;
    _isTyping = false;

    // IMPORTANT: Scroll to bottom immediately after sending
    // This ensures the new message appears at the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Also scroll after a slight delay to ensure the message is rendered
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  void _setReplyMessage(ChatMessage message) {
    setState(() {
      _selectedReplyMessage = message;
    });
    _messageFocusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _selectedReplyMessage = null;
    });
  }

  ChatUser? _getOtherUser() {
    if (_currentUserId == null) return null;
    return widget.chat.getOtherParticipant(_currentUserId!);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final otherUser = _getOtherUser();
    final isUserOnline = ref.watch(isUserOnlineProvider(otherUser?.id ?? ''));
    final socketConnectionStatus = ref.watch(socketConnectionProvider);

    if (_isLoadingAuth) {
      return Scaffold(
        backgroundColor: HospitalTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): _sendMessage,
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _sendMessage,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectedReplyMessage != null) {
            _clearReply();
          } else {
            Navigator.pop(context);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: HospitalTheme.background,
          appBar: _buildAppBar(context, otherUser, isUserOnline, isTablet,
              socketConnectionStatus),
          body: Column(
            children: [
              // Connection status indicator
              _buildConnectionStatus(socketConnectionStatus, isTablet),
              Expanded(
                child: _buildMessagesList(isTablet),
              ),
              if (_selectedReplyMessage != null) _buildReplyPreview(isTablet),
              _buildMessageInput(context, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(
      AsyncValue<bool> connectionStatus, bool isTablet) {
    return connectionStatus.when(
      data: (isConnected) {
        if (isConnected) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 8 : 6,
            horizontal: isTablet ? 16 : 12,
          ),
          color: HospitalTheme.warning,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: isTablet ? 18 : 16,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                'Connecting...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ChatUser? otherUser,
    bool isOnline,
    bool isTablet,
    AsyncValue<bool> connectionStatus,
  ) {
    return AppBar(
      backgroundColor: HospitalTheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildUserAvatar(otherUser, isOnline, isTablet ? 45 : 40),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUser?.displayName ?? 'Unknown User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      isOnline ? 'Online' : 'Last seen recently',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                    if (connectionStatus.value == false) ...[
                      SizedBox(width: isTablet ? 8 : 6),
                      Icon(
                        Icons.cloud_off,
                        color: Colors.white70,
                        size: isTablet ? 14 : 12,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: () {
            // TODO: Implement video call
          },
        ),
        IconButton(
          icon: const Icon(Icons.phone, color: Colors.white),
          onPressed: () {
            // TODO: Implement voice call
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'view_profile':
                // TODO: Navigate to user profile
                break;
              case 'clear_chat':
                _showClearChatDialog(context);
                break;
              case 'refresh_connection':
                final socketService = ref.read(socketServiceProvider);
                socketService.forceReconnect();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_profile',
              child: Text('View Profile'),
            ),
            const PopupMenuItem(
              value: 'clear_chat',
              child: Text('Clear Chat'),
            ),
            const PopupMenuItem(
              value: 'refresh_connection',
              child: Text('Refresh Connection'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserAvatar(ChatUser? user, bool isOnline, double size) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: HospitalTheme.surfaceLight,
            image: user?.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(
                      Methods().getGoogleDriveDirectLink(user!.imageUrl!),
                    ),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user?.imageUrl == null
              ? Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: HospitalTheme.primary,
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: HospitalTheme.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessagesList(bool isTablet) {
    return Consumer(
      builder: (context, ref, child) {
        final messagesState = ref.watch(chatMessagesProvider(widget.chat.id));

        print('=== MESSAGES LIST BUILD ===');
        print('Messages count: ${messagesState.messages.length}');
        print('Is loading: ${messagesState.isLoading}');
        print('Error: ${messagesState.error}');
        print('Current user ID for comparison: $_currentUserId');

        if (messagesState.isLoading && messagesState.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messagesState.error != null && messagesState.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isTablet ? 64 : 48,
                  color: HospitalTheme.error,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  'Failed to load messages',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(
                  'Error: ${messagesState.error}',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: HospitalTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                ElevatedButton(
                  onPressed: () {
                    print(
                        'Retrying to load messages for chat: ${widget.chat.id}');
                    ref
                        .read(chatMessagesProvider(widget.chat.id).notifier)
                        .loadMessages();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (messagesState.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: isTablet ? 64 : 48,
                  color: HospitalTheme.textLight,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(
                  'Start a conversation!',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: HospitalTheme.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        print('Showing ${messagesState.messages.length} messages');

        // IMPORTANT: Ensure messages are in correct order
        // Sort messages by timestamp to ensure proper chronological order
        final sortedMessages = List<ChatMessage>.from(messagesState.messages);
        sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          // IMPORTANT: Use sorted messages and correct item count
          itemCount: sortedMessages.length +
              (messagesState.isLoading && sortedMessages.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at top when loading more
            if (messagesState.isLoading &&
                sortedMessages.isNotEmpty &&
                index == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final messageIndex =
                messagesState.isLoading && sortedMessages.isNotEmpty
                    ? index - 1
                    : index;

            // Ensure we don't go out of bounds
            if (messageIndex >= sortedMessages.length) {
              return const SizedBox.shrink();
            }

            final message = sortedMessages[messageIndex];
            // FIXED: Proper comparison with current user ID
            final isMe = message.senderId == _currentUserId;

            print(
                'Message ${messageIndex}: senderId=${message.senderId}, currentUserId=$_currentUserId, isMe=$isMe');

            return _buildMessageBubble(message, isMe, isTablet);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool isTablet) {
    // Debug alignment
    print(
        'Building message bubble - isMe: $isMe, senderId: ${message.senderId}, currentUserId: $_currentUserId');

    return Container(
      margin: EdgeInsets.only(
        bottom: isTablet ? 12 : 8,
        // FIXED: Proper alignment based on isMe
        left: isMe ? (isTablet ? 80 : 60) : 0,
        right: isMe ? 0 : (isTablet ? 80 : 60),
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.replyToMessage != null)
            _buildReplyContent(message.replyToMessage!, isMe, isTablet),
          GestureDetector(
            onLongPress: () => _showMessageOptions(message, isMe),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 12 : 8,
              ),
              decoration: BoxDecoration(
                // FIXED: Proper color based on isMe
                color: isMe ? HospitalTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: HospitalTheme.shadowSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isDeleted)
                    Text(
                      'This message was deleted',
                      style: TextStyle(
                        color: isMe ? Colors.white70 : HospitalTheme.textLight,
                        fontStyle: FontStyle.italic,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    )
                  else
                    Container(
                      constraints: BoxConstraints(
                        minWidth: 20,
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Text(
                        message.content.isNotEmpty
                            ? message.content
                            : 'Empty message',
                        style: TextStyle(
                          // FIXED: Proper text color based on isMe
                          color: isMe ? Colors.white : HospitalTheme.textDark,
                          fontSize: isTablet ? 16 : 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  SizedBox(height: isTablet ? 8 : 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color:
                              isMe ? Colors.white70 : HospitalTheme.textLight,
                          fontSize: isTablet ? 12 : 10,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: isTablet ? 8 : 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : message.isDelivered
                                  ? Icons.done_all
                                  : message.isSent
                                      ? Icons.done
                                      : Icons.access_time,
                          size: isTablet ? 16 : 14,
                          color: message.isRead
                              ? Colors.greenAccent // Green for read messages
                              : Colors.white70,
                        ),
                      ],
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

  Widget _buildReplyContent(
      ChatMessage replyMessage, bool isMe, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 8 : 4),
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color:
            (isMe ? HospitalTheme.primary : Colors.grey[200])?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe ? HospitalTheme.primary : HospitalTheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replying to:',
            style: TextStyle(
              fontSize: isTablet ? 12 : 10,
              color: HospitalTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isTablet ? 4 : 2),
          Text(
            replyMessage.content,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: HospitalTheme.textMedium,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(bool isTablet) {
    final replyMessage = _selectedReplyMessage;
    if (replyMessage == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        border: Border(
          top: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: isTablet ? 60 : 50,
            color: HospitalTheme.primary,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to:',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: HospitalTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isTablet ? 4 : 2),
                Text(
                  replyMessage.content,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: HospitalTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: HospitalTheme.textMedium,
              size: isTablet ? 24 : 20,
            ),
            onPressed: _clearReply,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: HospitalTheme.primary,
                size: isTablet ? 28 : 24,
              ),
              onPressed: () {
                _showAttachmentOptions(context);
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: HospitalTheme.background,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: HospitalTheme.border),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 12 : 10,
                    ),
                    hintStyle: TextStyle(
                      color: HospitalTheme.textLight,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: isTablet ? 50 : 44,
                height: isTablet ? 50 : 44,
                decoration: const BoxDecoration(
                  color: HospitalTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage message, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isDeleted)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _setReplyMessage(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (isMe && !message.isDeleted)
              ListTile(
                leading: Icon(Icons.delete, color: HospitalTheme.error),
                title: Text(
                  'Delete',
                  style: TextStyle(color: HospitalTheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteMessageDialog(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: HospitalTheme.primary),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement photo picker
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: HospitalTheme.primary),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement video picker
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.insert_drive_file, color: HospitalTheme.primary),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement document picker
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteMessageDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(chatMessagesProvider(widget.chat.id).notifier)
                  .deleteMessage(message.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: HospitalTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
            'Are you sure you want to clear this entire chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear chat functionality
            },
            style: TextButton.styleFrom(
              foregroundColor: HospitalTheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
