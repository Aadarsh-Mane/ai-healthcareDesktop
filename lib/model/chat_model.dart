// models/chat_models.dart - FIXED FOR YOUR SPECIFIC API RESPONSE
import 'package:flutter/foundation.dart';

class ChatUser {
  final String id;
  final String email;
  final String usertype;
  final String? doctorName;
  final String? nurseName;
  final String? imageUrl;
  final String? department;
  final String? speciality;
  final String? phoneNumber;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatUser({
    required this.id,
    required this.email,
    required this.usertype,
    this.doctorName,
    this.nurseName,
    this.imageUrl,
    this.department,
    this.speciality,
    this.phoneNumber,
    this.isOnline = false,
    this.lastSeen,
  });

  String get displayName {
    if (usertype == 'doctor') return doctorName ?? email;
    if (usertype == 'nurse') return nurseName ?? email;
    return doctorName ?? nurseName ?? email;
  }

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      usertype: json['usertype'] ?? 'doctor',
      doctorName: json['doctorName'],
      nurseName: json['nurseName'],
      imageUrl: json['imageUrl'],
      department: json['department'],
      speciality: json['speciality'],
      phoneNumber: json['phoneNumber'],
      isOnline: json['isOnline'] ?? false,
      lastSeen:
          json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen']) : null,
    );
  }

  ChatUser copyWith({
    String? id,
    String? email,
    String? usertype,
    String? doctorName,
    String? nurseName,
    String? imageUrl,
    String? department,
    String? speciality,
    String? phoneNumber,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ChatUser(
      id: id ?? this.id,
      email: email ?? this.email,
      usertype: usertype ?? this.usertype,
      doctorName: doctorName ?? this.doctorName,
      nurseName: nurseName ?? this.nurseName,
      imageUrl: imageUrl ?? this.imageUrl,
      department: department ?? this.department,
      speciality: speciality ?? this.speciality,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

// FIXED ChatMessage model for your specific API response structure
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final bool isSent;
  final String? replyToId;
  final ChatMessage? replyToMessage;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? senderName;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.isSent = true,
    this.replyToId,
    this.replyToMessage,
    this.isDeleted = false,
    this.deletedAt,
    this.senderName,
  });

  // FIXED factory method for your specific API response
  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {String? currentUserId}) {
    try {
      print('=== PARSING CHAT MESSAGE FROM YOUR API ===');
      print('Raw JSON: $json');

      // Handle message ID
      String messageId = json['_id']?.toString() ??
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Handle chat ID - might need to be set externally
      String chatId = json['chatId']?.toString() ?? '';

      // Handle sender ID
      String senderId = json['senderId']?.toString() ?? '';

      // Handle sender name
      String? senderName = json['senderName']?.toString();

      // Handle content
      String content = json['content']?.toString() ?? '';

      // Handle message type
      String messageType = json['messageType']?.toString() ?? 'text';

      // Handle timestamp - your API uses 'createdAt'
      DateTime timestamp = DateTime.now();
      if (json['createdAt'] != null) {
        timestamp =
            DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
      }

      // IMPROVED: Handle read status - check if current user has read this message
      bool isRead = false;
      if (json['readBy'] is List && currentUserId != null) {
        final readBy = json['readBy'] as List;
        // Check if the current user ID is in the readBy list
        isRead = readBy.any((readInfo) {
          if (readInfo is Map<String, dynamic>) {
            return readInfo['userId']?.toString() == currentUserId;
          }
          return readInfo?.toString() == currentUserId;
        });
      } else if (json['readBy'] is List) {
        final readBy = json['readBy'] as List;
        // If no current user ID provided, consider read if anyone has read it
        isRead = readBy.isNotEmpty;
      }

      // Handle delivery and sent status
      bool isDelivered = true; // Default to true for messages from API
      bool isSent = true; // Default to true for messages from API

      // Handle reply information
      String? replyToId = json['replyToId']?.toString();
      ChatMessage? replyToMessage;
      if (json['replyToMessage'] is Map) {
        try {
          replyToMessage = ChatMessage.fromJson(json['replyToMessage'],
              currentUserId: currentUserId);
        } catch (e) {
          print('Failed to parse reply message: $e');
        }
      }

      // Handle deletion status
      bool isDeleted = json['isDeleted'] == true;
      DateTime? deletedAt = json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null;

      final message = ChatMessage(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        content: content,
        messageType: messageType,
        timestamp: timestamp,
        isRead: isRead,
        isDelivered: isDelivered,
        isSent: isSent,
        replyToId: replyToId,
        replyToMessage: replyToMessage,
        isDeleted: isDeleted,
        deletedAt: deletedAt,
        senderName: senderName,
      );

      print(
          'Parsed message successfully: "${message.content}" at ${message.timestamp}, isRead: $isRead');
      print('=== END PARSING ===');

      return message;
    } catch (e) {
      print('ERROR parsing ChatMessage: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    bool? isDelivered,
    bool? isSent,
    String? replyToId,
    ChatMessage? replyToMessage,
    bool? isDeleted,
    DateTime? deletedAt,
    String? senderName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      isSent: isSent ?? this.isSent,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      senderName: senderName ?? this.senderName,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, chatId: $chatId, senderId: $senderId, content: "$content", timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// FIXED Chat model for your specific API response structure
class Chat {
  final String id;
  final List<String> participants;
  final List<ChatUser> participantDetails;
  final ChatMessage? lastMessage;
  final DateTime? lastActivity;
  final int unreadCount;
  final bool isActive;
  final String? chatType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.participants,
    this.participantDetails = const [],
    this.lastMessage,
    this.lastActivity,
    this.unreadCount = 0,
    this.isActive = true,
    this.chatType,
    required this.createdAt,
    required this.updatedAt,
  });

  // FIXED factory method for your messages API response
  factory Chat.fromMessages(Map<String, dynamic> json) {
    try {
      print('=== PARSING CHAT FROM MESSAGES API ===');
      print('Raw JSON keys: ${json.keys.toList()}');

      // Get chat ID from the response
      String chatId = json['chatId']?.toString() ?? '';

      // Parse participants
      List<ChatUser> participantDetails = [];
      List<String> participants = [];

      if (json['participants'] is List) {
        final participantsData = json['participants'] as List;
        for (var participant in participantsData) {
          if (participant is Map<String, dynamic>) {
            final user = ChatUser.fromJson(participant);
            participantDetails.add(user);
            participants.add(user.id);
          }
        }
      }

      // Parse messages and get the last one
      ChatMessage? lastMessage;
      if (json['messages'] is List) {
        final messagesData = json['messages'] as List;
        if (messagesData.isNotEmpty) {
          // Get the last message (newest one)
          final lastMessageData = messagesData.last as Map<String, dynamic>;
          // Set the chatId for the message
          lastMessageData['chatId'] = chatId;
          lastMessage = ChatMessage.fromJson(lastMessageData);
        }
      }

      // Set timestamps
      DateTime createdAt = DateTime.now();
      DateTime updatedAt = DateTime.now();

      final chat = Chat(
        id: chatId,
        participants: participants,
        participantDetails: participantDetails,
        lastMessage: lastMessage,
        lastActivity: lastMessage?.timestamp ?? updatedAt,
        unreadCount: 0, // You might need to calculate this
        isActive: true,
        chatType: 'direct',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      print('Chat parsed successfully: ${chat.id}');
      print('=== END PARSING CHAT ===');

      return chat;
    } catch (e) {
      print('ERROR parsing Chat from messages: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  // Original factory method for chat list API
  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      print('=== PARSING CHAT FROM LIST API ===');
      print('Raw JSON: $json');

      // Get chat ID
      String chatId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

      // Parse partner information (the other user in the chat)
      List<ChatUser> participantDetails = [];
      List<String> participants = [];

      if (json['partner'] != null && json['partner'] is Map<String, dynamic>) {
        final partnerData = json['partner'] as Map<String, dynamic>;
        final partner = ChatUser.fromJson(partnerData);
        participantDetails.add(partner);
        participants.add(partner.id);

        print('Partner parsed: ${partner.displayName} (${partner.id})');
      }

      // Parse last message if exists
      ChatMessage? lastMessage;
      if (json['lastMessage'] != null &&
          json['lastMessage'] is Map<String, dynamic>) {
        try {
          final lastMessageData = json['lastMessage'] as Map<String, dynamic>;
          // Add chatId to the message data since it might be missing
          lastMessageData['chatId'] = chatId;
          lastMessage = ChatMessage.fromJson(lastMessageData);
          print('Last message parsed: ${lastMessage.content}');
        } catch (e) {
          print('Failed to parse last message: $e');
        }
      }

      // Parse unread count
      int unreadCount = 0;
      if (json['unreadCount'] is int) {
        unreadCount = json['unreadCount'];
      } else if (json['unreadCount'] is String) {
        unreadCount = int.tryParse(json['unreadCount']) ?? 0;
      }

      // Parse timestamps
      DateTime createdAt = DateTime.now();
      DateTime updatedAt = DateTime.now();

      if (json['createdAt'] != null) {
        createdAt =
            DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
      }

      if (json['updatedAt'] != null) {
        updatedAt =
            DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now();
      }

      // Use lastMessage timestamp as lastActivity, fallback to updatedAt
      DateTime? lastActivity = lastMessage?.timestamp ?? updatedAt;

      final chat = Chat(
        id: chatId,
        participants: participants,
        participantDetails: participantDetails,
        lastMessage: lastMessage,
        lastActivity: lastActivity,
        unreadCount: unreadCount,
        isActive: json['isActive'] ?? true,
        chatType: json['chatType']?.toString(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      print('Chat parsed successfully: ${chat.id}');
      print('=== END PARSING CHAT ===');

      return chat;
    } catch (e) {
      print('ERROR parsing Chat: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Chat copyWith({
    String? id,
    List<String>? participants,
    List<ChatUser>? participantDetails,
    ChatMessage? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
    bool? isActive,
    String? chatType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantDetails: participantDetails ?? this.participantDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      chatType: chatType ?? this.chatType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the other participant in the chat (for 1-on-1 chats)
  ChatUser? getOtherParticipant(String currentUserId) {
    try {
      return participantDetails.firstWhere(
        (user) => user.id != currentUserId,
      );
    } catch (e) {
      return participantDetails.isNotEmpty ? participantDetails.first : null;
    }
  }

  @override
  String toString() {
    return 'Chat(id: $id, participants: ${participants.length}, unreadCount: $unreadCount)';
  }
}

class TypingUser {
  final String userId;
  final String chatId;
  final String userName;
  final DateTime timestamp;

  const TypingUser({
    required this.userId,
    required this.chatId,
    required this.userName,
    required this.timestamp,
  });

  factory TypingUser.fromJson(Map<String, dynamic> json) {
    return TypingUser(
      userId: json['userId'] ?? '',
      chatId: json['chatId'] ?? '',
      userName: json['userName'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChatState {
  final List<Chat> chats;
  final bool isLoading;
  final String? error;
  final int totalUnreadCount;

  final List<String> onlineUsers;
  final Map<String, List<TypingUser>> typingUsers;

  const ChatState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
    this.totalUnreadCount = 0,
    this.onlineUsers = const [],
    this.typingUsers = const {},
  });

  ChatState copyWith({
    List<Chat>? chats,
    bool? isLoading,
    String? error,
    int? totalUnreadCount,
    List<String>? onlineUsers,
    Map<String, List<TypingUser>>? typingUsers,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}

class ChatMessagesState {
  final String chatId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool hasMoreMessages;
  final String? error;
  final int currentPage;

  const ChatMessagesState({
    required this.chatId,
    this.messages = const [],
    this.isLoading = false,
    this.hasMoreMessages = true,
    this.error,
    this.currentPage = 1,
  });

  ChatMessagesState copyWith({
    String? chatId,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? hasMoreMessages,
    String? error,
    int? currentPage,
  }) {
    return ChatMessagesState(
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}
