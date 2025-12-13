import 'package:flutter/material.dart';

class Notification {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String referenceId;
  final bool isRead;
  final String createdAt;
  final String? readAt;

  Notification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.referenceId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      notificationId: json['notificationId'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      referenceId: json['referenceId'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
      readAt: json['readAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': createdAt,
      'readAt': readAt,
    };
  }

  String getTypeText() {
    switch (type) {
      case 'NEW_ORDER':
        return 'Đơn hàng mới';
      case 'ORDER_CONFIRMED':
        return 'Đơn hàng được xác nhận';
      case 'ORDER_SHIPPED':
        return 'Đơn hàng đang giao';
      case 'ORDER_DELIVERED':
        return 'Đơn hàng đã giao';
      case 'REVIEW_RECEIVED':
        return 'Đánh giá mới';
      case 'PAYMENT_RECEIVED':
        return 'Thanh toán nhận được';
      default:
        return type;
    }
  }

  IconData getTypeIcon() {
    switch (type) {
      case 'NEW_ORDER':
        return Icons.shopping_bag_outlined;
      case 'ORDER_CONFIRMED':
        return Icons.check_circle_outline;
      case 'ORDER_SHIPPED':
        return Icons.local_shipping_outlined;
      case 'ORDER_DELIVERED':
        return Icons.done_all;
      case 'REVIEW_RECEIVED':
        return Icons.star_outline;
      case 'PAYMENT_RECEIVED':
        return Icons.payment;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color getTypeColor() {
    switch (type) {
      case 'NEW_ORDER':
        return const Color(0xFF667EEA);
      case 'ORDER_CONFIRMED':
        return Colors.green;
      case 'ORDER_SHIPPED':
        return Colors.blue;
      case 'ORDER_DELIVERED':
        return Colors.teal;
      case 'REVIEW_RECEIVED':
        return Colors.amber;
      case 'PAYMENT_RECEIVED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
