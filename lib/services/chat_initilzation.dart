import 'dart:developer';
import 'package:doctordesktop/model/chat_model.dart';
import 'package:doctordesktop/providers/chat_provider.dart';
import 'package:doctordesktop/screens/ChatScreen.dart';
import 'package:doctordesktop/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple auth state class to track authentication
class AuthenticationState {
  final bool isAuthenticated;
  final String? token;
  final String? userId;

  AuthenticationState({
    required this.isAuthenticated,
    this.token,
    this.userId,
  });
}

// Provider for authentication state
final authStateProvider = StateProvider<AuthenticationState>((ref) {
  return AuthenticationState(isAuthenticated: false);
});

// Provider to check auth token from SharedPreferences
final authTokenProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
});

class ChatInitializationService {
  static final ChatInitializationService _instance =
      ChatInitializationService._internal();
  factory ChatInitializationService() => _instance;
  ChatInitializationService._internal();

  bool _isInitialized = false;
  ProviderContainer? _container;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(ProviderContainer container) async {
    if (_isInitialized) return;

    _container = container;

    try {
      log('Initializing chat system...');

      // Get auth token directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('userId');

      // Update auth state
      if (token != null) {
        _container!.read(authStateProvider.notifier).state =
            AuthenticationState(
          isAuthenticated: true,
          token: token,
          userId: userId,
        );

        // Setup chat system if authenticated
        await _setupChatSystem(token, userId);
      }

      // Listen to auth state changes
      _container!.listen<AuthenticationState>(
        authStateProvider,
        (previous, next) async {
          await _handleAuthStateChange(previous, next);
        },
      );

      _isInitialized = true;
      log('Chat system initialized successfully');
    } catch (e) {
      log('Failed to initialize chat system: $e');
      throw Exception('Chat initialization failed: $e');
    }
  }

  Future<void> _handleAuthStateChange(
    AuthenticationState? previous,
    AuthenticationState next,
  ) async {
    try {
      // User logged in
      if ((previous == null || !previous.isAuthenticated) &&
          next.isAuthenticated) {
        log('User logged in, setting up chat system');
        await _setupChatSystem(next.token, next.userId);
      }

      // User logged out
      else if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        log('User logged out, cleaning up chat system');
        await _cleanupChatSystem();
      }
    } catch (e) {
      log('Error handling auth state change: $e');
    }
  }

  Future<void> _setupChatSystem(String? token, String? userId) async {
    if (token == null || userId == null) {
      log('Cannot setup chat: missing token or userId');
      return;
    }

    try {
      // Initialize socket connection
      final socketService = _container!.read(socketServiceProvider);

      if (!socketService.isConnected) {
        await socketService.connect(
          token: token,
          userId: userId,
        );
      }

      // Load initial chat data
      _container!.read(chatListProvider.notifier).loadChats();

      log('Chat system setup completed for user: $userId');
    } catch (e) {
      log('Error setting up chat system: $e');
    }
  }

  Future<void> _cleanupChatSystem() async {
    try {
      // Disconnect socket
      final socketService = _container!.read(socketServiceProvider);
      await socketService.disconnect();

      log('Chat system cleanup completed');
    } catch (e) {
      log('Error cleaning up chat system: $e');
    }
  }

  void dispose() {
    _cleanupChatSystem();
    _isInitialized = false;
    _container = null;
  }
}

// Widget to initialize chat system in your app
class ChatSystemInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const ChatSystemInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ChatSystemInitializer> createState() =>
      _ChatSystemInitializerState();
}

class _ChatSystemInitializerState extends ConsumerState<ChatSystemInitializer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatSystem();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _handleAppLifecycleChange(state);
  }

  Future<void> _initializeChatSystem() async {
    try {
      final chatService = ChatInitializationService();
      // Get the ProviderContainer instance
      final container = ProviderScope.containerOf(context);
      await chatService.initialize(container);
    } catch (e) {
      log('Failed to initialize chat system: $e');
    }
  }

  void _handleAppLifecycleChange(AppLifecycleState state) {
    final socketService = ref.read(socketServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        // Reconnect if needed
        _checkAndReconnectSocket();
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

  Future<void> _checkAndReconnectSocket() async {
    final socketService = ref.read(socketServiceProvider);
    if (!socketService.isConnected) {
      _reconnectSocket();
    }
  }

  Future<void> _reconnectSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('userId');

      if (token != null && userId != null) {
        final socketService = ref.read(socketServiceProvider);
        await socketService.connect(
          token: token,
          userId: userId,
        );
      }
    } catch (e) {
      log('Error reconnecting socket: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Chat Badge Widget for showing unread count
class ChatNotificationBadge extends ConsumerWidget {
  final Widget child;
  final double? badgeSize;
  final Color? badgeColor;

  const ChatNotificationBadge({
    super.key,
    required this.child,
    this.badgeSize,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(totalUnreadCountProvider);

    if (unreadCount <= 0) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: badgeColor ?? Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: BoxConstraints(
              minWidth: badgeSize ?? 16,
              minHeight: badgeSize ?? 16,
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// Typing Indicator Widget
class TypingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const TypingIndicator({
    super.key,
    this.color = Colors.grey,
    this.size = 4.0,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.33, 0.66, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(_animation1),
        SizedBox(width: widget.size * 0.5),
        _buildDot(_animation2),
        SizedBox(width: widget.size * 0.5),
        _buildDot(_animation3),
      ],
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (animation.value * 0.5),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.3 + (animation.value * 0.7)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// Connection Status Indicator
class ConnectionStatusIndicator extends ConsumerWidget {
  final bool showText;
  final double size;

  const ConnectionStatusIndicator({
    super.key,
    this.showText = true,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(socketConnectionProvider);

    return connectionAsync.when(
      data: (isConnected) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color: isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 8),
            const Text(
              'Connecting...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      error: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 8),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Navigation Helper
class ChatNavigationHelper {
  static void navigateToChatList(BuildContext context) {
    Navigator.pushNamed(context, '/chat-list');
  }

  static void navigateToNewChat(BuildContext context) {
    Navigator.pushNamed(context, '/new-chat');
  }

  static void navigateToChat(BuildContext context, Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenDesktop(chat: chat),
      ),
    );
  }

  static void navigateToChatWithUser(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      final chat =
          await ref.read(chatListProvider.notifier).createChatWithUser(userId);

      if (chat != null && context.mounted) {
        navigateToChat(context, chat);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Extensions for easier usage
extension ChatUserExtensions on ChatUser {
  String get initials {
    final name = displayName;
    if (name.isEmpty) return '?';

    final nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
  }

  Color get statusColor {
    switch (usertype.toLowerCase()) {
      case 'doctor':
        return Colors.blue;
      case 'nurse':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

extension ChatMessageExtensions on ChatMessage {
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);
    return messageDate == today;
  }

  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);
    return messageDate == yesterday;
  }

  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
