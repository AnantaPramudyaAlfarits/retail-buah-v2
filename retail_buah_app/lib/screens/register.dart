import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../main.dart'; // Import main untuk akses theme switcher jika perlu
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String _selectedRole = 'staff';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

String get baseUrl => 'https://retail-buah-v2-7mu3ahd3h-anantapramudyaalfarits-projects.vercel.app/api';
String get storageUrl => 'https://vercel-deploy-app-retail.vercel.app/uploads';

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Semua field harus diisi!', isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Password tidak cocok!', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('Password minimal 6 karakter!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await dio.post(
        '$baseUrl/register',
        data: {
          "username": _usernameController.text,
          "password": _passwordController.text,
          "role": _selectedRole,
        },
      );

      if (mounted) {
        _showSnackBar('✅ Akun berhasil dibuat! Silakan login.', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } on DioException catch (e) {
      String msg = e.response?.statusCode == 400 
          ? '❌ Username sudah digunakan!' 
          : '❌ Registrasi gagal: ${e.message}';
      _showSnackBar(msg, isError: true);
    } catch (e) {
      _showSnackBar('❌ Terjadi kesalahan jaringan.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        actions: [
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              children: [
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),

                // Username
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  obscure: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_reset,
                  isDark: isDark,
                  obscure: _obscureConfirmPassword,
                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                const SizedBox(height: 16),

                // Role Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      items: ['staff', 'admin'].map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.toUpperCase(), 
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        );
                      }).toList(),
                      onChanged: _isLoading ? null : (v) => setState(() => _selectedRole = v!),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                // Register Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFFE91E63)]),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('SIGN UP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        suffixIcon: onToggleVisibility != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleVisibility,
              )
            : null,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
      ),
      enabled: !_isLoading,
    );
  }
}