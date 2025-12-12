import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import '../services/stats_service.dart';
import '../models/shop.dart';
import '../models/seller_stats.dart';
import 'product_management_screen.dart';
import 'add_product_screen.dart';
import 'create_shop_screen.dart';
import 'report_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> with TickerProviderStateMixin {
  Shop? _shop;
  SellerStats? _sellerStats;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalProducts': 0,
    'totalOrders': 0,
    'totalRevenue': 0.0,
    'averageRating': 0.0,
  };

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadData() async {
    print('Loading shop data...');
    final shopResult = await ShopService.getMyShop();
    print('Shop result: $shopResult');
    
    if (shopResult['success'] == true) {
      _shop = shopResult['data'];
      print('Shop loaded: ${_shop?.shopName}');
      
      // Load stats from API
      if (_shop != null) {
        final statsResult = await StatsService.getSellerStats(_shop!.shopId);
        if (statsResult['success'] == true) {
          _sellerStats = statsResult['data'];
          print('Stats loaded successfully');
          
          // Update stats from API data
          setState(() {
            _stats = {
              'totalProducts': _sellerStats!.overview.totalProducts,
              'totalOrders': _sellerStats!.overview.totalOrders,
              'totalRevenue': _sellerStats!.overview.totalRevenue,
              'averageRating': _sellerStats!.overview.averageRating,
            };
          });
        }
      }
    } else {
      print('Failed to load shop: ${shopResult['message']}');
      _shop = null;
    }
    
    setState(() {
      _isLoading = false;
    });
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToCreateShop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateShopScreen()),
    );

    // If shop was created successfully, reload data
    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
              Color(0xFFF093FB),
              Color(0xFFF5576C),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _shop == null
                  ? _buildCreateShopScreen()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: CustomScrollView(
                        slivers: [
                          // Modern Header
                          SliverToBoxAdapter(
                            child: _buildModernHeader(),
                          ),
                          // Stats Section
                          SliverToBoxAdapter(
                            child: _buildStatsSection(),
                          ),
                          // Main Content
                          SliverToBoxAdapter(
                            child: _buildMainContent(),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildCreateShopScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chưa có cửa hàng',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn cần tạo cửa hàng để có thể bắt đầu bán hàng trên nền tảng',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _navigateToCreateShop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF667EEA),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_business, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tạo cửa hàng ngay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _shop?.status == 'ACTIVE' ? Icons.check_circle : Icons.pending,
                      color: _shop?.status == 'ACTIVE' ? Colors.greenAccent : Colors.orangeAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _shop?.getStatusText() ?? 'Chưa có shop',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_shop?.logoUrl != null)
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _shop!.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.store,
                        size: 32,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shop?.shopName ?? 'Cửa hàng của bạn',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                 
                    if (_shop?.address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _shop!.address!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan cửa hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'Sản phẩm',
                  value: '${_stats['totalProducts']}',
                  color: Colors.blue,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Đơn hàng',
                  value: '${_stats['totalOrders']}',
                  color: Colors.orange,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.attach_money_rounded,
                  title: 'Doanh thu',
                  value: '${(_stats['totalRevenue'] as num).toStringAsFixed(0)}đ',
                  color: Colors.green,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.star_rounded,
                  title: 'Đánh giá',
                  value: '${(_stats['averageRating'] as num).toStringAsFixed(1)}',
                  color: Colors.amber,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE259), Color(0xFFFFA751)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý cửa hàng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quản lý sản phẩm và đơn hàng của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                _buildActionGrid(),
                const SizedBox(height: 32),
                _buildRecentActivity(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      {
        'icon': Icons.inventory_2_rounded,
        'title': 'Sản phẩm',
        'subtitle': 'Quản lý sản phẩm',
        'color': const Color(0xFF667EEA),
        'bgColor': const Color(0xFFF7FAFC),
      },
      {
        'icon': Icons.add_circle_rounded,
        'title': 'Thêm sản phẩm',
        'subtitle': 'Thêm sản phẩm mới',
        'color': const Color(0xFF48BB78),
        'bgColor': const Color(0xFFF0FFF4),
      },
      {
        'icon': Icons.shopping_bag_rounded,
        'title': 'Đơn hàng',
        'subtitle': 'Quản lý đơn hàng',
        'color': const Color(0xFFED8936),
        'bgColor': const Color(0xFFFFFAF0),
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Báo cáo',
        'subtitle': 'Thống kê doanh thu',
        'color': const Color(0xFF9F7AEA),
        'bgColor': const Color(0xFFFAF5FF),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          icon: action['icon'] as IconData,
          title: action['title'] as String,
          subtitle: action['subtitle'] as String,
          color: action['color'] as Color,
          bgColor: action['bgColor'] as Color,
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return InkWell(
      onTap: () {
        if (_shop == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đợi tải thông tin shop')),
          );
          return;
        }
        
        if (title == 'Sản phẩm') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductManagementScreen()),
          ).then((_) => _loadData());
        } else if (title == 'Thêm sản phẩm') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(shopId: _shop!.shopId),
            ),
          ).then((_) => _loadData());
        } else if (title == 'Báo cáo') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportScreen(shopId: _shop!.shopId),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentReviews = _sellerStats?.reviewStats.recentReviews ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đánh giá gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            if (recentReviews.isNotEmpty)
              TextButton(
                onPressed: () {
                  if (_shop != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportScreen(shopId: _shop!.shopId),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        recentReviews.isEmpty
            ? _buildEmptyActivityState()
            : Column(
                children: recentReviews.take(3).map((review) => _buildReviewCard(review)).toList(),
              ),
      ],
    );
  }
  
  Widget _buildReviewCard(RecentReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF667EEA).withOpacity(0.1),
                  child: Text(
                    review.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            review.createdAt,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.productName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.timeline_rounded,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có hoạt động nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu thêm sản phẩm để theo dõi hoạt động bán hàng',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_shop == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đợi tải thông tin shop')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(shopId: _shop!.shopId),
                ),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm sản phẩm đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
