import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/location_service.dart';
import '../../navigation/main_navigation_screen.dart';

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

  // Installation & Delivery Address Controllers
  final _doorNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'Tamil Nadu');
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _doorNoController.addListener(() => setState(() {}));
    _streetController.addListener(() => setState(() {}));
    _cityController.addListener(() => setState(() {}));
    _pincodeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _doorNoController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _autoFillCurrentLocation() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detecting live address via GPS...'),
          duration: Duration(seconds: 1),
        ),
      );
      final locData = await LocationService.fetchLiveCoordinatesAndAddress();
      final addr = locData['address']?.toString() ?? '';
      if (addr.isNotEmpty) {
        final parts = addr.split(',').map((e) => e.trim()).toList();
        if (parts.isNotEmpty && _doorNoController.text.isEmpty) {
          _doorNoController.text = parts[0];
        }
        if (parts.length > 1 && _streetController.text.isEmpty) {
          _streetController.text = parts[1];
        }
        if (parts.length > 2 && _cityController.text.isEmpty) {
          _cityController.text = parts[parts.length > 3 ? parts.length - 3 : 2];
        }
        final match = RegExp(r'\b\d{6}\b').firstMatch(addr);
        if (match != null) {
          _pincodeController.text = match.group(0)!;
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint('Auto location error: $e');
    }
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
          final address = data['address']?.toString() ?? '';

          await StorageService.saveSession(
            token: token,
            email: email,
            phone: phone,
            name: name,
            address: address,
          );
          if (address.isNotEmpty) {
            await LocationService.saveAddress(address);
          }

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
        // Register Request with Installation & Delivery Address
        final doorNo = _doorNoController.text.trim();
        final street = _streetController.text.trim();
        final city = _cityController.text.trim();
        final state = _stateController.text.trim();
        final pincode = _pincodeController.text.trim();
        final landmark = _landmarkController.text.trim();

        final addressParts = [
          if (doorNo.isNotEmpty) doorNo,
          if (street.isNotEmpty) street,
          if (landmark.isNotEmpty) 'Near $landmark',
          if (city.isNotEmpty) city,
          if (state.isNotEmpty) state,
          if (pincode.isNotEmpty) pincode,
        ];
        final fullAddress = addressParts.join(', ');

        final res = await ApiService.post('auth/register', {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': 'CUSTOMER',
          'address': fullAddress,
          'doorNo': doorNo,
          'street': street,
          'city': city,
          'state': state,
          'pincode': pincode,
          'landmark': landmark,
        });

        if (res != null && res['success'] == true && res['data'] != null) {
          final data = res['data'];
          final token = data['token']?.toString() ?? 'session-token';
          final email = data['email']?.toString() ?? _emailController.text.trim();
          final name = data['name']?.toString() ?? _nameController.text.trim();
          final phone = data['phone']?.toString() ?? _phoneController.text.trim();
          final address = fullAddress.isNotEmpty ? fullAddress : (data['address']?.toString() ?? '');

          await StorageService.saveSession(
            token: token,
            email: email,
            phone: phone,
            name: name,
            address: address,
          );
          if (address.isNotEmpty) {
            await LocationService.saveAddress(address);
            await LocationService.addSavedAddress({
              'name': name,
              'phone': phone,
              'address': address,
              'type': 'Home',
              'isDefault': 'true',
            });
          }

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
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter 10 digit mobile number';
                              if (v.trim().length != 10) return 'Mobile number must be exactly 10 digits';
                              return null;
                            },
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
                          const SizedBox(height: 20),

                          // INSTALLATION & DELIVERY ADDRESS Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.location_on_outlined, color: AppColors.primaryRed, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'INSTALLATION & DELIVERY ADDRESS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: _autoFillCurrentLocation,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.my_location, color: Color(0xFF2563EB), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'GPS Auto',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 1. Door No / Building / Apartment Name *
                          _buildAddressField(
                            controller: _doorNoController,
                            label: '1. Door No / Building / Apartment Name',
                            hintText: 'Flat 4B / House No',
                            isRequired: true,
                            prefixIcon: const Icon(Icons.apartment_outlined, color: Color(0xFF64748B), size: 20),
                          ),
                          const SizedBox(height: 12),

                          // 2. Street / Area / Colony *
                          _buildAddressField(
                            controller: _streetController,
                            label: '2. Street / Area / Colony',
                            hintText: 'Street Name, Area',
                            isRequired: true,
                            prefixIcon: const Icon(Icons.near_me_outlined, color: Color(0xFF64748B), size: 20),
                          ),
                          const SizedBox(height: 12),

                          // 3. City / Town * & 4. State *
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildAddressField(
                                  controller: _cityController,
                                  label: '3. City / Town',
                                  hintText: 'City',
                                  isRequired: true,
                                  prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF64748B), size: 20),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildAddressField(
                                  controller: _stateController,
                                  label: '4. State',
                                  hintText: 'State',
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 5. Pincode (6 digits) *
                          _buildAddressField(
                            controller: _pincodeController,
                            label: '5. Pincode (6 digits)',
                            hintText: '600001',
                            isRequired: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter pincode';
                              if (v.trim().length != 6) return 'Must be 6 digits';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // 6. Landmark (Optional)
                          _buildAddressField(
                            controller: _landmarkController,
                            label: '6. Landmark',
                            hintText: 'e.g. Near Bus Stand, Opp. Temple',
                            isRequired: false,
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
                          backgroundColor: (_isLoginMode ? (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) : (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty)) ? const Color(0xFFff3b30) : const Color(0xFFF1F2F4),
                          foregroundColor: (_isLoginMode ? (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) : (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty)) ? Colors.white : Colors.black45,
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
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        counterText: '',
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

  Widget _buildAddressField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool isRequired = true,
    Widget? prefixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const TextSpan(
                  text: ' (Optional)',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator ??
              (isRequired
                  ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
                  : null),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
