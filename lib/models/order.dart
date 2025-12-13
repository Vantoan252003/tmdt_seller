class Order {
  final String orderId;
  final String userId;
  final String shopId;
  final String orderCode;
  final double totalAmount;
  final double shippingFee;
  final double discountAmount;
  final double finalAmount;
  final String status; // PENDING, CONFIRMED, PROCESSING, SHIPPING, DELIVERED, CANCELLED, RETURNED
  final String paymentMethod;
  final String paymentStatus;
  final String shippingAddress;
  final String recipientName;
  final String recipientPhone;
  final String? note;
  final String? voucherCode;
  final String createdAt;
  final String updatedAt;

  Order({
    required this.orderId,
    required this.userId,
    required this.shopId,
    required this.orderCode,
    required this.totalAmount,
    required this.shippingFee,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.recipientName,
    required this.recipientPhone,
    this.note,
    this.voucherCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      shopId: json['shopId'] ?? '',
      orderCode: json['orderCode'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      shippingAddress: json['shippingAddress'] ?? '',
      recipientName: json['recipientName'] ?? '',
      recipientPhone: json['recipientPhone'] ?? '',
      note: json['note'],
      voucherCode: json['voucherCode'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'shopId': shopId,
      'orderCode': orderCode,
      'totalAmount': totalAmount,
      'shippingFee': shippingFee,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'shippingAddress': shippingAddress,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'note': note,
      'voucherCode': voucherCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String getStatusText() {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PROCESSING':
        return 'Đang xử lý';
      case 'SHIPPING':
        return 'Đang giao';
      case 'DELIVERED':
        return 'Đã giao';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'RETURNED':
        return 'Đã trả';
      default:
        return status;
    }
  }

  String getPaymentStatusText() {
    switch (paymentStatus) {
      case 'UNPAID':
        return 'Chưa thanh toán';
      case 'PAID':
        return 'Đã thanh toán';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return paymentStatus;
    }
  }
}
