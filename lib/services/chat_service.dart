import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'api_endpoints.dart';
import 'auth_service.dart';
import '../models/chat.dart';

class ChatService {
  static StompClient? _stompClient;
  static Function(ChatMessage)? _onMessageReceived;
  static String? _currentUserId;

  // Initialize WebSocket connection
  static Future<void> connect(String userId, Function(ChatMessage) onMessageReceived) async {
    _currentUserId = userId;
    _onMessageReceived = onMessageReceived;

    final token = await AuthService.getToken();

    _stompClient?.deactivate();
    
    _stompClient = StompClient(
      config: StompConfig(
        url: ApiEndpoints.chatWebSocket,
        onConnect: onConnectCallback,
        onWebSocketError: (dynamic error) {
          print('❌ WebSocket error: $error');
        },
        onStompError: (StompFrame frame) {
          print('❌ STOMP error: ${frame.body}');
        },
        onDisconnect: (StompFrame frame) {
          print('🔌 Disconnected from WebSocket');
        },
        beforeConnect: () async {
          print('🔄 Connecting to WebSocket...');
        },
        onWebSocketDone: () {
          print('✅ WebSocket connection closed');
        },
        // SockJS fallback for better compatibility
        useSockJS: true,
        
        // Connection settings
        connectionTimeout: const Duration(seconds: 10),
        reconnectDelay: const Duration(seconds: 3),
     
        
        // Heartbeat to keep connection alive
        heartbeatIncoming: const Duration(seconds: 20),
        heartbeatOutgoing: const Duration(seconds: 20),
        
        // Add authorization headers
        stompConnectHeaders: token != null 
          ? {
              'Authorization': 'Bearer $token',
              'accept-version': '1.1,1.0',
              'heart-beat': '0,0',
              'userType': 'seller',
            }
          : {
              'accept-version': '1.1,1.0',
              'heart-beat': '0,0',
              'userType': 'seller',
            },
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );

    print('🚀 Activating STOMP client with WebSocket URL: ${ApiEndpoints.chatWebSocket}');
    _stompClient?.activate();
    
    // Give it a moment to connect
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static void onConnectCallback(StompFrame frame) {
    print('✅ Connected to chat WebSocket at ${DateTime.now()}');
    print('🔗 Connection details - Frame command: ${frame.command}');
    print('👤 Connected with userId: $_currentUserId');
    
    // Subscribe to user's message queue WITH FULL PATH including userId
    final subscriptionDestination = '/user/$_currentUserId/queue/messages';
    print('📡 Subscribing to: $subscriptionDestination');
    
    _stompClient?.subscribe(
      destination: subscriptionDestination,
      callback: (StompFrame frame) {
        print('🎉🎉🎉 WEBSOCKET CALLBACK TRIGGERED! 🎉🎉🎉');
        print('📨 Received WebSocket frame');
        print('📦 Frame body: ${frame.body}');
        print('📍 Frame destination: ${frame.headers?["destination"] ?? "N/A"}');
        print('📍 Frame subscription: ${frame.headers?["subscription"] ?? "N/A"}');
        if (frame.body != null && frame.body!.isNotEmpty) {
          try {
            final message = ChatMessage.fromJson(jsonDecode(frame.body!));
            print('✅ Parsed message: ID=${message.messageId}, Content=${message.content}, Type=${message.messageType}');
            print('✅ Conversation: ${message.conversationId}, Sender: ${message.senderId}');
            _onMessageReceived?.call(message);
          } catch (e) {
            print('❌ Error parsing WebSocket message: $e');
            print('❌ Stack trace: ${e.toString()}');
          }
        } else {
          print('⚠️ Frame body is null or empty');
        }
      },
    );
    print('✅ Subscribed to $subscriptionDestination');
  }

  // Send message via WebSocket
  static Map<String, dynamic> sendMessageViaWebSocket(String receiverId, String content, {String messageType = 'TEXT', String? conversationId}) {
    if (_stompClient == null || !_stompClient!.connected) {
      print('❌ WebSocket not connected, cannot send message');
      throw Exception('WebSocket not connected');
    }

    final messageData = {
      'senderId': _currentUserId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType,
      if (conversationId != null) 'conversationId': conversationId,
    };
    
    print('📤 Sending WebSocket message: $messageData');
    print('📤 Destination: /app/send');
    print('📤 Client connected: ${_stompClient!.connected}');
    
    _stompClient?.send(
      destination: '/app/send',
      body: jsonEncode(messageData),
    );
    
    print('✅ WebSocket message sent');
    
    // Return optimistic message data for sender's UI
    return {
      'messageId': 'temp-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
      'conversationId': conversationId ?? '',
      'senderId': _currentUserId ?? '',
      'senderName': 'You', // Will be updated when real message arrives
      'senderAvatar': null,
      'receiverId': receiverId,
      'content': content,
      'imageUrl': null,
      'messageType': messageType,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Disconnect WebSocket
  static void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
  }

  static bool get isConnected => _stompClient?.connected ?? false;

  // REST API: Get conversations
  static Future<List<Conversation>> getConversations() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.chatConversations),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          if (data is List) {
            return data.map((conv) => Conversation.fromJson(conv)).toList();
          } else {
            return [];
          }
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to get conversations');
        }
      } else {
        throw Exception('Failed to get conversations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting conversations: $e');
    }
  }

  // REST API: Get messages in a conversation
  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.chatMessages(conversationId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          if (data is List) {
            return data.map((msg) => ChatMessage.fromJson(msg)).toList();
          } else {
            return [];
          }
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to get messages');
        }
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting messages: $e');
    }
  }

  // REST API: Send message
  static Future<ChatMessage?> sendMessage(SendMessageRequest request) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.chatSend),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return ChatMessage.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // REST API: Mark conversation as read
  static Future<void> markAsRead(String conversationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.chatMarkRead(conversationId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking as read: $e');
    }
  }

  // REST API: Send image message
  static Future<ChatMessage?> sendImageMessage(String receiverId, File imageFile) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.chatSendImage),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add receiverId field
      request.fields['receiverId'] = receiverId;

      // Add image file
      final fileName = path.basename(imageFile.path);
      final mimeType = _getMimeType(fileName);
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return ChatMessage.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to send image');
        }
      } else {
        throw Exception('Failed to send image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending image: $e');
    }
  }

  // REST API: Start/get conversation
  static Future<Conversation?> startConversation(String otherUserId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final request = StartConversationRequest(otherUserId: otherUserId);

      final response = await http.post(
        Uri.parse(ApiEndpoints.chatStartConversation),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return Conversation.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to start conversation');
        }
      } else {
        throw Exception('Failed to start conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error starting conversation: $e');
    }
  }

  // Helper method to get MIME type from file extension
  static String _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }
}