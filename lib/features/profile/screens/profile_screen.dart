import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../installation/screens/installation_service_screen.dart';
import 'my_orders_screen.dart';
import 'my_addresses_screen.dart';
import 'wishlist_screen.dart';
import 'support_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Guest User';
  String _userContact = 'Log in to manage your account';
  String _amcPlan = 'Gold AMC Plan';
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final loggedIn = await StorageService.isLoggedIn();
    final localName = await StorageService.getUserName();
    final localEmail = await StorageService.getUserEmail();
    final localPhone = await StorageService.getUserPhone();

    if (!loggedIn || localEmail == null || localEmail.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userName = localName ?? 'Guest User';
          _userContact = localPhone ?? 'Log in to view account';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final res = await ApiService.get('auth/profile?email=${Uri.encodeComponent(localEmail)}');
      if (res != null && res['success'] == true && res['data'] != null) {
        final data = res['data'];
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _userName = data['name']?.toString() ?? localName ?? 'Customer';
            _userContact = data['email']?.toString() ?? localEmail;
            _amcPlan = data['amcPlan']?.toString() ?? 'Gold AMC Plan';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _userName = localName ?? 'Customer';
            _userContact = localEmail;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading backend profile: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _userName = localName ?? 'Customer';
          _userContact = localEmail;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to log out of your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await StorageService.clearSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Color(0xFF166534),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen(isFromLogout: true)),
          (route) => false,
        );
      }
    }
  }

  void _showAccountSettingsDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userContact);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Contact Email / Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFF1F5F9),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    await ApiService.post('auth/profile', {
                      'email': _userContact,
                      'name': newName,
                    });
                    await StorageService.saveSession(
                      token: (await StorageService.getToken()) ?? 'token',
                      email: _userContact,
                      name: newName,
                    );
                    _loadUserProfile();
                  } catch (_) {}
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentMethodsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saved Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.qr_code_2, color: Color(0xFF166534), size: 30),
                title: const Text('UPI Payment (Google Pay / PhonePe)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Primary Default Payment Option'),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF166534)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.credit_card, color: AppColors.primaryRed, size: 30),
                title: const Text('Credit / Debit Cards', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Visa, MasterCard, RuPay'),
                trailing: TextButton(onPressed: () {}, child: const Text('Add Card')),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.payments_outlined, color: Color(0xFFD97706), size: 30),
                title: const Text('Cash on Delivery & Site Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Pay technician after installation inspection'),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF166534)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReferralSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: const Icon(Icons.card_giftcard, color: Color(0xFFD97706), size: 36),
              ),
              const SizedBox(height: 12),
              const Text('Refer & Earn ₹500 Cashback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Share your referral code with friends & family. Earn ₹500 cashback for every successful CCTV installation!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('YOUR CODE: SKCCTV500', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied!')));
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4), // Flipkart's grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Log In Banner for Guest Users
              if (!_isLoggedIn)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Log in to get exclusive offers', style: TextStyle(color: Colors.black87, fontSize: 14)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed, // Flipkart Blue
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text('Log In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              else
                // Logged in User Profile Info (Flipkart Style)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppColors.primaryRed, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(_userContact, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black54, size: 20),
                        onPressed: _showAccountSettingsDialog,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Orders & Wishlist Section
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildFlipkartTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Orders',
                      subtitle: 'Check your order status',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersScreen()));
                      },
                    ),

                    _buildFlipkartTile(
                      icon: Icons.favorite_border,
                      title: 'Wishlist',
                      subtitle: 'Your saved items',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistScreen()));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Account Settings Section
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ),
                    _buildFlipkartTile(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAddressesScreen()));
                      },
                    ),

                    _buildFlipkartTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Saved Cards & Wallet',
                      iconColor: AppColors.primaryRed,
                      onTap: _showPaymentMethodsSheet,
                    ),

                    _buildFlipkartTile(
                      icon: Icons.language_outlined,
                      title: 'Select Language',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        // TODO: Implement language selection
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Services Section
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text('Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ),
                    _buildFlipkartTile(
                      icon: Icons.engineering_outlined,
                      title: 'Installation Bookings',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const InstallationServiceScreen()));
                      },
                    ),

                    _buildFlipkartTile(
                      icon: Icons.headset_mic_outlined,
                      title: 'Help Center',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportCenterScreen()));
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),

              // Refer & Earn Section
              Container(
                color: Colors.white,
                child: _buildFlipkartTile(
                  icon: Icons.card_giftcard,
                  title: 'Refer & Earn',
                  iconColor: AppColors.primaryRed,
                  onTap: _showReferralSheet,
                ),
              ),

              const SizedBox(height: 8),

              // Logout Option
              if (_isLoggedIn)
                Container(
                  color: Colors.white,
                  child: _buildFlipkartTile(
                    icon: Icons.power_settings_new,
                    title: 'Log Out',
                    iconColor: Colors.black54,
                    hideArrow: true,
                    onTap: _handleLogout,
                  ),
                ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlipkartTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool hideArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ]
                ],
              ),
            ),
            if (!hideArrow)
              const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
