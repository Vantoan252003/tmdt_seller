import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messagesCache = {};
  bool _isLoading = false;
  String? _errorMessage;
  int _totalUnreadCount = 0;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUnreadCount => _totalUnreadCount;

  // Get cached messages for a conversation
  List<Message>? getCachedMessages(String conversationId) {
    return _messagesCache[conversationId];
  }

  // Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ChatService.getConversations();

    _isLoading = false;
    if (result['success']) {
      _conversations = result['data'] as List<Conversation>;
      _calculateUnreadCount();
      _errorMessage = null;
    } else {
      _errorMessage = result['message'];
    }
    notifyListeners();
  }

  // Load messages for a conversation
  Future<List<Message>> loadMessages(String conversationId) async {
    final result = await ChatService.getMessages(conversationId);

    if (result['success']) {
      final messages = result['data'] as List<Message>;
      _messagesCache[conversationId] = messages;
      notifyListeners();
      return messages;
    }
    return [];
  }

  // Add new message to cache
  void addMessageToCache(String conversationId, Message message) {
    if (_messagesCache.containsKey(conversationId)) {
      _messagesCache[conversationId]!.add(message);
    } else {
      _messagesCache[conversationId] = [message];
    }
    
    // Update conversation list with new message
    final conversationIndex = _conversations
        .indexWhere((c) => c.conversationId == conversationId);
    
    if (conversationIndex != -1) {
      final updatedConversation = _conversations[conversationIndex].copyWith(
        lastMessage: message.content,
        lastMessageTime: message.createdAt,
      );
      _conversations[conversationIndex] = updatedConversation;
      
      // Move to top
      _conversations.removeAt(conversationIndex);
      _conversations.insert(0, updatedConversation);
    }
    
    notifyListeners();
  }

  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    await ChatService.markAsRead(conversationId);
    
    final conversationIndex = _conversations
        .indexWhere((c) => c.conversationId == conversationId);
    
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex]
          .copyWith(unreadCount: 0);
      _calculateUnreadCount();
      notifyListeners();
    }
  }

  // Calculate total unread count
  void _calculateUnreadCount() {
    _totalUnreadCount = _conversations.fold(
      0,
      (sum, conversation) => sum + conversation.unreadCount,
    );
  }

  // Clear cache for a conversation
  void clearMessagesCache(String conversationId) {
    _messagesCache.remove(conversationId);
    notifyListeners();
  }

  // Clear all cache
  void clearAllCache() {
    _messagesCache.clear();
    _conversations.clear();
    _totalUnreadCount = 0;
    notifyListeners();
  }
}
