import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/seller_stats.dart';
import 'api_endpoints.dart';
import 'auth_service.dart';

class StatsService {
  static Future<Map<String, dynamic>> getSellerStats(String shopId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/seller/stats/$shopId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': SellerStats.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lấy thống kê thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }
}
