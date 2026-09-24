import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/location_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../installation/screens/installation_service_screen.dart';
import 'my_orders_screen.dart';
import 'my_service_requests_screen.dart';
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
  String _userPhone = '';
  String _userAddress = '';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final loggedIn = await StorageService.isLoggedIn();
    final localName = await StorageService.getUserName();
    final localEmail = await StorageService.getUserEmail();
    final localPhone = await StorageService.getUserPhone();
    final localAddress = await StorageService.getUserAddress();

    if (!loggedIn || localEmail == null || localEmail.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userName = localName ?? 'Guest User';
          _userContact = localPhone ?? 'Log in to view account';
          _userAddress = localAddress ?? '';
        });
      }
      return;
    }

    try {
      final res = await ApiService.get('auth/profile?email=${Uri.encodeComponent(localEmail)}');
      if (res != null && res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final addr = data['address']?.toString().trim() ?? '';
        final phone = data['phone']?.toString() ?? localPhone ?? '';
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _userName = data['name']?.toString() ?? localName ?? 'Customer';
            _userContact = data['email']?.toString() ?? localEmail;
            _userPhone = phone;
            _userAddress = addr;
          });
        }
        if (addr.isNotEmpty) {
          await StorageService.setUserAddress(addr);
          await LocationService.saveAddress(addr);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _userName = localName ?? 'Customer';
            _userContact = localEmail;
            _userPhone = localPhone ?? '';
            _userAddress = localAddress ?? '';
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
    final phoneCtrl = TextEditingController(text: _userPhone);
    final emailCtrl = TextEditingController(text: _userContact);
    final addressCtrl = TextEditingController(text: _userAddress);

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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Contact Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: emailCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFF1F5F9),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter 10-digit mobile number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Delivery & Installation Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter delivery address (Door No, Street, City, Pincode)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                final newPhone = phoneCtrl.text.trim();
                final newAddress = addressCtrl.text.trim();
                try {
                  await ApiService.put('auth/profile', {
                    'email': _userContact,
                    'name': newName.isNotEmpty ? newName : _userName,
                    'phone': newPhone,
                    'address': newAddress,
                  });
                  await StorageService.saveSession(
                    token: (await StorageService.getToken()) ?? 'token',
                    email: _userContact,
                    name: newName.isNotEmpty ? newName : _userName,
                    phone: newPhone,
                    address: newAddress,
                  );
                  if (newAddress.isNotEmpty) {
                    await LocationService.saveAddress(newAddress);
                  }
                  _loadUserProfile();
                } catch (e) {
                  debugPrint('Failed to save profile changes to DB: $e');
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
              const Text('Payment Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.payments_outlined, color: Color(0xFF166534), size: 32),
                title: const Text('Cash on Delivery & Site Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Pay technician directly after CCTV delivery & installation'),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF166534)),
              ),
              const SizedBox(height: 10),
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
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4), // Flipkart's grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          lang.tr('account'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
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
                    children: [
                      Expanded(
                        child: Text(
                          lang.tr('log_in_exclusive'),
                          style: const TextStyle(color: Colors.black87, fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(lang.tr('log_in'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
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
                        backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
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
                      title: lang.tr('orders'),
                      subtitle: lang.tr('check_order_status'),
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersScreen()));
                      },
                    ),

                    _buildFlipkartTile(
                      icon: Icons.build_circle_outlined,
                      title: 'Service Requests',
                      subtitle: 'Check booked installation & repair requests',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyServiceRequestsScreen()));
                      },
                    ),

                    _buildFlipkartTile(
                      icon: Icons.favorite_border,
                      title: lang.tr('wishlist'),
                      subtitle: lang.tr('your_saved_items'),
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
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(lang.tr('account_settings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ),
                    _buildFlipkartTile(
                      icon: Icons.location_on_outlined,
                      title: lang.tr('saved_addresses'),
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAddressesScreen()));
                      },
                    ),

                    _buildFlipkartTile(
                      icon: Icons.credit_card_outlined,
                      title: lang.tr('saved_cards_wallet'),
                      iconColor: AppColors.primaryRed,
                      onTap: _showPaymentMethodsSheet,
                    ),

                    _buildFlipkartTile(
                      icon: Icons.language_outlined,
                      title: lang.tr('select_language'),
                      subtitle: lang.currentLanguageName,
                      iconColor: AppColors.primaryRed,
                      onTap: _showLanguageSelectionSheet,
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
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(lang.tr('services'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ),
                    _buildFlipkartTile(
                      icon: Icons.engineering_outlined,
                      title: lang.tr('installation_bookings'),
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const InstallationServiceScreen()));
                      },
                    ),

                    _buildFlipkartTile(
                      icon: Icons.headset_mic_outlined,
                      title: lang.tr('help_center'),
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
                  title: lang.tr('refer_earn'),
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

  void _showLanguageSelectionSheet() {
    final languages = [
      {'code': 'en', 'name': 'English', 'native': 'English', 'sub': 'Default'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'sub': 'Tamil'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी', 'sub': 'Hindi'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు', 'sub': 'Telugu'},
      {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം', 'sub': 'Malayalam'},
      {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'sub': 'Kannada'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.language, color: AppColors.primaryRed, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Select Language',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
                    ...languages.map((lang) {
                      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
                      final isSelected = Provider.of<LanguageProvider>(context).currentLanguage == lang['code'];
                      return ListTile(
                        onTap: () {
                          langProvider.setLanguage(lang['code']!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Language set to ${lang['name']} (${lang['native']})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF15803D),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryRed : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              lang['native']!.characters.first,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primaryRed : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          lang['native']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? AppColors.primaryRed : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          '${lang['name']} • ${lang['sub']}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primaryRed, size: 22)
                            : const Icon(Icons.radio_button_unchecked, color: Color(0xFFCBD5E1), size: 22),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
