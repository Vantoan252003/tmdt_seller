import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import 'api_endpoints.dart';

class OrderService {
  // Get auth token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get orders by shop
  static Future<Map<String, dynamic>> getOrdersByShop(String shopId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.ordersByShop(shopId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> ordersJson = data['data'] ?? [];
        final List<Order> orders = 
          ordersJson.map((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
        return {'success': true, 'data': orders};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể lấy danh sách đơn hàng'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.orderDetail(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📋 Order Detail Response Status: ${response.statusCode}');
      print('📋 Order Detail Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        try {
          final order = Order.fromJson(data['data']);
          print('✅ Order detail parsed successfully');
          return {'success': true, 'data': order};
        } catch (e) {
          print('❌ Error parsing order detail: $e');
          print('📋 Order data: ${data['data']}');
          return {'success': false, 'message': 'Lỗi phân tích dữ liệu: $e'};
        }
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể lấy thông tin đơn hàng'};
      }
    } catch (e) {
      print('❌ Exception in getOrderById: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      final response = await http.put(
        Uri.parse(ApiEndpoints.updateOrderStatus(orderId, status)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Cập nhật trạng thái thành công', 'data': Order.fromJson(data['data'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Cập nhật trạng thái thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Cancel order
  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      final response = await http.put(
        Uri.parse(ApiEndpoints.cancelOrder(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Hủy đơn hàng thành công'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Hủy đơn hàng thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
