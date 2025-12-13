class Voucher {
  final String voucherId;
  final String code;
  final String title;
  final String? description;
  final String type; // FIXED_AMOUNT, PERCENTAGE
  final double discountValue;
  final double? minOrderValue;
  final double? maxDiscountAmount;
  final int usageLimit;
  final int usedCount;
  final int? usageLimitPerUser;
  final String validFrom;
  final String validTo;
  final bool firstOrderOnly;
  final String status; // ACTIVE, EXPIRED, INACTIVE

  Voucher({
    required this.voucherId,
    required this.code,
    required this.title,
    this.description,
    required this.type,
    required this.discountValue,
    this.minOrderValue,
    this.maxDiscountAmount,
    required this.usageLimit,
    required this.usedCount,
    this.usageLimitPerUser,
    required this.validFrom,
    required this.validTo,
    required this.firstOrderOnly,
    required this.status,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      voucherId: json['voucherId'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'FIXED_AMOUNT',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderValue: json['minOrderValue'] != null ? (json['minOrderValue'] as num).toDouble() : null,
      maxDiscountAmount: json['maxDiscountAmount'] != null ? (json['maxDiscountAmount'] as num).toDouble() : null,
      usageLimit: json['usageLimit'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      usageLimitPerUser: json['usageLimitPerUser'],
      validFrom: json['validFrom'] ?? '',
      validTo: json['validTo'] ?? '',
      firstOrderOnly: json['firstOrderOnly'] ?? false,
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voucherId': voucherId,
      'code': code,
      'title': title,
      'description': description,
      'type': type,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'maxDiscountAmount': maxDiscountAmount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'usageLimitPerUser': usageLimitPerUser,
      'validFrom': validFrom,
      'validTo': validTo,
      'firstOrderOnly': firstOrderOnly,
      'status': status,
    };
  }

  String getTypeText() {
    switch (type) {
      case 'FIXED_AMOUNT':
        return 'Giảm giá cố định';
      case 'PERCENTAGE':
        return 'Giảm theo %';
      default:
        return type;
    }
  }

  String getStatusText() {
    switch (status) {
      case 'ACTIVE':
        return 'Hoạt động';
      case 'EXPIRED':
        return 'Hết hạn';
      case 'INACTIVE':
        return 'Tạm ngừng';
      default:
        return status;
    }
  }

  String getDiscountText() {
    if (type == 'FIXED_AMOUNT') {
      return '${discountValue.toStringAsFixed(0)}đ';
    } else {
      return '${discountValue.toStringAsFixed(0)}%';
    }
  }
}
