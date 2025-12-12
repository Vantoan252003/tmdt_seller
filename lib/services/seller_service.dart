import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../services/auth_service.dart';
import 'api_endpoints.dart';

class SellerService {
  // Get seller's products
  static Future<List<Product>> getSellerProducts({String? shopId}) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // If shopId is provided, use it; otherwise get from user's shop
      String finalShopId = shopId ?? '';
      if (finalShopId.isEmpty) {
        final user = await AuthService.getUserData();
        if (user == null) {
          throw Exception('User not found');
        }
        finalShopId = user.id; // Fallback to user.id for backward compatibility
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.productsByShop(finalShopId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> productsJson = data['data'];
          return productsJson.map((json) => Product.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading seller products: $e');
      return [];
    }
  }

  // Create new product
  static Future<Map<String, dynamic>> createProduct({
    required String shopId,
    required String categoryId,
    required String productName,
    required String description,
    required double price,
    required int stockQuantity,
    double discountPercentage = 0.0,
    double weight = 0.0,
    String status = 'ACTIVE',
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.products),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'shopId': shopId,
          'categoryId': categoryId,
          'productName': productName,
          'description': description,
          'price': price,
          'stockQuantity': stockQuantity,
          'discountPercentage': discountPercentage,
          'weight': weight,
          'status': status,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Thêm sản phẩm thành công', 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Thêm sản phẩm thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Update product
  static Future<Map<String, dynamic>> updateProduct({
    required String shopId,
    required String productId,
    required String categoryId,
    required String productName,
    required String description,
    required double price,
    required int stockQuantity,
    double discountPercentage = 0.0,
    double weight = 0.0,
    String status = 'ACTIVE',
    String? mainImageUrl,
    String? imageUrl1,
    String? imageUrl2,
    String? imageUrl3,
    String? imageUrl4,
  }) async {
    try {
      final token = await AuthService.getToken();
      final user = await AuthService.getUserData();
      
      if (token == null || user == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      final Map<String, dynamic> requestBody = {
        'shopId': shopId, // Use shopId from parameter
        'categoryId': categoryId,
        'productName': productName,
        'description': description,
        'price': price,
        'stockQuantity': stockQuantity,
        'discountPercentage': discountPercentage,
        'weight': weight,
        'status': status,
      };

      // Add image URLs if provided
      if (mainImageUrl != null) requestBody['mainImageUrl'] = mainImageUrl;
      if (imageUrl1 != null) requestBody['imageUrl1'] = imageUrl1;
      if (imageUrl2 != null) requestBody['imageUrl2'] = imageUrl2;
      if (imageUrl3 != null) requestBody['imageUrl3'] = imageUrl3;
      if (imageUrl4 != null) requestBody['imageUrl4'] = imageUrl4;

      final response = await http.put(
        Uri.parse('${ApiEndpoints.products}/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Cập nhật sản phẩm thành công', 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Cập nhật sản phẩm thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Delete product
  static Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      final response = await http.delete(
        Uri.parse('${ApiEndpoints.products}/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Xóa sản phẩm thành công'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Xóa sản phẩm thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Upload product images
  static Future<Map<String, dynamic>> uploadProductImages({
    required String productId,
    File? mainImage,
    File? image1,
    File? image2,
    File? image3,
    File? image4,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndpoints.products}/$productId/images'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add images to request
      if (mainImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('mainImage', mainImage.path),
        );
      }
      if (image1 != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image1', image1.path),
        );
      }
      if (image2 != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image2', image2.path),
        );
      }
      if (image3 != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image3', image3.path),
        );
      }
      if (image4 != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image4', image4.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': 'Upload ảnh thành công', 'data': data};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Upload ảnh thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Get seller statistics
  static Future<Map<String, dynamic>> getSellerStats() async {
    try {
      final token = await AuthService.getToken();
      final user = await AuthService.getUserData();
      
      if (token == null || user == null) {
        return {
          'totalProducts': 0,
          'totalOrders': 0,
          'totalRevenue': 0.0,
          'averageRating': 0.0,
        };
      }

      // TODO: Implement API call to get seller statistics
      // For now, return mock data
      return {
        'totalProducts': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'averageRating': 0.0,
      };
    } catch (e) {
      print('Error loading seller stats: $e');
      return {
        'totalProducts': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'averageRating': 0.0,
      };
    }
  }
}
