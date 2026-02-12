import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/user_auth_service.dart';
import '../config/supabase_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isPhoneLogin = true;
  bool _acceptDisclaimer = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Vigil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Login Options Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton('Phone', true),
                    ),
                    Expanded(
                      child: _buildToggleButton('Email', false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Input Field
              TextField(
                controller: _isPhoneLogin ? _phoneController : _emailController,
                keyboardType: _isPhoneLogin ? TextInputType.phone : TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: _isPhoneLogin ? 'Phone Number' : 'Email Address',
                  hintText: _isPhoneLogin ? '+911234567890' : 'user1@gmail.com',
                  prefixIcon: Icon(_isPhoneLogin ? Icons.phone : Icons.email),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 16),
              // Continue/Login Button
              ElevatedButton(
                onPressed: _handleLogin,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 24),
              // Emergency Disclaimer
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Emergency Disclaimer',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'By continuing, you acknowledge that Vigil is designed for emergency situations and may contact your trusted circle and emergency services when needed.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _acceptDisclaimer,
                        onChanged: (value) {
                          setState(() {
                            _acceptDisclaimer = value ?? false;
                          });
                        },
                        title: const Text('I accept the terms'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final input = _isPhoneLogin ? _phoneController.text.trim() : _emailController.text.trim();
    
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter ${_isPhoneLogin ? "phone number" : "email address"}'),
        ),
      );
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure Supabase credentials first'),
        ),
      );
      return;
    }

    // Show loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Login user
    final authService = UserAuthService();
    final user = await authService.loginUser(
      phone: _isPhoneLogin ? input : null,
      email: _isPhoneLogin ? null : input,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog
    
    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${user.name}!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your email/phone and try again.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPhoneLogin = isSelected;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected == _isPhoneLogin ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected == _isPhoneLogin ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected == _isPhoneLogin ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
