import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboard extends StatefulWidget {
  final List<dynamic> transactions;
  final List<dynamic> products;

  const AnalyticsDashboard({
    super.key,
    required this.transactions,
    required this.products,
  });

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  // Helper untuk memformat angka Rupiah
  String formatIDR(dynamic amount) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Perhitungan Data
    final totalSales = widget.transactions.fold<int>(
      0, (sum, item) => sum + (item['total_price'] as int? ?? 0),
    );

    final today = DateTime.now();
    final todaySales = widget.transactions.where((item) {
      final date = DateTime.tryParse(item['tanggal'].toString());
      return date != null && date.year == today.year && date.month == today.month && date.day == today.day;
    }).fold<int>(0, (sum, item) => sum + (item['total_price'] as int? ?? 0));

    final bestSelling = _getBestSellingProduct();
    final chartData = _getLast7DaysData();

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Section: Overview
        Text(
          "Ringkasan Performa",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildSummaryCard(
              title: 'Total Penjualan',
              value: formatIDR(totalSales),
              icon: Icons.payments_outlined,
              color: Colors.teal,
              theme: theme,
            ),
            _buildSummaryCard(
              title: 'Hari Ini',
              value: formatIDR(todaySales),
              icon: Icons.today_outlined,
              color: Colors.blueAccent,
              theme: theme,
            ),
            _buildSummaryCard(
              title: 'Total Produk',
              value: '${widget.products.length}',
              icon: Icons.inventory_2_outlined,
              color: Colors.orange,
              theme: theme,
            ),
            _buildSummaryCard(
              title: 'Total Transaksi',
              value: '${widget.transactions.length}',
              icon: Icons.receipt_long_outlined,
              color: Colors.purpleAccent,
              theme: theme,
            ),
          ],
        ),
        
        const SizedBox(height: 28),

        // Section: Chart
        _buildSectionHeader(theme, "Tren Penjualan (7 Hari Terakhir)", Icons.insights),
        const SizedBox(height: 12),
        _buildChartContainer(theme, isDark, chartData),

        const SizedBox(height: 28),

        // Section: Best Selling
        _buildSectionHeader(theme, "Produk Terlaris", Icons.star_outline_rounded),
        const SizedBox(height: 12),
        _buildBestSellingCard(theme, isDark, bestSelling),
        
        const SizedBox(height: 40), // Spacer bawah
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00BCD4)),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(ThemeData theme, bool isDark, List<FlSpot> data) {
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final days = _getLast7DaysNames();
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox();
                  return Text(
                    value >= 1000000 ? '${(value / 1000000).toStringAsFixed(1)}M' : '${(value / 1000).toInt()}k',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFFE91E63)]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00BCD4).withOpacity(0.2),
                    const Color(0xFF00BCD4).withOpacity(0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellingCard(ThemeData theme, bool isDark, dynamic bestSelling) {
    if (bestSelling == null) return const Center(child: Text("Data tidak tersedia"));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFFE91E63)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bestSelling['product_name'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text("Volume penjualan: ${bestSelling['totalQuantity']} kg", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatIDR(bestSelling['totalRevenue']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00BCD4))),
              const Text("Omset", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  // --- Logic Functions ---

  List<String> _getLast7DaysNames() {
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('EEE').format(date);
    });
  }

  List<FlSpot> _getLast7DaysData() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final sales = widget.transactions.where((tx) {
        final d = DateTime.tryParse(tx['tanggal'].toString());
        return d != null && d.year == date.year && d.month == date.month && d.day == date.day;
      }).fold<int>(0, (sum, item) => sum + (item['total_price'] as int? ?? 0));
      return FlSpot(i.toDouble(), sales.toDouble());
    });
  }

  dynamic _getBestSellingProduct() {
    if (widget.transactions.isEmpty) return null;
    final map = <String, Map<String, dynamic>>{};
    for (var tx in widget.transactions) {
      final name = tx['product_name'] ?? 'Unknown';
      map.update(name, (val) => {
        'product_name': name,
        'totalQuantity': val['totalQuantity'] + (tx['quantity'] ?? 0),
        'totalRevenue': val['totalRevenue'] + (tx['total_price'] ?? 0),
      }, ifAbsent: () => {
        'product_name': name,
        'totalQuantity': tx['quantity'] ?? 0,
        'totalRevenue': tx['total_price'] ?? 0,
      });
    }
    return map.values.reduce((a, b) => a['totalQuantity'] > b['totalQuantity'] ? a : b);
  }
}