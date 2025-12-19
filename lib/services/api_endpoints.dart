class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'http://192.168.31.23:8080/api';
  
  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refresh';
  
  // Product endpoints
  static const String products = '$baseUrl/products';
  static String productDetail(String id) => '$baseUrl/products/$id';
  static String productsByCategory(String categoryId) => '$baseUrl/products/category/$categoryId';
  static String productsByShop(String shopId) => '$baseUrl/products/shop/$shopId';
  static String searchProducts = '$baseUrl/products/search';
  
  // Category endpoints
  static const String categories = '$baseUrl/categories';
  static String categoryDetail(String id) => '$baseUrl/categories/$id';
  
  // Cart endpoints
  static const String cart = '$baseUrl/cart';
  static String addToCart = '$baseUrl/cart/add';
  static String updateCartItem(String cartItemId) => '$baseUrl/cart/items/$cartItemId';
  static String removeFromCart(String cartItemId) => '$baseUrl/cart/items/$cartItemId';
  static const String clearCart = '$baseUrl/cart/clear';
  
  // Order endpoints
  static const String orders = '$baseUrl/orders';
  static String orderDetail(String id) => '$baseUrl/orders/$id';
  static const String createOrder = '$baseUrl/orders/create';
  static String cancelOrder(String id) => '$baseUrl/orders/$id/cancel';
  static String ordersByShop(String shopId) => '$baseUrl/orders/shop/$shopId';
  static String updateOrderStatus(String orderId, String status) => '$baseUrl/orders/$orderId/status?status=$status';
  
  // User endpoints
  static const String profile = '$baseUrl/user/profile';
  static const String updateProfile = '$baseUrl/user/profile';
  static const String changePassword = '$baseUrl/user/password/change';
  
  // Wishlist endpoints
  static const String wishlist = '$baseUrl/wishlist';
  static String addToWishlist = '$baseUrl/wishlist/add';
  static String removeFromWishlist(String productId) => '$baseUrl/wishlist/remove/$productId';
  
  // Review endpoints
  static String productReviews(String productId) => '$baseUrl/products/$productId/reviews';
  static const String createReview = '$baseUrl/reviews/create';

  // Address endpoints
  static const String addresses = '$baseUrl/addresses';
  static String addressById(String id) => '$baseUrl/addresses/$id';
  static String setDefaultAddress(String id) => '$baseUrl/addresses/$id/default';
  static String shopAddress(String shopId) => '$baseUrl/addresses/shop/$shopId';

  // Location endpoints
  static const String cities = '$baseUrl/locations/cities';
  static String districtsByCity(String city) => '$baseUrl/locations/cities/$city/districts';

  // Payment endpoints
  static const String paymentMethods = '$baseUrl/payment/methods';
  static const String processPayment = '$baseUrl/payment/process';

  // FCM Token endpoints
  static const String registerFcmToken = '$baseUrl/fcm-tokens/register';
  static const String deactivateFcmToken = '$baseUrl/fcm-tokens/deactivate';

  // Shop endpoints
  static const String shops = '$baseUrl/shops';
  static const String myShop = '$baseUrl/shops/my-shop';
  static String shopById(String id) => '$baseUrl/shops/$id';
  static const String uploadShopLogo = '$baseUrl/shops/upload-logo';
  static const String uploadShopBanner = '$baseUrl/shops/upload-banner';

  // Seller Stats endpoints
  static String sellerStats(String shopId) => '$baseUrl/seller/stats/$shopId';

  // Voucher endpoints
  static const String createShopVoucher = '$baseUrl/vouchers/shop/create';
  static const String myShopVouchers = '$baseUrl/vouchers/shop/my-vouchers';
  static String shopVouchers(String shopId) => '$baseUrl/vouchers/shop/$shopId';

  // Notification endpoints
  static const String notifications = '$baseUrl/notifications';
  static const String unreadCount = '$baseUrl/notifications/unread-count';
  static String markNotificationRead(String notificationId) => '$baseUrl/notifications/$notificationId/read';
  static const String markAllRead = '$baseUrl/notifications/mark-all-read';
  static String deleteNotification(String notificationId) => '$baseUrl/notifications/$notificationId';

  // Chat endpoints
  static const String chatConversations = '$baseUrl/chat/seller/conversations';
  static String chatMessages(String conversationId) => '$baseUrl/chat/conversations/$conversationId/messages';
  static const String chatSend = '$baseUrl/chat/send';
  static String chatMarkRead(String conversationId) => '$baseUrl/chat/conversations/$conversationId/mark-read';
  static const String chatStartConversation = '$baseUrl/chat/conversations/start';
  
  // WebSocket endpoint
  static const String chatWebSocket = 'http://192.168.31.23:8080/ws';
  
  // Chat image endpoint
  static const String chatSendImage = '$baseUrl/chat/send-image';
}
