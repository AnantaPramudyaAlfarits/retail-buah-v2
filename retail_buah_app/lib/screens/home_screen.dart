import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/theme_toggle_button.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final Function(dynamic)? onAddToCart;
  final String searchQuery;
  const HomeScreen({
    super.key, 
    required this.role, 
    this.onAddToCart,
    this.searchQuery = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dio = Dio();
  List<dynamic> products = [];
  bool _isLoading = true;

String get baseUrl => 'https://retail-buah-v2-7mu3ahd3h-anantapramudyaalfarits-projects.vercel.app/api';
String get storageUrl => 'https://retail-buah-v2-7mu3ahd3h-anantapramudyaalfarits-projects.vercel.app/uploads';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  List<dynamic> _filteredProducts() {
    if (widget.searchQuery.isEmpty) {
      return products;
    }
    return products.where((product) {
      final productName = (product['nama'] ?? '').toString().toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return productName.contains(query);
    }).toList();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await dio.get('$baseUrl/products');
      setState(() {
        products = response.data ?? [];
        _isLoading = false;
        _showLowStockNotification();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal memuat produk');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _generateQRCode(String productId, String productName) {
    return 'PROD_${productId}_$productName';
  }

  void _showQuantityDialog(dynamic product) {
    int quantity = 1;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text(
                'Berapa ${product['nama']}?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Stok tersedia: ${product['stok']} kg',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                        ),
                        Text(
                          '$quantity',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF00BCD4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: quantity < (product['stok'] ?? 0)
                              ? () => setState(() => quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    product['quantity'] = quantity;
                    widget.onAddToCart?.call(product);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                  ),
                  child: const Text('Tambah', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQRCodeWidget(String qrData) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white, 
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 70,
        gapless: false,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
        errorStateBuilder: (ctx, err) {
          return const Icon(Icons.error, size: 20, color: Colors.red);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Retail Buah',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black87),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchProducts();
            },
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            )
          : products.isEmpty || _filteredProducts().isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        products.isEmpty ? 'Tidak ada produk' : 'Hasil pencarian tidak ditemukan',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchProducts,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Container(
                          color: const Color(0xFF00BCD4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            children: [
                              _buildHeaderText('No', width: 40),
                              _buildHeaderText('Gambar', width: 70),
                              Expanded(child: _buildHeaderText('Nama Produk', textAlign: TextAlign.left)),
                              _buildHeaderText('Stok (kg)', width: 70),
                              _buildHeaderText('QR Code', width: 80),
                              if (widget.role == 'staff') _buildHeaderText('Aksi', width: 70),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredProducts().length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts()[index];
                            final rowColor = index % 2 == 0 
                                ? (isDark ? Colors.grey[900] : Colors.grey[50])
                                : (isDark ? theme.scaffoldBackgroundColor : Colors.white);

                            return Container(
                              color: rowColor,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(
                                            product: product,
                                            storageUrl: storageUrl,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                      child: Row(
                                        children: [
                                          _buildCellText('${index + 1}', width: 40),
                                          _buildImageCell(product['image_url']),
                                          Expanded(child: _buildCellText(product['nama'] ?? '-', textAlign: TextAlign.left, isBold: true)),
                                          _buildCellText('${product['stok'] ?? 0}', width: 70, color: const Color(0xFF00BCD4)),
                                          _buildQRCell(product),
                                          if (widget.role == 'staff') _buildActionCell(product),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Divider(height: 1, color: theme.dividerColor, indent: 8, endIndent: 8),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderText(String text, {double? width, TextAlign textAlign = TextAlign.center}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: textAlign,
      ),
    );
  }

  Widget _buildCellText(String text, {double? width, TextAlign textAlign = TextAlign.center, Color? color, bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
          color: color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
        ),
        textAlign: textAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // PERBAIKAN DI SINI: Mendukung URL image_url (sudah full URL)
  Widget _buildImageCell(String? imageUrl) {
    return SizedBox(
      width: 70,
      child: Center(
        child: Container(
          width: 55, height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[300],
          ),
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 28),
                )
              : const Icon(Icons.image, color: Colors.grey, size: 28),
        ),
      ),
    );
  }

  Widget _buildQRCell(dynamic product) {
    final qrData = _generateQRCode(product['id'] ?? '', product['nama'] ?? 'Produk');
    return SizedBox(
      width: 80,
      child: Tooltip(
        message: qrData,
        child: _buildQRCodeWidget(qrData),
      ),
    );
  }

  Widget _buildActionCell(dynamic product) {
    return SizedBox(
      width: 70,
      child: Center(
        child: ElevatedButton(
          onPressed: () => _showQuantityDialog(product),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCD4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Beli', style: TextStyle(fontSize: 11)),
        ),
      ),
    );
  }

  void _showLowStockNotification() {
    final lowStockProducts = products.where((p) => (p['stok'] ?? 0) < 5).toList();
    if (lowStockProducts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ Peringatan Stok Menipis', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Produk berikut stoknya menipis (<5kg):\n' +
                      lowStockProducts.map((p) => '• ${p['nama']} (${p['stok']}kg)').join('\n'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }
}