import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/seller_stats.dart';
import '../services/stats_service.dart';
import '../utils/app_theme.dart';

class ReportScreen extends StatefulWidget {
  final String shopId;
  
  const ReportScreen({super.key, required this.shopId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  SellerStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load stats
      final statsResult = await StatsService.getSellerStats(widget.shopId);
      if (statsResult['success'] == true) {
        _stats = statsResult['data'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Doanh thu'),
            Tab(text: 'Đơn hàng'),
            Tab(text: 'Sản phẩm'),
            Tab(text: 'Đánh giá'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể tải dữ liệu',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildRevenueTab(),
                      _buildOrderTab(),
                      _buildProductTab(),
                      _buildReviewTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = _stats!.overview;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Revenue Overview Card
        _buildSectionCard(
          title: 'Doanh thu',
          icon: Icons.attach_money,
          color: Colors.green,
          children: [
            _buildStatRow('Tổng doanh thu', '${overview.totalRevenue.toStringAsFixed(0)}đ'),
            _buildStatRow('Doanh thu tháng này', '${overview.monthRevenue.toStringAsFixed(0)}đ'),
          ],
        ),
        const SizedBox(height: 16),

        // Orders Overview Card
        _buildSectionCard(
          title: 'Đơn hàng',
          icon: Icons.shopping_bag,
          color: Colors.orange,
          children: [
            _buildStatRow('Tổng đơn hàng', overview.totalOrders.toString()),
            _buildStatRow('Đơn chờ xử lý', overview.pendingOrders.toString()),
            _buildStatRow('Đơn đang giao', overview.shippingOrders.toString()),
          ],
        ),
        const SizedBox(height: 16),

        // Products Overview Card
        _buildSectionCard(
          title: 'Sản phẩm',
          icon: Icons.inventory_2,
          color: Colors.blue,
          children: [
            _buildStatRow('Tổng sản phẩm', overview.totalProducts.toString()),
            _buildStatRow('Sản phẩm sắp hết', overview.lowStockProducts.toString()),
          ],
        ),
        const SizedBox(height: 16),

        // Reviews Overview Card
        _buildSectionCard(
          title: 'Đánh giá',
          icon: Icons.star,
          color: Colors.amber,
          children: [
            _buildStatRow('Đánh giá trung bình', '${overview.averageRating.toStringAsFixed(1)} ⭐'),
            _buildStatRow('Tổng đánh giá', overview.totalReviews.toString()),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueTab() {
    final revenue = _stats!.revenueStats;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Revenue Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'Hôm nay',
                '${revenue.todayRevenue.toStringAsFixed(0)}đ',
                Icons.today,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                'Tuần này',
                '${revenue.weekRevenue.toStringAsFixed(0)}đ',
                Icons.calendar_view_week,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'Tháng này',
                '${revenue.monthRevenue.toStringAsFixed(0)}đ',
                Icons.calendar_month,
                Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildMiniStatCard(
                'Năm nay',
                '${revenue.yearRevenue.toStringAsFixed(0)}đ',
                Icons.calendar_today,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 30 Days Chart
        _buildSectionCard(
          title: 'Doanh thu 30 ngày gần đây',
          icon: Icons.show_chart,
          color: Colors.blue,
          children: [
            SizedBox(
              height: 250,
              child: revenue.last30Days.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000).toStringAsFixed(0)}K',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 5,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= revenue.last30Days.length) {
                                  return const Text('');
                                }
                                final date = revenue.last30Days[value.toInt()].date;
                                final day = date.split('-').last;
                                return Text(day, style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: revenue.last30Days
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                                .toList(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 12 Months Chart
        _buildSectionCard(
          title: 'Doanh thu 12 tháng gần đây',
          icon: Icons.bar_chart,
          color: Colors.purple,
          children: [
            SizedBox(
              height: 250,
              child: revenue.last12Months.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000).toStringAsFixed(0)}K',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= revenue.last12Months.length) {
                                  return const Text('');
                                }
                                return Text(
                                  'T${revenue.last12Months[value.toInt()].month}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: revenue.last12Months
                            .asMap()
                            .entries
                            .map(
                              (e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.revenue,
                                    color: Colors.purple,
                                    width: 16,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderTab() {
    final orderStats = _stats!.orderStats;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Thống kê đơn hàng',
          icon: Icons.shopping_cart,
          color: Colors.orange,
          children: [
            _buildStatRow('Tổng đơn hàng', orderStats.totalOrders.toString()),
            _buildStatRow('Chờ xác nhận', orderStats.pendingOrders.toString()),
            _buildStatRow('Đã xác nhận', orderStats.confirmedOrders.toString()),
            _buildStatRow('Đang xử lý', orderStats.processingOrders.toString()),
            _buildStatRow('Đang giao hàng', orderStats.shippingOrders.toString()),
            _buildStatRow('Đã giao', orderStats.deliveredOrders.toString()),
            _buildStatRow('Đã hủy', orderStats.cancelledOrders.toString()),
            _buildStatRow('Đã trả hàng', orderStats.returnedOrders.toString()),
          ],
        ),
        const SizedBox(height: 16),

        // Order Status Distribution
        _buildSectionCard(
          title: 'Phân bố trạng thái',
          icon: Icons.pie_chart,
          color: Colors.blue,
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _getOrderPieChartSections(orderStats),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._getOrderLegends(orderStats),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _getOrderPieChartSections(OrderStats stats) {
    final total = stats.totalOrders;
    if (total == 0) return [];

    return [
      if (stats.pendingOrders > 0)
        PieChartSectionData(
          value: stats.pendingOrders.toDouble(),
          title: '${((stats.pendingOrders / total) * 100).toStringAsFixed(0)}%',
          color: Colors.orange,
          radius: 60,
        ),
      if (stats.confirmedOrders > 0)
        PieChartSectionData(
          value: stats.confirmedOrders.toDouble(),
          title: '${((stats.confirmedOrders / total) * 100).toStringAsFixed(0)}%',
          color: Colors.blue,
          radius: 60,
        ),
      if (stats.shippingOrders > 0)
        PieChartSectionData(
          value: stats.shippingOrders.toDouble(),
          title: '${((stats.shippingOrders / total) * 100).toStringAsFixed(0)}%',
          color: Colors.purple,
          radius: 60,
        ),
      if (stats.deliveredOrders > 0)
        PieChartSectionData(
          value: stats.deliveredOrders.toDouble(),
          title: '${((stats.deliveredOrders / total) * 100).toStringAsFixed(0)}%',
          color: Colors.green,
          radius: 60,
        ),
      if (stats.cancelledOrders > 0)
        PieChartSectionData(
          value: stats.cancelledOrders.toDouble(),
          title: '${((stats.cancelledOrders / total) * 100).toStringAsFixed(0)}%',
          color: Colors.red,
          radius: 60,
        ),
    ];
  }

  List<Widget> _getOrderLegends(OrderStats stats) {
    return [
      if (stats.pendingOrders > 0) _buildLegendItem('Chờ xác nhận', Colors.orange, stats.pendingOrders),
      if (stats.confirmedOrders > 0) _buildLegendItem('Đã xác nhận', Colors.blue, stats.confirmedOrders),
      if (stats.shippingOrders > 0) _buildLegendItem('Đang giao', Colors.purple, stats.shippingOrders),
      if (stats.deliveredOrders > 0) _buildLegendItem('Đã giao', Colors.green, stats.deliveredOrders),
      if (stats.cancelledOrders > 0) _buildLegendItem('Đã hủy', Colors.red, stats.cancelledOrders),
    ];
  }

  Widget _buildProductTab() {
    final productStats = _stats!.productStats;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Product Summary
        _buildSectionCard(
          title: 'Tổng quan sản phẩm',
          icon: Icons.inventory,
          color: Colors.blue,
          children: [
            _buildStatRow('Tổng sản phẩm', productStats.totalProducts.toString()),
            _buildStatRow('Đang hoạt động', productStats.activeProducts.toString()),
            _buildStatRow('Ngừng bán', productStats.inactiveProducts.toString()),
            _buildStatRow('Hết hàng', productStats.outOfStockProducts.toString()),
            _buildStatRow('Sắp hết hàng', productStats.lowStockProducts.toString()),
          ],
        ),
        const SizedBox(height: 16),

        // Top Selling Products
        _buildSectionCard(
          title: 'Sản phẩm bán chạy',
          icon: Icons.trending_up,
          color: Colors.green,
          children: productStats.topSellingProducts.isEmpty
              ? [const Center(child: Text('Chưa có dữ liệu'))]
              : productStats.topSellingProducts
                  .map((product) => _buildProductItem(product, true))
                  .toList(),
        ),
        const SizedBox(height: 16),

        // Top Revenue Products
        _buildSectionCard(
          title: 'Sản phẩm doanh thu cao',
          icon: Icons.attach_money,
          color: Colors.amber,
          children: productStats.topRevenueProducts.isEmpty
              ? [const Center(child: Text('Chưa có dữ liệu'))]
              : productStats.topRevenueProducts
                  .map((product) => _buildProductItem(product, false))
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildReviewTab() {
    final reviewStats = _stats!.reviewStats;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Review Summary
        _buildSectionCard(
          title: 'Tổng quan đánh giá',
          icon: Icons.star,
          color: Colors.amber,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    reviewStats.averageRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < reviewStats.averageRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${reviewStats.totalReviews} đánh giá',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildRatingBar('5 sao', reviewStats.fiveStarCount, reviewStats.totalReviews),
            _buildRatingBar('4 sao', reviewStats.fourStarCount, reviewStats.totalReviews),
            _buildRatingBar('3 sao', reviewStats.threeStarCount, reviewStats.totalReviews),
            _buildRatingBar('2 sao', reviewStats.twoStarCount, reviewStats.totalReviews),
            _buildRatingBar('1 sao', reviewStats.oneStarCount, reviewStats.totalReviews),
          ],
        ),
        const SizedBox(height: 16),

        // Recent Reviews
        _buildSectionCard(
          title: 'Đánh giá gần đây',
          icon: Icons.rate_review,
          color: Colors.blue,
          children: reviewStats.recentReviews.isEmpty
              ? [const Center(child: Text('Chưa có đánh giá nào'))]
              : reviewStats.recentReviews.map((review) => _buildReviewItem(review)).toList(),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(TopProduct product, bool showSold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  showSold ? 'Đã bán: ${product.soldQuantity}' : 'Doanh thu: ${product.revenue.toStringAsFixed(0)}đ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Tồn kho: ${product.stockQuantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(RecentReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review.productName,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            review.createdAt,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('$label ($value)', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
