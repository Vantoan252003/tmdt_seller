import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voucher.dart';
import 'api_endpoints.dart';

class VoucherService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Create voucher
  static Future<Map<String, dynamic>> createVoucher({
    required String code,
    required String title,
    String? description,
    required String type,
    required double discountValue,
    double? minOrderValue,
    double? maxDiscountAmount,
    required int usageLimit,
    int? usageLimitPerUser,
    required String validFrom,
    required String validTo,
    bool firstOrderOnly = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      final body = {
        'code': code,
        'title': title,
        'type': type,
        'discountValue': discountValue,
        'usageLimit': usageLimit,
        'validFrom': validFrom,
        'validTo': validTo,
        'firstOrderOnly': firstOrderOnly,
      };

      if (description != null) body['description'] = description;
      if (minOrderValue != null) body['minOrderValue'] = minOrderValue;
      if (maxDiscountAmount != null) body['maxDiscountAmount'] = maxDiscountAmount;
      if (usageLimitPerUser != null) body['usageLimitPerUser'] = usageLimitPerUser;

      final response = await http.post(
        Uri.parse(ApiEndpoints.createShopVoucher),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final voucher = Voucher.fromJson(data['data']);
        return {'success': true, 'data': voucher, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể tạo voucher'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Get my shop vouchers
  static Future<Map<String, dynamic>> getMyVouchers() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.myShopVouchers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<Voucher> vouchers = (data['data'] as List)
            .map((json) => Voucher.fromJson(json))
            .toList();
        return {'success': true, 'data': vouchers};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể lấy danh sách voucher'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Get shop vouchers by ID (public)
  static Future<Map<String, dynamic>> getShopVouchers(String shopId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.shopVouchers(shopId)),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<Voucher> vouchers = (data['data'] as List)
            .map((json) => Voucher.fromJson(json))
            .toList();
        return {'success': true, 'data': vouchers};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể lấy danh sách voucher'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
