class SellerStats {
  final Overview overview;
  final OrderStats orderStats;
  final RevenueStats revenueStats;
  final ProductStats productStats;
  final ReviewStats reviewStats;

  SellerStats({
    required this.overview,
    required this.orderStats,
    required this.revenueStats,
    required this.productStats,
    required this.reviewStats,
  });

  factory SellerStats.fromJson(Map<String, dynamic> json) {
    return SellerStats(
      overview: Overview.fromJson(json['overview']),
      orderStats: OrderStats.fromJson(json['orderStats']),
      revenueStats: RevenueStats.fromJson(json['revenueStats']),
      productStats: ProductStats.fromJson(json['productStats']),
      reviewStats: ReviewStats.fromJson(json['reviewStats']),
    );
  }
}

class Overview {
  final int totalOrders;
  final int pendingOrders;
  final int shippingOrders;
  final double totalRevenue;
  final double monthRevenue;
  final int totalProducts;
  final int lowStockProducts;
  final double averageRating;
  final int totalReviews;

  Overview({
    required this.totalOrders,
    required this.pendingOrders,
    required this.shippingOrders,
    required this.totalRevenue,
    required this.monthRevenue,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.averageRating,
    required this.totalReviews,
  });

  factory Overview.fromJson(Map<String, dynamic> json) {
    return Overview(
      totalOrders: json['totalOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      shippingOrders: json['shippingOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      monthRevenue: (json['monthRevenue'] ?? 0).toDouble(),
      totalProducts: json['totalProducts'] ?? 0,
      lowStockProducts: json['lowStockProducts'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }
}

class OrderStats {
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int processingOrders;
  final int shippingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int returnedOrders;
  final Map<String, int> ordersByStatus;

  OrderStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.processingOrders,
    required this.shippingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.returnedOrders,
    required this.ordersByStatus,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      totalOrders: json['totalOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      confirmedOrders: json['confirmedOrders'] ?? 0,
      processingOrders: json['processingOrders'] ?? 0,
      shippingOrders: json['shippingOrders'] ?? 0,
      deliveredOrders: json['deliveredOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      returnedOrders: json['returnedOrders'] ?? 0,
      ordersByStatus: Map<String, int>.from(json['ordersByStatus'] ?? {}),
    );
  }
}

class RevenueStats {
  final double totalRevenue;
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final double yearRevenue;
  final List<DailyRevenue> last30Days;
  final List<MonthlyRevenue> last12Months;

  RevenueStats({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.yearRevenue,
    required this.last30Days,
    required this.last12Months,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      weekRevenue: (json['weekRevenue'] ?? 0).toDouble(),
      monthRevenue: (json['monthRevenue'] ?? 0).toDouble(),
      yearRevenue: (json['yearRevenue'] ?? 0).toDouble(),
      last30Days: (json['last30Days'] as List?)
              ?.map((e) => DailyRevenue.fromJson(e))
              .toList() ??
          [],
      last12Months: (json['last12Months'] as List?)
              ?.map((e) => MonthlyRevenue.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DailyRevenue {
  final String date;
  final double revenue;
  final int orderCount;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: json['date'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orderCount: json['orderCount'] ?? 0,
    );
  }
}

class MonthlyRevenue {
  final int year;
  final int month;
  final double revenue;
  final int orderCount;

  MonthlyRevenue({
    required this.year,
    required this.month,
    required this.revenue,
    required this.orderCount,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      orderCount: json['orderCount'] ?? 0,
    );
  }

  String get monthName {
    const months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return months[month - 1];
  }
}

class ProductStats {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int outOfStockProducts;
  final int lowStockProducts;
  final List<TopProduct> topSellingProducts;
  final List<TopProduct> topRevenueProducts;

  ProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.outOfStockProducts,
    required this.lowStockProducts,
    required this.topSellingProducts,
    required this.topRevenueProducts,
  });

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      inactiveProducts: json['inactiveProducts'] ?? 0,
      outOfStockProducts: json['outOfStockProducts'] ?? 0,
      lowStockProducts: json['lowStockProducts'] ?? 0,
      topSellingProducts: (json['topSellingProducts'] as List?)
              ?.map((e) => TopProduct.fromJson(e))
              .toList() ??
          [],
      topRevenueProducts: (json['topRevenueProducts'] as List?)
              ?.map((e) => TopProduct.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TopProduct {
  final String productId;
  final String productName;
  final String imageUrl;
  final int soldQuantity;
  final double revenue;
  final int stockQuantity;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.soldQuantity,
    required this.revenue,
    required this.stockQuantity,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      soldQuantity: json['soldQuantity'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
    );
  }
}

class ReviewStats {
  final int totalReviews;
  final double averageRating;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final Map<String, int> ratingDistribution;
  final List<RecentReview> recentReviews;

  ReviewStats({
    required this.totalReviews,
    required this.averageRating,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    required this.ratingDistribution,
    required this.recentReviews,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      totalReviews: json['totalReviews'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      fiveStarCount: json['fiveStarCount'] ?? 0,
      fourStarCount: json['fourStarCount'] ?? 0,
      threeStarCount: json['threeStarCount'] ?? 0,
      twoStarCount: json['twoStarCount'] ?? 0,
      oneStarCount: json['oneStarCount'] ?? 0,
      ratingDistribution: Map<String, int>.from(json['ratingDistribution'] ?? {}),
      recentReviews: (json['recentReviews'] as List?)
              ?.map((e) => RecentReview.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RecentReview {
  final String reviewId;
  final String userName;
  final String productName;
  final int rating;
  final String comment;
  final String createdAt;

  RecentReview({
    required this.reviewId,
    required this.userName,
    required this.productName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory RecentReview.fromJson(Map<String, dynamic> json) {
    return RecentReview(
      reviewId: json['reviewId'] ?? '',
      userName: json['userName'] ?? '',
      productName: json['productName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
