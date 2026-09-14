import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../location/screens/add_address_map_screen.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  String _userName = 'Customer';
  String _userContact = '';
  List<Map<String, String>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await StorageService.getUserName();
    final email = await StorageService.getUserEmail();
    final phone = await StorageService.getUserPhone();
    var addresses = await LocationService.getSavedAddresses();

    String dbAddress = '';
    if (email != null && email.isNotEmpty) {
      try {
        final profileRes = await ApiService.get('auth/profile?email=${Uri.encodeComponent(email)}');
        if (profileRes != null && profileRes['success'] == true && profileRes['data'] != null) {
          final data = profileRes['data'];
          dbAddress = data['address']?.toString().trim() ?? '';
        }
      } catch (e) {
        debugPrint('Could not fetch DB profile: $e');
      }
    }

    if (dbAddress.isEmpty) {
      final cached = await StorageService.getUserAddress();
      if (cached != null && cached.trim().isNotEmpty) {
        dbAddress = cached.trim();
      }
    }

    if (addresses.isEmpty && dbAddress.isNotEmpty) {
      final defaultItem = {
        'name': name ?? 'Customer',
        'phone': phone ?? '',
        'address': dbAddress,
        'type': 'Home',
        'isDefault': 'true',
      };
      await LocationService.addSavedAddress(defaultItem);
      addresses = [defaultItem];
    }

    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        if (phone != null && phone.isNotEmpty) {
          _userContact = phone;
        } else if (email != null) {
          _userContact = email;
        }
        _addresses = addresses;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddAddressMap() async {
    final res = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (ctx) => const AddAddressMapScreen()),
    );
    if (res != null && mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'My Addresses',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openAddAddressMap,
            icon: const Icon(Icons.add_location_alt_outlined, color: Color(0xFF2563EB), size: 18),
            label: const Text('Add New', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
            : _addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_outlined, size: 60, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text('No saved addresses yet', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openAddAddressMap,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Address with Live Map', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final item = _addresses[index];
                      final isDefault = item['isDefault'] == 'true';
                      final type = item['type'] ?? 'Home';
                      final isHome = type.toLowerCase().contains('home');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isHome ? Icons.home_outlined : Icons.apartment_outlined,
                                          size: 14,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Default', style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(item['name'] ?? _userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Text(item['address'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(item['phone'] ?? _userContact, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),

                              const Divider(height: 20, color: Color(0xFFF1F5F9)),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await LocationService.saveAddress(item['address'] ?? '');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Delivery address selected!'), duration: Duration(seconds: 1)),
                                        );
                                      }
                                    },
                                    child: const Text('Deliver Here', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () async {
                                      await LocationService.deleteSavedAddress(index);
                                      _loadData();
                                    },
                                    child: const Text('Remove', style: TextStyle(color: AppColors.primaryRed, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
