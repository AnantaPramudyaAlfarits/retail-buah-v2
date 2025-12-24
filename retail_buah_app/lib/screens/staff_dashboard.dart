import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'home_screen.dart';
import 'login.dart';
import '../main.dart'; // Import untuk fungsi ganti tema
import '../widgets/theme_toggle_button.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 0;
  final dio = Dio();
  List<dynamic> cartItems = [];
  List<dynamic> transactionHistory = [];
  String searchQuery = ''; 

String get baseUrl => 'https://retail-buah-v2-7mu3ahd3h-anantapramudyaalfarits-projects.vercel.app/api';
String get storageUrl => 'https://retail-buah-v2-7mu3ahd3h-anantapramudyaalfarits-projects.vercel.app/uploads';

  @override
  void initState() {
    super.initState();
    _fetchTransactionHistory();
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      final response = await dio.get('$baseUrl/transactions');
      setState(() => transactionHistory = response.data ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat riwayat')),
        );
      }
    }
  }

  void _addToCart(dynamic product) {
    final existingItemIndex = cartItems.indexWhere((item) => item['id'] == product['id']);
    final quantity = product['quantity'] ?? 1;

    setState(() {
      if (existingItemIndex != -1) {
        cartItems[existingItemIndex]['quantity'] = 
            (cartItems[existingItemIndex]['quantity'] ?? 1) + quantity;
      } else {
        cartItems.add({...product, 'quantity': quantity});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['nama']} x$quantity ditambah ke keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _checkout() async {
    if (cartItems.isEmpty) return;

    try {
      for (var item in cartItems) {
        print('💳 Processing item: ${item['nama']} (ID: ${item['id']})');
        
        // 1. Buat transaksi dengan detail produk lengkap
        try {
          final transactionResponse = await dio.post('$baseUrl/transactions', data: {
            'product_id': item['id'],
            'product_name': item['nama'],
            'quantity': item['quantity'],
            'price': item['harga'],
            'total_price': (item['harga'] ?? 0) * item['quantity'],
          });
          print('✅ Transaction created: ${transactionResponse.data}');
        } catch (e) {
          print('❌ Transaction error: $e');
          throw Exception('Gagal membuat transaksi untuk ${item['nama']}: $e');
        }

        // 2. Kurangi stok
        try {
          print('📉 Reducing stock for product ${item['id']} by ${item['quantity']}');
          final stockResponse = await dio.put(
            '$baseUrl/products/${item['id']}/reduce-stock',
            data: {'quantity': item['quantity'] ?? 1},
          );
          print('✅ Stock reduced: ${stockResponse.data}');
        } catch (e) {
          print('❌ Stock reduction error: $e');
          throw Exception('Gagal mengurangi stok untuk ${item['nama']}: $e');
        }
      }

      setState(() => cartItems.clear());
      await _fetchTransactionHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transaksi Berhasil! Stok telah diperbarui.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Checkout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeFromCart(int index) {
    setState(() => cartItems.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Staff Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        actions: const [
          ThemeToggleButton(), // Tombol ganti tema global
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildPenjualanTab(isDark, theme),
          _buildRiwayatTab(isDark, theme),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Penjualan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }

  Widget _buildPenjualanTab(bool isDark, ThemeData theme) {
    return Row(
      children: [
        // Bagian Kiri: List Produk + Search
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  ),
                ),
              ),
              Expanded(
                child: HomeScreen(
                  role: 'staff',
                  onAddToCart: _addToCart,
                  searchQuery: searchQuery, // Kirim parameter search
                ),
              ),
            ],
          ),
        ),
        // Bagian Kanan: Keranjang Belanja
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: theme.dividerColor)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFFE91E63)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Keranjang',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Text('${cartItems.length}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFE91E63))),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: cartItems.isEmpty
                      ? Center(
                          child: Icon(Icons.shopping_basket_outlined,
                              size: 40, color: isDark ? Colors.grey[700] : Colors.grey[300]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Card(
                              color: isDark ? Colors.grey[850] : Colors.grey[100],
                              child: ListTile(
                                dense: true,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey[300],
                                  ),
                                  child: (item['image_url'] != null && item['image_url'].toString().isNotEmpty)
                                      ? Image.network(
                                          item['image_url'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 18),
                                        )
                                      : const Icon(Icons.image, size: 18),
                                ),
                                title: Text(item['nama'],
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: Text('x${item['quantity']} - Rp ${item['harga'] * item['quantity']}',
                                    style: const TextStyle(fontSize: 11)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total'),
                          Text(
                            'Rp ${cartItems.fold<int>(0, (sum, item) => sum + (((item['harga'] ?? 0) as int) * ((item['quantity'] ?? 1) as int)))}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00BCD4)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cartItems.isEmpty ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('BAYAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatTab(bool isDark, ThemeData theme) {
    return transactionHistory.isEmpty
        ? Center(child: Icon(Icons.history, size: 60, color: isDark ? Colors.grey[700] : Colors.grey[300]))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: transactionHistory.length,
            itemBuilder: (context, index) {
              final trx = transactionHistory[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[300],
                    ),
                    child: (trx['image_url'] != null && trx['image_url'].toString().isNotEmpty)
                        ? Image.network(
                            trx['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 24),
                          )
                        : const Icon(Icons.image, size: 24),
                  ),
                  title: Text(trx['product_name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${trx['tanggal']?.toString().substring(0, 10) ?? ''} | x${trx['quantity']}',
                  ),
                  trailing: Text('Rp ${trx['total_price']}',
                      style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
  }
}