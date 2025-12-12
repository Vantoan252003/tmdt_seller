class Shop {
  final String shopId;
  final String sellerId;
  final String shopName;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? logoUrl;
  final String? bannerUrl;
  final String status; // PENDING, ACTIVE, SUSPENDED
  final double rating;
  final int totalProducts;
  final int totalOrders;
  final String createdAt;
  final String updatedAt;

  Shop({
    required this.shopId,
    required this.sellerId,
    required this.shopName,
    this.description,
    this.address,
    this.phoneNumber,
    this.logoUrl,
    this.bannerUrl,
    required this.status,
    required this.rating,
    required this.totalProducts,
    required this.totalOrders,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      shopId: json['shopId'] ?? '',
      sellerId: json['sellerId'] ?? '',
      shopName: json['shopName'] ?? '',
      description: json['description'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      logoUrl: json['logoUrl'],
      bannerUrl: json['bannerUrl'],
      status: json['status'] ?? 'PENDING',
      rating: (json['rating'] ?? 0).toDouble(),
      totalProducts: json['totalProducts'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'sellerId': sellerId,
      'shopName': shopName,
      'description': description,
      'address': address,
      'phoneNumber': phoneNumber,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'status': status,
      'rating': rating,
      'totalProducts': totalProducts,
      'totalOrders': totalOrders,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String getStatusText() {
    switch (status) {
      case 'PENDING':
        return 'Chờ duyệt';
      case 'ACTIVE':
        return 'Hoạt động';
      case 'SUSPENDED':
        return 'Tạm ngừng';
      default:
        return status;
    }
  }
}
