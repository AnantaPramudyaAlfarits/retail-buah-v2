import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'login.dart';
import '../widgets/theme_toggle_button.dart';
import 'analytics_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final dio = Dio();

String get baseUrl => 'https://retail-buah-v2-7mu3ahd3h-anantapramudyaalfarits-projects.vercel.app/api';
  String get storageUrl => 'https://retail-buah-v2-7mu3ahd3h-anantapramudyaalfarits-projects.vercel.app/uploads';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(role: 'admin'),
          _AnalyticsTab(baseUrl: baseUrl, dio: dio),
          _ProductsTab(baseUrl: baseUrl, storageUrl: storageUrl, dio: dio),
          _StaffTab(baseUrl: baseUrl, dio: dio),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analitik'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
        ],
      ),
    );
  }
}

// ================= TAB PRODUK (CRUD + SEARCH) =================
class _ProductsTab extends StatefulWidget {
  final String baseUrl;
  final String storageUrl;
  final Dio dio;
  const _ProductsTab({required this.baseUrl, required this.storageUrl, required this.dio});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  @override
  void initState() { super.initState(); _fetchProducts(); }

  Future<void> _fetchProducts() async {
    try {
      final res = await widget.dio.get('${widget.baseUrl}/products');
      setState(() {
        products = res.data ?? [];
        filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  void _filter(String q) {
    setState(() => filteredProducts = products.where((p) => p['nama'].toLowerCase().contains(q.toLowerCase())).toList());
  }

  void _showProductDialog({dynamic product}) {
    final nameC = TextEditingController(text: product?['nama'] ?? '');
    final priceC = TextEditingController(text: product?['harga']?.toString() ?? '');
    final stockC = TextEditingController(text: product?['stok']?.toString() ?? '');
    final imageUrlC = TextEditingController(text: product?['image_url'] ?? '');
    final isEdit = product != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setST) => AlertDialog(
          title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview gambar dari URL
                Container(
                  height: 120, width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[500]!),
                  ),
                  child: imageUrlC.text.isNotEmpty
                      ? Image.network(imageUrlC.text, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey))
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imageUrlC,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.link),
                  ),
                  onChanged: (_) => setST(() {}),
                ),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nama Produk')),
                TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
                TextField(controller: stockC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'nama': nameC.text,
                  'harga': priceC.text,
                  'stok': stockC.text,
                  'image_url': imageUrlC.text,
                };
                
                try {
                  if (isEdit) {
                    await widget.dio.put('${widget.baseUrl}/products/${product['id']}', data: data);
                  } else {
                    await widget.dio.post('${widget.baseUrl}/products', data: data);
                  }
                  Navigator.pop(ctx);
                  _fetchProducts();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Simpan'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BCD4),
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(hintText: "Cari produk...", prefixIcon: Icon(Icons.search)), onChanged: _filter)),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, i) {
                final p = filteredProducts[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: Container(width: 50, height: 50, color: Colors.grey[300], child: p['image_url'] != null && p['image_url'] != '' ? Image.network(p['image_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)) : const Icon(Icons.image)),
                    title: Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Rp ${p['harga']} | Stok: ${p['stok']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductDialog(product: p)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                           await widget.dio.delete('${widget.baseUrl}/products/${p['id']}'); _fetchProducts();
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB STAFF (VIEW + EDIT + DELETE + FILTER) =================
class _StaffTab extends StatefulWidget {
  final String baseUrl;
  final Dio dio;
  const _StaffTab({required this.baseUrl, required this.dio});

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  List staffList = [];
  List filteredStaffList = [];
  String selectedFilter = 'semua'; // 'semua', 'admin', 'staff'

  @override
  void initState() { 
    super.initState(); 
    _fetchStaff(); 
  }

  Future _fetchStaff({String? role}) async {
    try {
      final url = role != null && role != 'semua' 
          ? '${widget.baseUrl}/users?role=$role'
          : '${widget.baseUrl}/users';
      final res = await widget.dio.get(url);
      setState(() {
        staffList = res.data ?? [];
        _applyFilter();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _applyFilter() {
    if (selectedFilter == 'semua') {
      filteredStaffList = staffList;
    } else {
      filteredStaffList = staffList.where((u) => u['role'] == selectedFilter).toList();
    }
  }

  void _showEditDialog(dynamic user) {
    final usernameC = TextEditingController(text: user['username']);
    final passwordC = TextEditingController();
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setST) => AlertDialog(
          title: const Text('Edit Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameC,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Baru (kosongkan jika tidak diubah)',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.security),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  ],
                  onChanged: (val) => setST(() => selectedRole = val ?? 'staff'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updateData = {
                    'username': usernameC.text,
                    'role': selectedRole,
                  };
                  if (passwordC.text.isNotEmpty) {
                    updateData['password'] = passwordC.text;
                  }
                  await widget.dio.put('${widget.baseUrl}/users/${user['id']}', data: updateData);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Staff berhasil diperbarui')),
                  );
                  _fetchStaff(role: selectedFilter != 'semua' ? selectedFilter : null);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: $e')),
                  );
                }
              },
              child: const Text('Simpan'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Filter Buttons
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _buildFilterButton('Semua', 'semua', isDark),
                const SizedBox(width: 8),
                _buildFilterButton('Admin', 'admin', isDark),
                const SizedBox(width: 8),
                _buildFilterButton('Staff', 'staff', isDark),
              ],
            ),
          ),
        ),
        // Staff List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchStaff(role: selectedFilter != 'semua' ? selectedFilter : null),
            child: filteredStaffList.isEmpty 
                ? const Center(child: Text("Tidak ada staff")) 
                : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredStaffList.length,
                  itemBuilder: (ctx, i) {
                    final user = filteredStaffList[i];
                    final roleColor = user['role'] == 'admin' ? Colors.purple : Colors.blue;
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: roleColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          user['username'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Role: ${user['role'].toUpperCase()}',
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                              onPressed: () async {
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Hapus Akun?"),
                                    content: Text("Yakin ingin menghapus ${user['username']}?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text("Batal"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await widget.dio.delete('${widget.baseUrl}/users/${user['id']}');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('✅ Staff berhasil dihapus')),
                                    );
                                    _fetchStaff(role: selectedFilter != 'semua' ? selectedFilter : null);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('❌ Error: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String value, bool isDark) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
          _applyFilter();
        });
      },
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      selectedColor: const Color(0xFF00BCD4),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

// ================= TAB ANALITIK =================
class _AnalyticsTab extends StatefulWidget {
  final String baseUrl;
  final Dio dio;
  const _AnalyticsTab({required this.baseUrl, required this.dio});

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  List<dynamic> transactions = [];
  List<dynamic> products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final txRes = await widget.dio.get('${widget.baseUrl}/transactions');
      final pdRes = await widget.dio.get('${widget.baseUrl}/products');
      setState(() {
        transactions = txRes.data ?? [];
        products = pdRes.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
            ),
          )
        : AnalyticsDashboard(
            transactions: transactions,
            products: products,
          );
  }
}