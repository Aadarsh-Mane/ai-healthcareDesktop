import 'package:doctordesktop/Doctor/NewChatScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/chat_model.dart';
import 'package:doctordesktop/providers/chat_provider.dart';
import 'package:doctordesktop/screens/ChatScreen.dart';
import 'package:doctordesktop/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Simple provider to get current user ID from SharedPreferences
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
});

// Provider to get user data from SharedPreferences
final currentUserProvider = FutureProvider<ChatUser?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('user_data');
  if (userData != null) {
    try {
      final Map<String, dynamic> userMap = json.decode(userData);
      return ChatUser.fromJson(userMap);
    } catch (e) {
      debugPrint('Error parsing user data: $e');
    }
  }
  return null;
});

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _currentUserId;
  ChatUser? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _initializeSocketConnection();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userData = prefs.getString('user_data');

    if (userId != null) {
      setState(() {
        _currentUserId = userId;
      });
    }

    if (userData != null) {
      try {
        final Map<String, dynamic> userMap = json.decode(userData);
        setState(() {
          _currentUser = ChatUser.fromJson(userMap);
        });
      } catch (e) {
        debugPrint('Error parsing user data: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final socketService = ref.read(socketServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        if (!socketService.isConnected) {
          _initializeSocketConnection();
        }
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

  Future<void> _initializeSocketConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('userId');

    if (token != null && userId != null) {
      final socketService = ref.read(socketServiceProvider);

      if (!socketService.isConnected) {
        await socketService.connect(
          token: token,
          userId: userId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: _buildAppBar(context, isTablet),
      body: _buildBody(isTablet),
      floatingActionButton: _buildFloatingActionButton(context, isTablet),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    return AppBar(
      backgroundColor: HospitalTheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      title: Row(
        children: [
          Text(
            'Chats',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildConnectionStatus(isTablet),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: Colors.white,
            size: isTablet ? 28 : 24,
          ),
          onPressed: () {
            // TODO: Implement search functionality
            _showSearchDialog(context);
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Colors.white,
            size: isTablet ? 28 : 24,
          ),
          onSelected: (value) {
            switch (value) {
              case 'new_group':
                // TODO: Implement group chat creation
                break;
              case 'settings':
                // TODO: Navigate to chat settings
                break;
              case 'help':
                // TODO: Show help dialog
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'new_group',
              child: Text('New Group'),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Text('Settings'),
            ),
            const PopupMenuItem(
              value: 'help',
              child: Text('Help'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(bool isTablet) {
    return Consumer(
      builder: (context, ref, child) {
        final connectionAsync = ref.watch(socketConnectionProvider);

        return connectionAsync.when(
          data: (isConnected) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 8,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: isConnected
                  ? HospitalTheme.success.withOpacity(0.2)
                  : HospitalTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isTablet ? 8 : 6,
                  height: isTablet ? 8 : 6,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? HospitalTheme.success
                        : HospitalTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Text(
                  isConnected ? 'Online' : 'Connecting...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildBody(bool isTablet) {
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatListProvider);

        if (chatState.isLoading && chatState.chats.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (chatState.error != null && chatState.chats.isEmpty) {
          return _buildErrorState(chatState.error!, isTablet);
        }

        if (chatState.chats.isEmpty) {
          return _buildEmptyState(isTablet);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(chatListProvider.notifier).refreshChats();
          },
          child: ListView.separated(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            itemCount: chatState.chats.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: isTablet ? 12 : 8),
            itemBuilder: (context, index) {
              final chat = chatState.chats[index];
              return _buildChatTile(chat, isTablet);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isTablet ? 64 : 48,
              color: HospitalTheme.error,
            ),
            SizedBox(height: isTablet ? 24 : 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              error,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 24 : 16),
            ElevatedButton(
              onPressed: () {
                ref.read(chatListProvider.notifier).refreshChats();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: isTablet ? 80 : 64,
              color: HospitalTheme.textLight,
            ),
            SizedBox(height: isTablet ? 24 : 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Start a conversation with a doctor or colleague',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToNewChat(),
              icon: const Icon(Icons.add),
              label: const Text('Start Chat'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: isTablet ? 16 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(Chat chat, bool isTablet) {
    // Use the stored current user ID instead of getting from provider
    final otherUser = chat.getOtherParticipant(_currentUserId ?? '');
    final isOnline = ref.watch(isUserOnlineProvider(otherUser?.id ?? ''));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        side: BorderSide(color: HospitalTheme.border),
      ),
      child: InkWell(
        onTap: () => _navigateToChat(chat),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Row(
            children: [
              _buildChatAvatar(otherUser, isOnline, isTablet),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUser?.displayName ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessage != null)
                          Text(
                            _formatChatTime(chat.lastMessage!.timestamp),
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: chat.unreadCount > 0
                                  ? HospitalTheme.primary
                                  : HospitalTheme.textLight,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    if (otherUser?.department != null) ...[
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        otherUser!.department!,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: HospitalTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: isTablet ? 8 : 6),
                    Row(
                      children: [
                        Expanded(
                          child: chat.lastMessage != null
                              ? _buildLastMessage(
                                  chat.lastMessage!, _currentUserId, isTablet)
                              : Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: HospitalTheme.textLight,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                        if (chat.unreadCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 10 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: HospitalTheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              chat.unreadCount > 99
                                  ? '99+'
                                  : chat.unreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 12 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatAvatar(ChatUser? user, bool isOnline, bool isTablet) {
    final size = isTablet ? 60.0 : 50.0;

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

  Widget _buildLastMessage(
      ChatMessage message, String? currentUserId, bool isTablet) {
    final isMe = message.senderId == currentUserId;

    return Row(
      children: [
        if (isMe) ...[
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
                ? HospitalTheme.primary
                : HospitalTheme.textLight,
          ),
          SizedBox(width: isTablet ? 6 : 4),
        ],
        Expanded(
          child: Text(
            message.isDeleted
                ? 'This message was deleted'
                : (isMe ? 'You: ${message.content}' : message.content),
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: message.isDeleted
                  ? HospitalTheme.textLight
                  : HospitalTheme.textMedium,
              fontStyle:
                  message.isDeleted ? FontStyle.italic : FontStyle.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, bool isTablet) {
    return FloatingActionButton(
      onPressed: _navigateToNewChat,
      backgroundColor: HospitalTheme.primary,
      child: Icon(
        Icons.add_comment,
        size: isTablet ? 28 : 24,
        color: Colors.white,
      ),
    );
  }

  void _navigateToChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenDesktop(chat: chat),
      ),
    );
  }

  void _navigateToNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewChatScreen(),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Chats'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search messages, users...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            // TODO: Implement search functionality
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatChatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today - show time
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      // This week - show day
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
