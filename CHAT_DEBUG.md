# 🐛 Chat Debug Guide

## Vấn đề: Không thấy tin nhắn hiển thị

### Các bước kiểm tra:

#### 1. Kiểm tra Console Logs

Khi mở màn hình chat, bạn sẽ thấy các logs như sau trong console:

**Khi load conversations:**
```
📡 GET http://192.168.31.96:8080/api/chat/conversations
📊 Conversations Status: 200
📦 Conversations Response: {"success":true,"data":[...]}
✅ Found X conversations
```

**Khi mở chat room:**
```
🔄 Loading messages for conversation: conv-123
📡 GET http://192.168.31.96:8080/api/chat/conversations/conv-123/messages
🔑 Token: eyJhbGciOiJIUzI1NiIs...
📊 Status Code: 200
📦 Response Body: {"success":true,"data":[...]}
✅ Found X messages
✅ Loaded X messages
```

**Khi gửi tin nhắn:**
```
📤 Sending message: Hello
📤 POST http://192.168.31.96:8080/api/chat/send
📝 Sending to: user-456, content: Hello
📊 Send Status: 200
📦 Send Response: {"success":true,"data":{...}}
✅ Message sent: msg-123
```

---

#### 2. Các lỗi thường gặp và cách fix

##### ❌ Error: HTTP 401 Unauthorized
```
📊 Status Code: 401
❌ HTTP 401: Unauthorized
```

**Nguyên nhân:** Token hết hạn hoặc không hợp lệ  
**Cách fix:** Đăng xuất và đăng nhập lại

---

##### ❌ Error: HTTP 403 Forbidden
```
📊 Status Code: 403
❌ HTTP 403: Forbidden
```

**Nguyên nhân:** User không có quyền SELLER  
**Cách fix:** Đảm bảo user đã có shop và role là SELLER

---

##### ❌ Error: HTTP 404 Not Found
```
📊 Status Code: 404
❌ HTTP 404: Not Found
```

**Nguyên nhân:** API endpoint không tồn tại  
**Cách fix:** 
- Kiểm tra backend đã implement đầy đủ các endpoint chưa
- Kiểm tra URL trong `api_endpoints.dart` có đúng không

---

##### ❌ Error: Connection refused
```
💥 Exception: SocketException: Connection refused
```

**Nguyên nhân:** Backend không chạy hoặc sai IP  
**Cách fix:**
- Kiểm tra backend đang chạy tại `http://192.168.31.96:8080`
- Ping thử IP: `ping 192.168.31.96`
- Kiểm tra cùng mạng WiFi

---

##### ⚠️ Response success=false
```
⚠️ Response success=false: Conversation not found
```

**Nguyên nhân:** ConversationId không tồn tại  
**Cách fix:**
- Kiểm tra conversationId có đúng không
- Kiểm tra database có conversation này không

---

#### 3. Kiểm tra Response Format

Response từ API phải đúng format:

**GET /api/chat/conversations/{conversationId}/messages**
```json
{
    "success": true,
    "data": [
        {
            "messageId": "msg-001",
            "conversationId": "conv-123",
            "senderId": "user-456",
            "senderName": "Nguyễn Văn A",
            "senderAvatar": "https://...",
            "receiverId": "seller-789",
            "content": "Hello",
            "messageType": "TEXT",
            "isRead": true,
            "createdAt": "2025-12-13T10:25:00"
        }
    ]
}
```

**Lưu ý:** Các trường bắt buộc:
- `success`: boolean
- `data`: array
- Mỗi message phải có đầy đủ: messageId, conversationId, senderId, senderName, receiverId, content, messageType, isRead, createdAt

---

#### 4. Test với Postman/curl

Test API trực tiếp:

```bash
# Get conversations
curl -X GET http://192.168.31.96:8080/api/chat/conversations \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get messages
curl -X GET http://192.168.31.96:8080/api/chat/conversations/conv-123/messages \
  -H "Authorization: Bearer YOUR_TOKEN"

# Send message
curl -X POST http://192.168.31.96:8080/api/chat/send \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "receiverId": "user-456",
    "content": "Test message",
    "messageType": "TEXT"
  }'
```

---

#### 5. Kiểm tra Database

Truy vấn database để xem dữ liệu:

```sql
-- Check conversations
SELECT * FROM conversations WHERE user1_id = 'seller-id' OR user2_id = 'seller-id';

-- Check messages
SELECT * FROM messages WHERE conversation_id = 'conv-123' ORDER BY created_at;
```

---

## 📱 Run App với Logs

Chạy app và xem logs:

```bash
cd /Users/nguyenvantoan/dev/FLUTTER_PROJECTS/seller_ecommerce
flutter run
```

Trong VS Code, mở Debug Console để xem tất cả logs.

---

## 🔍 Điểm cần kiểm tra

- [ ] Backend đang chạy tại `http://192.168.31.96:8080`
- [ ] User đã đăng nhập với role SELLER
- [ ] Token còn hạn
- [ ] API endpoints đã được implement đầy đủ
- [ ] Response format đúng chuẩn
- [ ] Database có dữ liệu conversations và messages
- [ ] Cùng mạng WiFi với backend

---

## 💡 Tips

1. **Clear app data** nếu gặp lỗi cache:
```bash
flutter clean
flutter pub get
flutter run
```

2. **Hot restart** thay vì hot reload khi thay đổi service:
- Press `R` trong terminal
- Hoặc click nút restart trong VS Code

3. **Check network inspector** trong Flutter DevTools để xem tất cả HTTP requests

4. **Enable verbose logging** trong app settings nếu cần chi tiết hơn
