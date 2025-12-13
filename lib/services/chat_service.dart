import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'api_endpoints.dart';
import 'auth_service.dart';

class ChatService {
  static StompClient? _stompClient;
  static Function(Message)? _onMessageReceived;

  // Initialize WebSocket connection
  static Future<void> connect({
    required String userId,
    required Function(Message) onMessageReceived,
  }) async {
    _onMessageReceived = onMessageReceived;

    _stompClient = StompClient(
      config: StompConfig(
        url: ApiEndpoints.wsUrl,
        onConnect: (StompFrame frame) {
          print('Connected to WebSocket');
          
          // Subscribe to receive messages
          _stompClient!.subscribe(
            destination: '/user/$userId/queue/messages',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                try {
                  final message = Message.fromJson(jsonDecode(frame.body!));
                  _onMessageReceived?.call(message);
                } catch (e) {
                  print('Error parsing message: $e');
                }
              }
            },
          );
        },
        onWebSocketError: (dynamic error) {
          print('WebSocket Error: $error');
        },
        onStompError: (StompFrame frame) {
          print('Stomp Error: ${frame.body}');
        },
        onDisconnect: (StompFrame frame) {
          print('Disconnected from WebSocket');
        },
      ),
    );

    _stompClient!.activate();
  }

  // Disconnect WebSocket
  static void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _onMessageReceived = null;
  }

  // Send message via WebSocket
  static void sendMessageViaWebSocket({
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'TEXT',
  }) {
    if (_stompClient == null || !_stompClient!.isActive) {
      print('WebSocket not connected');
      return;
    }

    _stompClient!.send(
      destination: '/app/send',
      body: jsonEncode({
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'messageType': messageType,
      }),
    );
  }

  // REST API: Get conversations
  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final token = await AuthService.getToken();
      
      print('📡 GET ${ApiEndpoints.chatConversations}');
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.chatConversations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Conversations Status: ${response.statusCode}');
      print('📦 Conversations Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        if (responseBody['success'] == true) {
          final List<dynamic> data = responseBody['data'] ?? [];
          print('✅ Found ${data.length} conversations');
          
          final List<Conversation> conversations = 
            data.map((item) => Conversation.fromJson(item as Map<String, dynamic>)).toList();
          
          return {
            'success': true,
            'data': conversations,
            'message': responseBody['message'] ?? 'Success',
          };
        } else {
          return {
            'success': false,
            'data': [],
            'message': responseBody['message'] ?? 'Failed to fetch conversations',
          };
        }
      }
      
      return {
        'success': false,
        'data': [],
        'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      };
    } catch (e) {
      print('💥 Conversations Exception: $e');
      return {
        'success': false,
        'data': [],
        'message': 'Error: $e',
      };
    }
  }

  // REST API: Get messages in a conversation
  static Future<Map<String, dynamic>> getMessages(String conversationId) async {
    try {
      final token = await AuthService.getToken();
      final url = ApiEndpoints.chatMessages(conversationId);
      
      print('📡 GET $url');
      print('🔑 Token: ${token?.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        if (responseBody['success'] == true) {
          final List<dynamic> data = responseBody['data'] ?? [];
          print('✅ Found ${data.length} messages');
          
          final List<Message> messages = 
            data.map((item) => Message.fromJson(item as Map<String, dynamic>)).toList();
          
          return {
            'success': true,
            'data': messages,
            'message': responseBody['message'] ?? 'Success',
          };
        } else {
          print('⚠️ Response success=false: ${responseBody['message']}');
          return {
            'success': false,
            'data': [],
            'message': responseBody['message'] ?? 'Failed to fetch messages',
          };
        }
      }
      
      print('❌ HTTP ${response.statusCode}: ${response.body}');
      return {
        'success': false,
        'data': [],
        'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      };
    } catch (e) {
      print('💥 Exception: $e');
      return {
        'success': false,
        'data': [],
        'message': 'Error: $e',
      };
    }
  }

  // REST API: Send message
  static Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'TEXT',
  }) async {
    try {
      final token = await AuthService.getToken();
      
      print('📤 POST ${ApiEndpoints.chatSend}');
      print('📝 Sending to: $receiverId, content: $content');
      
      final response = await http.post(
        Uri.parse(ApiEndpoints.chatSend),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'content': content,
          'messageType': messageType,
        }),
      );

      print('📊 Send Status: ${response.statusCode}');
      print('📦 Send Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        if (responseBody['success'] == true) {
          final message = Message.fromJson(responseBody['data']);
          print('✅ Message sent: ${message.messageId}');
          
          return {
            'success': true,
            'data': message,
            'message': responseBody['message'] ?? 'Message sent',
          };
        } else {
          return {
            'success': false,
            'data': null,
            'message': responseBody['message'] ?? 'Failed to send message',
          };
        }
      }
      
      return {
        'success': false,
        'data': null,
        'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      };
    } catch (e) {
      print('💥 Send Exception: $e');
      return {
        'success': false,
        'data': null,
        'message': 'Error: $e',
      };
    }
  }

  // REST API: Mark conversation as read
  static Future<Map<String, dynamic>> markAsRead(String conversationId) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.post(
        Uri.parse(ApiEndpoints.chatMarkRead(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        return {
          'success': responseBody['success'] == true,
          'message': responseBody['message'] ?? 'Success',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to mark as read',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // REST API: Start/Get conversation with user
  static Future<Map<String, dynamic>> startConversation(String otherUserId) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.post(
        Uri.parse(ApiEndpoints.chatStartConversation),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'otherUserId': otherUserId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        if (responseBody['success'] == true) {
          final conversation = Conversation.fromJson(responseBody['data']);
          
          return {
            'success': true,
            'data': conversation,
            'message': responseBody['message'] ?? 'Success',
          };
        }
      }
      
      return {
        'success': false,
        'data': null,
        'message': 'Failed to start conversation',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error: $e',
      };
    }
  }

  // Check if connected
  static bool get isConnected => _stompClient?.isActive ?? false;
}
