import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification.dart';
import 'api_endpoints.dart';
import 'auth_service.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.notifications),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        if (responseBody['status'] == 'success') {
          final List<dynamic> data = responseBody['data'] ?? [];
          final List<Notification> notifications = 
            data.map((item) => Notification.fromJson(item as Map<String, dynamic>)).toList();
          
          return {
            'success': true,
            'data': notifications,
            'message': responseBody['message'] ?? 'Success',
          };
        }
      }
      
      return {
        'success': false,
        'data': [],
        'message': 'Failed to fetch notifications',
      };
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.unreadCount),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        if (responseBody['status'] == 'success') {
          return {
            'success': true,
            'data': responseBody['data'] ?? 0,
            'message': responseBody['message'] ?? 'Success',
          };
        }
      }
      
      return {
        'success': false,
        'data': 0,
        'message': 'Failed to fetch unread count',
      };
    } catch (e) {
      return {
        'success': false,
        'data': 0,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.put(
        Uri.parse(ApiEndpoints.markNotificationRead(notificationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        return {
          'success': responseBody['status'] == 'success',
          'message': responseBody['message'] ?? 'Success',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to mark notification as read',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.put(
        Uri.parse(ApiEndpoints.markAllRead),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        return {
          'success': responseBody['status'] == 'success',
          'message': responseBody['message'] ?? 'Success',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to mark all notifications as read',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.delete(
        Uri.parse(ApiEndpoints.deleteNotification(notificationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        return {
          'success': responseBody['status'] == 'success',
          'message': responseBody['message'] ?? 'Success',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to delete notification',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
