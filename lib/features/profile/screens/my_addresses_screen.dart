import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  String _userName = 'Customer';
  String _userContact = '';

  final List<Map<String, String>> _addresses = [
    {
      'type': 'Home',
      'name': 'Customer',
      'address': '12, 3rd Cross Street, Anna Nagar, Chennai - 600040, Tamil Nadu',
      'phone': '+91 98765 43210',
      'isDefault': 'true',
    },
    {
      'type': 'Office / Commercial Site',
      'name': 'Customer',
      'address': 'SK Tech CCTV Site #45, Mount Road, Chennai - 600002, Tamil Nadu',
      'phone': '+91 98765 43210',
      'isDefault': 'false',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await StorageService.getUserName();
    final email = await StorageService.getUserEmail();
    final phone = await StorageService.getUserPhone();
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        if (phone != null && phone.isNotEmpty) {
          _userContact = phone;
        } else if (email != null) {
          _userContact = email;
        }
      });
    }
  }

  void _showAddAddressDialog() {
    final typeCtrl = TextEditingController(text: 'Home');
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Address Label (Home / Office / Site)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: typeCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Home',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Full Shipping Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: addrCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Door No, Street Name, City, Pincode',
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
              onPressed: () {
                final addr = addrCtrl.text.trim();
                if (addr.isNotEmpty) {
                  setState(() {
                    _addresses.add({
                      'type': typeCtrl.text.trim().isNotEmpty ? typeCtrl.text.trim() : 'Other',
                      'name': _userName,
                      'address': addr,
                      'phone': _userContact,
                      'isDefault': 'false',
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Save Address'),
            ),
          ],
        );
      },
    );
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
            onPressed: _showAddAddressDialog,
            icon: const Icon(Icons.add, color: AppColors.primaryRed, size: 18),
            label: const Text('Add New', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _addresses.length,
          itemBuilder: (context, index) {
            final item = _addresses[index];
            final isDefault = item['isDefault'] == 'true';
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['type']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
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
                    const SizedBox(height: 8),
                    Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(item['address']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(_userContact, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),

                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isDefault) ...[
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (var a in _addresses) {
                                  a['isDefault'] = 'false';
                                }
                                item['isDefault'] = 'true';
                              });
                            },
                            child: const Text('Set as Default', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _addresses.removeAt(index);
                            });
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
