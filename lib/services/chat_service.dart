// services/chat_service.dart - FIXED: Correct message order from API
import 'dart:convert';
import 'dart:developer';

import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/chat_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ChatService {
  // Search doctors
  static Future<List<ChatUser>> searchDoctors({
    required String query,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/chat/search-doctors?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> doctorsData = responseData['data'] ?? [];

        return doctorsData.map((doctor) => ChatUser.fromJson(doctor)).toList();
      } else {
        throw Exception('Failed to search doctors: ${response.statusCode}');
      }
    } catch (e) {
      log('Error searching doctors: $e');
      throw Exception('Failed to search doctors: $e');
    }
  }

  // FIXED: Get user chats list for your API response structure
  static Future<List<Chat>> getUserChats({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('=== FETCHING USER CHATS ===');
      print('URL: ${BASE_URL}/chat/list?page=$page&limit=$limit');

      final response = await http.get(
        Uri.parse('${BASE_URL}/chat/list?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if the response is successful
        if (responseData['success'] != true) {
          throw Exception('API returned unsuccessful response');
        }

        // Extract the data array from your API response
        final List<dynamic> chatsData = responseData['data'] ?? [];

        print('Found ${chatsData.length} chats in response');

        // Parse each chat item
        final List<Chat> chats = chatsData.map((chatJson) {
          try {
            print('Parsing chat: $chatJson');
            return Chat.fromJson(chatJson);
          } catch (e) {
            print('Failed to parse individual chat: $e');
            print('Chat data: $chatJson');
            rethrow;
          }
        }).toList();

        print('Successfully parsed ${chats.length} chats');
        print('=== END FETCHING CHATS ===');

        return chats;
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error Response: ${response.body}');
        throw Exception('Failed to get chats: ${response.statusCode}');
      }
    } catch (e) {
      log('Error getting user chats: $e');
      print('Detailed error: $e');
      throw Exception('Failed to get chats: $e');
    }
  }

  // Get or create chat with a user
  static Future<Chat> getOrCreateChat({
    required String recipientId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/chat/$recipientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return Chat.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to get/create chat: ${response.statusCode}');
      }
    } catch (e) {
      log('Error getting/creating chat: $e');
      throw Exception('Failed to get/create chat: $e');
    }
  }

  // FIXED: Get chat messages with proper ordering
  static Future<List<ChatMessage>> getChatMessages({
    required String chatId,
    required String token,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final url = '${BASE_URL}/chat/$chatId/messages?page=$page&limit=$limit';
      print('=== API REQUEST ===');
      print('URL: $url');
      print('Chat ID: $chatId');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Updated to match your API response structure
        final List<dynamic> messagesData =
            responseData['data']['messages'] ?? [];

        print('Messages count from API: ${messagesData.length}');

        final messages = messagesData.map((message) {
          print('Raw message data: $message');
          return ChatMessage.fromJson(message);
        }).toList();

        print('Parsed messages count: ${messages.length}');

        // IMPORTANT: Sort messages by timestamp (oldest first, newest last)
        // This ensures chronological order in the chat
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        print('=== MESSAGE ORDER AFTER SORTING ===');
        for (int i = 0; i < messages.length; i++) {
          print('[$i] "${messages[i].content}" - ${messages[i].timestamp}');
        }
        print('=== END MESSAGE ORDER ===');

        return messages;
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting chat messages: $e');
      throw Exception('Failed to get messages: ${e}');
    }
  }

  // Send message via HTTP (backup for when socket fails)
  static Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
    required String token,
    String messageType = 'text',
    String? replyToId,
  }) async {
    try {
      print('=== SENDING MESSAGE VIA HTTP ===');
      print('Chat ID: $chatId');
      print('Content: "$content"');

      final requestBody = {
        'content': content,
        'messageType': messageType,
        if (replyToId != null) 'replyToId': replyToId,
      };

      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('${BASE_URL}/chat/$chatId/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final sentMessage = ChatMessage.fromJson(responseData['message']);

        print('Message sent successfully via HTTP: "${sentMessage.content}"');
        return sentMessage;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Mark chat as read
  static Future<void> markChatAsRead({
    required String chatId,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${BASE_URL}/chat/$chatId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      log('Error marking chat as read: $e');
      throw Exception('Failed to mark chat as read: $e');
    }
  }

  // Get unread messages count
  static Future<int> getUnreadCount({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/chat/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['unreadCount'] ?? 0;
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      log('Error getting unread count: $e');
      return 0;
    }
  }

  // Delete message
  static Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}/chat/$chatId/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      log('Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  // Check socket status (for debugging)
  static Future<Map<String, dynamic>> checkSocketStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/socket-status'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to check socket status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error checking socket status: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
}

// Riverpod providers for chat service
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// Provider for getting user chats
final userChatsProvider =
    FutureProvider.family<List<Chat>, Map<String, dynamic>>(
        (ref, params) async {
  final token = params['token'] as String;
  final page = params['page'] as int? ?? 1;
  final limit = params['limit'] as int? ?? 20;

  return ChatService.getUserChats(
    token: token,
    page: page,
    limit: limit,
  );
});

// Provider for getting chat messages
final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, Map<String, dynamic>>(
        (ref, params) async {
  final chatId = params['chatId'] as String;
  final token = params['token'] as String;
  final page = params['page'] as int? ?? 1;
  final limit = params['limit'] as int? ?? 50;

  return ChatService.getChatMessages(
    chatId: chatId,
    token: token,
    page: page,
    limit: limit,
  );
});

// Provider for searching doctors
final searchDoctorsProvider =
    FutureProvider.family<List<ChatUser>, Map<String, String>>(
        (ref, params) async {
  final query = params['query']!;
  final token = params['token']!;

  return ChatService.searchDoctors(query: query, token: token);
});

// Provider for unread count
final unreadCountProvider =
    FutureProvider.family<int, String>((ref, token) async {
  return ChatService.getUnreadCount(token: token);
});
