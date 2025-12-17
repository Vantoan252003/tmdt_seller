import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/fcm_service.dart';
import '../widgets/message_bubble.dart';
import '../utils/app_theme.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  String? _currentShopId;
  String? _shopLogo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Ngắt FCM khi vào chat room để tránh nhận notification trùng
    await FCMService().deactivateToken();
    
    // Lấy shopId và userId TRƯỚC KHI setup WebSocket
    await _getCurrentUserId();
    
    // Giờ mới setup WebSocket (vì đã có shopId/userId)
    _setupWebSocket();
    
    await _loadMessages();
    await _markAsRead();
  }

  Future<void> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentShopId = prefs.getString('shopId'); // Lấy shopId để so sánh tin nhắn
      _currentUserId = prefs.getString('sellerId'); // Dùng sellerId để subscribe WebSocket
      _shopLogo = prefs.getString('shopLogo'); // Lấy logo shop để hiển thị
    });
    
    print('\n========== USER INFO ==========');
    print('🔑 Current ShopId: $_currentShopId');
    print('🔑 Current SellerId (UserId for WebSocket): $_currentUserId');
    print('🖼️ Shop Logo: $_shopLogo');
    print('===============================\n');
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _messages = await ChatService.getMessages(widget.conversationId);
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _markAsRead() async {
    await ChatService.markAsRead(widget.conversationId);
  }

  void _setupWebSocket() {
    final userId =  _currentUserId;
    
    print('\n========== SETUP WEBSOCKET ==========');
    print('🔍 ShopId: $_currentShopId');
    print('🔍 UserId: $_currentUserId');
    print('🔍 Will use: $userId');
    print('🔌 Already connected: ${ChatService.isConnected}');
    
    if (userId == null) {
      print('❌ Cannot connect WebSocket: shopId and userId are both null');
      print('=====================================\n');
      return;
    }
    
    if (ChatService.isConnected) {
      print('✅ WebSocket already connected');
      print('=====================================\n');
      return;
    }
    
    print('🔌 Calling ChatService.connect() with userId: $userId');
    print('=====================================\n');
    
    ChatService.connect(
      userId,
      (message) {
        print('\n========== MESSAGE CALLBACK ==========');
        print('📨 Received message via callback: ${message.messageId}');
        print('📬 Conversation: ${message.conversationId}');
        print('📬 Expected: ${widget.conversationId}');
        print('📬 Match: ${message.conversationId == widget.conversationId}');
        print('======================================\n');
        
        if (mounted && message.conversationId == widget.conversationId) {
          print('✅ Processing message for UI');
          
          setState(() {
            // Check if this is a replacement for optimistic message
            final optimisticIndex = _messages.indexWhere(
              (msg) => msg.messageId.startsWith('temp-') && 
                      msg.senderId == message.senderId &&
                      msg.content == message.content &&
                      msg.conversationId == message.conversationId
            );
            
            if (optimisticIndex != -1) {
              // Replace optimistic message with real message
              print('🔄 Replacing optimistic message at index $optimisticIndex');
              _messages[optimisticIndex] = message;
            } else {
              // Add new message
              print('➕ Adding new message');
              _messages.add(message);
            }
          });
          
          _scrollToBottom();
          _markAsRead();
        } else {
          print('⏭️ Skipping message (different conversation)');
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    print('\n========== SEND MESSAGE ==========');
    print('📤 Content: $content');
    print('🔌 WebSocket connected: ${ChatService.isConnected}');
    print('🔑 ShopId: $_currentShopId');
    print('🔑 UserId: $_currentUserId');
    
    // Check WebSocket connection
    if (!ChatService.isConnected) {
      print('❌ WebSocket NOT connected!');
      print('==================================\n');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa kết nối WebSocket. Vui lòng thử lại!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final senderId = _currentUserId ?? '';
      print('🔐 Sending as: $senderId');
      print('📬 To: ${widget.otherUserId}');
      print('🚀 Calling sendMessageViaWebSocket()...');
      print('==================================\n');
      
      // Tạo optimistic message để hiển thị ngay
      final optimisticMessage = ChatMessage(
        messageId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: widget.conversationId,
        senderId: senderId,
        senderName: 'Shop', // Tên hiển thị
        senderAvatar: _shopLogo,
        receiverId: widget.otherUserId,
        content: content,
        imageUrl: null,
        messageType: 'TEXT',
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Add optimistic message vào UI ngay lập tức
      setState(() {
        _messages.add(optimisticMessage);
      });
      _scrollToBottom();

      // Clear input ngay lập tức
      _messageController.clear();
      
      // Gửi tin nhắn TEXT qua WebSocket (REALTIME!)
      ChatService.sendMessageViaWebSocket(
        widget.otherUserId,
        content,
        messageType: 'TEXT',
        conversationId: widget.conversationId,
      );
      
      print('✅ Message sent via WebSocket (optimistic UI updated)');
    } catch (e, stackTrace) {
      print('❌ Failed to send message: $e');
      print('❌ Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi tin nhắn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _isSending = true;
        });

        print('📸 Sending image: ${pickedFile.path}');
        final message = await ChatService.sendImageMessage(
          widget.otherUserId,
          File(pickedFile.path),
        );

        if (mounted) {
          setState(() {
            _isSending = false;
          });

          if (message != null) {
            setState(() {
              _messages.add(message);
            });
            _scrollToBottom();
            print('✅ Image sent successfully');
          } else {
            print('❌ Failed to send image');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể gửi ảnh'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    //dispose WebSocket connection
    ChatService.disconnect();
    // Kết nối lại FCM khi ra khỏi chat room
    FCMService().registerToken(
      deviceType: 'android',
      deviceId: 'device_id', // Có thể lấy device ID thực tế nếu cần
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: widget.otherUserAvatar != null && widget.otherUserAvatar!.isNotEmpty
                    ? NetworkImage(widget.otherUserAvatar!)
                    : null,
                child: widget.otherUserAvatar == null || widget.otherUserAvatar!.isEmpty
                    ? Text(
                        widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ChatService.isConnected)
                    const Text(
                      'Đang hoạt động',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    )
                  else
                    const Text(
                      'Mất kết nối',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // More options
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _buildMessagesList(),
          ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải tin nhắn',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final showDateHeader = index == 0 || 
            _shouldShowDateHeader(_messages[index], _messages[index - 1]);
        return Column(
          children: [
            if (showDateHeader)
              _buildDateHeader(_messages[index].createdAt),
            _buildMessageBubble(_messages[index]),
          ],
        );
      },
    );
  }

  bool _shouldShowDateHeader(ChatMessage current, ChatMessage previous) {
    try {
      final currentDate = DateTime.parse(current.createdAt);
      final previousDate = DateTime.parse(previous.createdAt);
      return currentDate.day != previousDate.day ||
             currentDate.month != previousDate.month ||
             currentDate.year != previousDate.year;
    } catch (e) {
      return false;
    }
  }

  Widget _buildDateHeader(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      String displayText;

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        displayText = 'Hôm nay';
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        displayText = 'Hôm qua';
      } else {
        displayText = '${date.day}/${date.month}/${date.year}';
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            displayText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bắt đầu cuộc trò chuyện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gửi tin nhắn đầu tiên của bạn',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // SELLER APP: Check cả shopId và userId
    final isMe = message.senderId == _currentShopId || 
                 message.senderId == _currentUserId;
    
    // Xác định avatar hiển thị: nếu là tin nhắn của shop thì dùng shop logo, không thì dùng user avatar
    final displayAvatar = isMe ? _shopLogo : widget.otherUserAvatar;
    final displayName = isMe ? 'Shop' : widget.otherUserName;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty
                  ? NetworkImage(displayAvatar)
                  : null,
              child: displayAvatar == null || displayAvatar.isEmpty
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Display image for IMAGE messages
                if (message.messageType == 'IMAGE')
                  _buildImageMessage(message, isMe)
                else
                  _buildTextMessage(message, isMe),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message, bool isMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 15,
          color: isMe ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildImageMessage(ChatMessage message, bool isMe) {
    final imageUrl = message.imageUrl ?? message.content;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        child: GestureDetector(
          onTap: () => _showFullScreenImage(imageUrl),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 48,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final time = DateTime.parse(timeStr);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add image button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: _isSending ? null : _pickAndSendImage,
                icon: Icon(
                  Icons.image,
                  color: _isSending ? Colors.grey[400] : Colors.grey[600],
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}