import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../navigation/main_navigation_screen.dart';
import '../../profile/screens/support_center_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isFromLogout;
  final bool returnToPrevious;
  const LoginScreen({super.key, this.isFromLogout = false, this.returnToPrevious = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _agreeTerms = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBackAction() {
    if (widget.returnToPrevious && Navigator.canPop(context)) {
      Navigator.pop(context, false);
    } else if (widget.isFromLogout || !Navigator.canPop(context)) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialIndex: 0)),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLoginMode) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the Terms & Conditions to proceed.'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match!'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        // Login Request
        final res = await ApiService.post('auth/login', {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        });

        if (res != null && res['success'] == true && res['data'] != null) {
          final data = res['data'];
          final token = data['token']?.toString() ?? 'session-token';
          final email = data['email']?.toString() ?? _emailController.text.trim();
          final name = data['name']?.toString() ?? 'Customer';
          final phone = data['phone']?.toString() ?? '';

          await StorageService.saveSession(
            token: token,
            email: email,
            phone: phone,
            name: name,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back, $name!'),
                backgroundColor: const Color(0xFF166534),
              ),
            );

            if (widget.returnToPrevious) {
              Navigator.pop(context, true);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                (route) => false,
              );
            }
          }
        } else {
          throw Exception(res?['message'] ?? 'Login failed. Please check credentials.');
        }
      } else {
        // Register Request
        final res = await ApiService.post('auth/register', {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': 'CUSTOMER',
        });

        if (res != null && res['success'] == true && res['data'] != null) {
          final data = res['data'];
          final token = data['token']?.toString() ?? 'session-token';
          final email = data['email']?.toString() ?? _emailController.text.trim();
          final name = data['name']?.toString() ?? _nameController.text.trim();
          final phone = data['phone']?.toString() ?? _phoneController.text.trim();

          await StorageService.saveSession(
            token: token,
            email: email,
            phone: phone,
            name: name,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Account created successfully! Welcome, $name'),
                backgroundColor: const Color(0xFF166534),
              ),
            );

            if (widget.returnToPrevious) {
              Navigator.pop(context, true);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                (route) => false,
              );
            }
          }
        } else {
          throw Exception(res?['message'] ?? 'Registration failed.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isFromLogout,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryRed, // Flipkart Blue
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: _handleBackAction,
          ),
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/sklogo1.jpeg',
                  height: 30,
                  width: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.security, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'SK Technology',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoginMode ? 'Log in for the best experience' : 'Create an account for the best experience',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoginMode
                              ? 'Enter your email address and password to continue'
                              : 'Enter your details to create a new account',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 32),

                        // Register Fields
                        if (!_isLoginMode) ...[
                          _buildFlipkartInput(
                            controller: _nameController,
                            labelText: 'Full Name',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFlipkartInput(
                            controller: _phoneController,
                            labelText: 'Mobile Number',
                            keyboardType: TextInputType.phone,
                            prefixText: '+91 |  ',
                            validator: (v) => v == null || v.trim().length < 10 ? 'Please enter 10 digit mobile number' : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field (Login & Register)
                        _buildFlipkartInput(
                          controller: _emailController,
                          labelText: 'Email-ID',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@') ? 'Please enter a valid email address' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildFlipkartInput(
                          controller: _passwordController,
                          labelText: 'Password',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.primaryRed, size: 20),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                        ),

                        if (!_isLoginMode) ...[
                          const SizedBox(height: 16),
                          _buildFlipkartInput(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.primaryRed, size: 20),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Please confirm your password' : null,
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Toggle Mode Link (Flipkart style "Use Email-ID")
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                              });
                            },
                            child: Text(
                              _isLoginMode ? 'Create New Account' : 'Use Existing Account',
                              style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Section (Terms & Continue Button)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                        children: [
                          TextSpan(text: 'By continuing, you agree to SK Technology\'s '),
                          TextSpan(text: 'Terms of Use', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w500)),
                          TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w500)),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F2F4), // Light grey when disabled/enabled normally
                          foregroundColor: Colors.black45, // Dark grey text
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        // Note: In a real app we might validate text to turn this blue.
                        // For simplicity, we just trigger submit on press.
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text(
                                'Continue',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlipkartInput({
    required TextEditingController controller,
    required String labelText,
    String? prefixText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black54),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryRed),
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.black87, fontSize: 16),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
