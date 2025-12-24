import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../main.dart';
import 'admin_dashboard.dart';
import 'staff_dashboard.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String get baseUrl => 'https://retail-buah-v2-7mu3ahd3h-anantapramudyaalfarits-projects.vercel.app/api';

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Username dan password tidak boleh kosong!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      final response = await dio.post(
        '$baseUrl/login',
        data: {
          "username": _usernameController.text,
          "password": _passwordController.text,
        },
      );

      final role = response.data['role'] ?? 'staff';
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role == 'admin'
                ? const AdminDashboard()
                : const StaffDashboard(),
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _showSnackBar('❌ Username atau password salah!');
      } else {
        _showSnackBar('❌ Gagal login: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('❌ Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor otomatis mengikuti tema (scaffoldBackgroundColor)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // TOMBOL SWITCH TEMA DI LOGIN
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, 
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              MyApp.of(context)?.changeTheme(newMode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Header Title - Mengikuti tema teks
                Text(
                  'Fruit Store Management',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Username Field
                TextField(
                  controller: _usernameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person_outline),
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    // Border warna adaptif
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                
                const SizedBox(height: 40),

                // Login Button dengan Gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFFE91E63)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleLogin,
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                              )
                            : const Text(
                                'LOGIN',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sign Up Button - Outline adaptif
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'SIGN UP',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}