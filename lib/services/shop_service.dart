import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop.dart';
import 'api_endpoints.dart';

class ShopService {
  // Get auth token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get shop by ID
  static Future<Map<String, dynamic>> getShopById(String shopId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.shopById(shopId)),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final shop = Shop.fromJson(data['data']);
        return {'success': true, 'data': shop};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể lấy thông tin cửa hàng'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Get my shop (current user's shop)
  static Future<Map<String, dynamic>> getMyShop() async {
    try {
      final token = await _getToken();
      print('Token: $token');
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      print('Calling API: ${ApiEndpoints.myShop}');
      final response = await http.get(
        Uri.parse(ApiEndpoints.myShop),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final shop = Shop.fromJson(data['data']);
        return {'success': true, 'data': shop};
      } else if (response.statusCode == 404) {
        // Shop not found - user doesn't have a shop yet
        return {'success': false, 'message': 'Bạn chưa có cửa hàng', 'hasShop': false};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể lấy thông tin cửa hàng'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Create new shop
  static Future<Map<String, dynamic>> createShop({
    required String shopName,
    String? description,
    String? address,
    String? phoneNumber,
    String? logoUrl,
    String? bannerUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      final body = <String, dynamic>{
        'shopName': shopName,
      };

      if (description != null) body['description'] = description;
      if (address != null) body['address'] = address;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (logoUrl != null) body['logoUrl'] = logoUrl;
      if (bannerUrl != null) body['bannerUrl'] = bannerUrl;

      final response = await http.post(
        Uri.parse(ApiEndpoints.shops),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final shop = Shop.fromJson(data['data']);
        return {'success': true, 'data': shop, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể tạo cửa hàng'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Update shop
  static Future<Map<String, dynamic>> updateShop({
    required String shopId,
    String? shopName,
    String? description,
    String? address,
    String? phoneNumber,
    String? logoUrl,
    String? bannerUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      final body = <String, dynamic>{};

      if (shopName != null) body['shopName'] = shopName;
      if (description != null) body['description'] = description;
      if (address != null) body['address'] = address;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (logoUrl != null) body['logoUrl'] = logoUrl;
      if (bannerUrl != null) body['bannerUrl'] = bannerUrl;

      final response = await http.put(
        Uri.parse(ApiEndpoints.shopById(shopId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final shop = Shop.fromJson(data['data']);
        return {'success': true, 'data': shop, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể cập nhật cửa hàng'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
