import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class LocationService {
  static const String _prefKeyAddress = 'sk_delivery_address';
  static const String _prefKeyPincode = 'sk_delivery_pincode';

  // CCTV Main Warehouse / Dispatch Hub Details
  static const String warehouseAddress =
      'Down street, 2/222A, Berigai - Shoolagiri Rd, Dhoodi, Shoolagiri, Tamil Nadu 635117';
  static const String warehousePincode = '635117';
  static const String warehouseCity = 'Shoolagiri';

  // Default fallback if nothing is available
  static const String defaultAddress = 'Hosur / Shoolagiri - 635117';

  /// Calculate dynamic delivery estimate based on customer address vs Shoolagiri (635117) Warehouse
  static Map<String, dynamic> calculateDeliveryEstimate(String address) {
    final now = DateTime.now();
    // Daily dispatch cutoff time: 4:00 PM (16:00)
    final isBeforeCutoff = now.hour < 16;
    int extraDays = isBeforeCutoff ? 0 : 1;

    // Extract 6 digit pincode if present
    final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(address);
    final pincode = pinMatch?.group(0) ?? '';
    final lowerAddr = address.toLowerCase();

    int deliveryDays = 3;
    String badge = 'Standard Express Delivery';

    if (pincode.startsWith('635') ||
        lowerAddr.contains('shoolagiri') ||
        lowerAddr.contains('hosur') ||
        lowerAddr.contains('krishnagiri')) {
      // Local Warehouse Zone (< 30km)
      deliveryDays = 1;
      badge = '⚡ Local Hub Delivery (Dispatch from Shoolagiri Hub)';
    } else if (pincode.startsWith('560') ||
        pincode.startsWith('561') ||
        pincode.startsWith('562') ||
        lowerAddr.contains('bengaluru') ||
        lowerAddr.contains('bangalore')) {
      // Bengaluru Metro (~50km direct express)
      deliveryDays = 1;
      badge = '⚡ Next-Day Express Delivery (Near Hub)';
    } else if (pincode.startsWith('60') ||
        pincode.startsWith('61') ||
        pincode.startsWith('62') ||
        pincode.startsWith('63') ||
        pincode.startsWith('64') ||
        lowerAddr.contains('tamil nadu') ||
        lowerAddr.contains('chennai') ||
        lowerAddr.contains('coimbatore') ||
        lowerAddr.contains('salem') ||
        lowerAddr.contains('trichy') ||
        lowerAddr.contains('madurai')) {
      // Tamil Nadu Intra-State
      deliveryDays = 2;
      badge = '🚚 Fast Intra-State Delivery (Direct from Shoolagiri)';
    } else if (pincode.startsWith('5') ||
        lowerAddr.contains('karnataka') ||
        lowerAddr.contains('andhra') ||
        lowerAddr.contains('telangana') ||
        lowerAddr.contains('kerala') ||
        lowerAddr.contains('hyderabad')) {
      // South India Zone
      deliveryDays = 3;
      badge = '🚚 South Zone Priority Shipping';
    } else {
      // All-India
      deliveryDays = 4;
      badge = '📦 All-India Insured CCTV Delivery';
    }

    final totalDays = deliveryDays + extraDays;
    final estimatedDate = now.add(Duration(days: totalDays));

    // Calculate remaining cutoff countdown for today
    String countdownText;
    if (isBeforeCutoff) {
      final cutoff = DateTime(now.year, now.month, now.day, 16, 0, 0);
      final diff = cutoff.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
      countdownText = 'Order in ${hours}h ${mins}m ${secs}s for Same-Day Dispatch';
    } else {
      countdownText = 'Order now for Tomorrow 10 AM Dispatch from Shoolagiri Hub';
    }

    return {
      'deliveryDate': estimatedDate,
      'deliveryDays': totalDays,
      'isTomorrow': totalDays == 1,
      'badge': badge,
      'countdownText': countdownText,
      'hub': 'Shoolagiri Warehouse (635117)',
    };
  }

  /// Get current saved delivery address from local cache
  static Future<String> getSavedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKeyAddress) ?? defaultAddress;
    } catch (_) {
      return defaultAddress;
    }
  }

  /// Save delivery address to local cache
  static Future<void> saveAddress(String address, {String? pincode}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyAddress, address);
      if (pincode != null && pincode.isNotEmpty) {
        await prefs.setString(_prefKeyPincode, pincode);
      }
    } catch (_) {}
  }

  /// Fetch Live GPS / Network Coordinates & Address together
  static Future<Map<String, dynamic>> fetchLiveCoordinatesAndAddress() async {
    Position? position;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Live GPS check note: $e');
    }

    if (position != null) {
      final resolved = await _reverseGeocode(position.latitude, position.longitude);
      final addr = (resolved != null && resolved.isNotEmpty) ? resolved : defaultAddress;
      await saveAddress(addr);
      return {
        'lat': position.latitude,
        'lon': position.longitude,
        'address': addr,
      };
    }

    // IP Geolocation Fallback
    try {
      final res = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num?)?.toDouble() ?? 12.6644;
          final lon = (data['lon'] as num?)?.toDouble() ?? 77.9734;
          final resolved = await _reverseGeocode(lat, lon);
          final addr = resolved ?? '${data['city']}, ${data['regionName']} - ${data['zip']}';
          await saveAddress(addr);
          return {
            'lat': lat,
            'lon': lon,
            'address': addr,
          };
        }
      }
    } catch (_) {}

    // Default Shoolagiri / Hosur CCTV Hub
    return {
      'lat': 12.6644,
      'lon': 77.9734,
      'address': 'Down street, 2/222A, Berigai - Shoolagiri Rd, Dhoodi, Shoolagiri, Tamil Nadu 635117',
    };
  }

  /// Bulletproof Live GPS Location Detection with Multiple Fallbacks
  static Future<String> fetchLiveLocation() async {
    final res = await fetchLiveCoordinatesAndAddress();
    return res['address'] as String? ?? defaultAddress;
  }

  /// Clean and format address to match Flipkart / Amazon style
  static String cleanAddress(String rawAddress) {
    if (rawAddress.trim().isEmpty) return defaultAddress;

    String cleaned = rawAddress
        .replaceAll(RegExp(r'\b(City Corporation|Municipal Corporation|Corporation|Taluk|District|Zone|Ward|Subdivision)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(', ,', ',')
        .replaceAll(' ,', ',')
        .trim();

    cleaned = cleaned.replaceAll(RegExp(r'^,\s*|,\s*$'), '');

    // Eliminate duplicate city parts (e.g. "Bengaluru, Bengaluru - 560072")
    final parts = cleaned.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      final p0 = parts[0].toLowerCase();
      final p1 = parts[1].toLowerCase();
      if (p0 == p1 || p0.contains(p1) || p1.contains(p0)) {
        parts.removeAt(0);
        cleaned = parts.join(', ');
      }
    }

    return cleaned.isNotEmpty ? cleaned : defaultAddress;
  }

  /// Reverse-Geocode coordinates to Street / Area / Landmark / City / Pincode (Flipkart Exact Precision)
  static Future<String?> _reverseGeocode(double lat, double lon) async {
    // Method 1: High-Precision OpenStreetMap Nominatim (Zoom 18 = Building & Street Landmark Level)
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1&zoom=18',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'CCTVApp_FlipkartPreciseLocation/1.0',
        'Accept-Language': 'en-US,en;q=0.9',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final building = addr['amenity']?.toString() ??
              addr['building']?.toString() ??
              addr['shop']?.toString() ??
              addr['office']?.toString() ??
              addr['leisure']?.toString();
          final road = addr['road']?.toString() ?? addr['pedestrian']?.toString();
          final neighbourhood = addr['neighbourhood']?.toString();
          final quarter = addr['quarter']?.toString() ?? addr['residential']?.toString() ?? addr['village']?.toString();
          final suburb = addr['suburb']?.toString() ?? addr['subdistrict']?.toString();
          final city = addr['city']?.toString() ??
              addr['town']?.toString() ??
              addr['municipality']?.toString() ??
              addr['state_district']?.toString() ??
              addr['county']?.toString() ??
              '';
          final state = addr['state']?.toString() ?? '';
          final postcode = addr['postcode'] != null ? ' - ${addr['postcode']}' : '';

          final List<String> streetParts = [];
          if (building != null && building.isNotEmpty) streetParts.add(building);
          if (road != null && road.isNotEmpty) streetParts.add(road);
          if (neighbourhood != null && neighbourhood.isNotEmpty && !streetParts.contains(neighbourhood)) streetParts.add(neighbourhood);
          if (quarter != null && quarter.isNotEmpty && !streetParts.contains(quarter)) streetParts.add(quarter);
          if (suburb != null && suburb.isNotEmpty && !streetParts.contains(suburb)) streetParts.add(suburb);

          String finalResult;
          if (streetParts.isNotEmpty) {
            finalResult = '${streetParts.join(', ')}, ${city.isNotEmpty ? city : state}$postcode';
          } else {
            finalResult = '${city.isNotEmpty ? city : state}$postcode';
          }

          final cleaned = cleanAddress(finalResult);
          if (cleaned.isNotEmpty && cleaned != defaultAddress) {
            return cleaned;
          }
        }
      }
    } catch (_) {}

    // Method 2: BigDataCloud High-Speed Client Reverse Geocoder
    try {
      final url = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final rawLocality = data['locality']?.toString() ?? '';
        final city = data['city']?.toString() ?? data['principalSubdivision']?.toString() ?? '';
        final postal = data['postcode']?.toString();

        final List<String> parts = [];
        if (rawLocality.isNotEmpty && rawLocality.toLowerCase() != city.toLowerCase()) {
          parts.add(rawLocality);
        }

        if (data['localityInfo']?['informative'] != null) {
          final infoList = data['localityInfo']['informative'] as List;
          for (var item in infoList) {
            final name = item['name']?.toString() ?? '';
            final order = item['order'] ?? 10;
            if (name.isNotEmpty &&
                !parts.contains(name) &&
                name.toLowerCase() != city.toLowerCase() &&
                name.toLowerCase() != 'india' &&
                (order is int && order >= 5)) {
              parts.add(name);
              if (parts.length >= 2) break;
            }
          }
        }

        String pincodePart = (postal != null && postal.isNotEmpty) ? ' - $postal' : '';
        String rawResult;
        if (parts.isNotEmpty) {
          rawResult = '${parts.join(', ')}, $city$pincodePart';
        } else {
          rawResult = '$city$pincodePart';
        }
        return cleanAddress(rawResult);
      }
    } catch (_) {}

    return null;
  }

  /// IP-based Location Fallback (Works 100% reliably even when GPS is turned off)
  static Future<String> fetchIpBasedLocation() async {
    // 1. Try ip-api.com
    try {
      final res = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          final city = data['city'] ?? 'Chennai';
          final region = data['regionName'] ?? 'Tamil Nadu';
          final zip = data['zip'] != null && data['zip'].toString().isNotEmpty ? ' - ${data['zip']}' : '';
          final result = '$city, $region$zip';
          await saveAddress(result, pincode: data['zip']?.toString());
          return result;
        }
      }
    } catch (_) {}

    // 2. Try freeipapi.com
    try {
      final res = await http.get(Uri.parse('https://freeipapi.com/api/json')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final city = data['cityName'] ?? 'Chennai';
        final region = data['regionName'] ?? 'Tamil Nadu';
        final zip = data['zipCode'] != null && data['zipCode'].toString().isNotEmpty ? ' - ${data['zipCode']}' : '';
        final result = '$city, $region$zip';
        await saveAddress(result, pincode: data['zipCode']?.toString());
        return result;
      }
    } catch (_) {}

    return defaultAddress;
  }

  static const String _prefKeySavedAddresses = 'sk_saved_address_list';

  /// Get list of saved delivery addresses
  static Future<List<Map<String, String>>> getSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeySavedAddresses);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = json.decode(raw);
        final list = decoded.map((e) => Map<String, String>.from(e)).where((item) {
          final addr = item['address'] ?? '';
          final name = item['name'] ?? '';
          return !(name.contains('Dhanush') && (addr.contains('Vinayaka Layout') || addr.contains('Harur')));
        }).toList();
        return list;
      }
    } catch (_) {}

    // Return clean empty list if user hasn't saved any addresses yet
    return [];
  }

  /// Add new address to saved list
  static Future<void> addSavedAddress(Map<String, String> address) async {
    try {
      final list = await getSavedAddresses();
      list.insert(0, address);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeySavedAddresses, json.encode(list));
    } catch (_) {}
  }

  /// Delete saved address
  static Future<void> deleteSavedAddress(int index) async {
    try {
      final list = await getSavedAddresses();
      if (index >= 0 && index < list.length) {
        list.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeySavedAddresses, json.encode(list));
      }
    } catch (_) {}
  }

  /// Open Flipkart / Amazon style Delivery Location Picker Modal (Returns address string)
  static Future<String?> showLocationPicker(BuildContext context, String currentAddress) async {
    final details = await showLocationPickerDetails(context, currentAddress);
    return details?['address'];
  }

  /// Open Location Picker Modal and return complete map with 'name', 'phone', 'address'
  static Future<Map<String, String>?> showLocationPickerDetails(BuildContext context, String currentAddress) async {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationPickerSheet(currentAddress: currentAddress),
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final String currentAddress;
  const _LocationPickerSheet({required this.currentAddress});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isDetecting = false;
  bool _isAddingNewAddress = false;
  List<Map<String, String>> _addresses = [];
  List<Map<String, String>> _filteredAddresses = [];
  int _selectedIndex = 0;

  // Add address form controllers
  final _addFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _selectedState = 'Tamil Nadu';
  String _selectedType = 'Home';

  final List<String> _indianStates = [
    'Tamil Nadu',
    'Karnataka',
    'Andhra Pradesh',
    'Kerala',
    'Telangana',
    'Maharashtra',
    'Delhi',
    'Puducherry',
    'Goa',
    'Gujarat',
    'Odisha',
    'West Bengal',
    'Rajasthan',
    'Uttar Pradesh',
  ];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    var list = await LocationService.getSavedAddresses();
    if (list.isEmpty) {
      final cachedAddr = await StorageService.getUserAddress();
      final userName = await StorageService.getUserName();
      final userPhone = await StorageService.getUserPhone();
      if (cachedAddr != null && cachedAddr.trim().isNotEmpty) {
        final Map<String, String> profileAddr = {
          'name': userName?.isNotEmpty == true ? userName! : 'Customer',
          'phone': userPhone?.isNotEmpty == true ? userPhone! : '',
          'address': cachedAddr.trim(),
          'type': 'Home',
          'isDefault': 'true',
          'isPrimary': 'true',
        };
        await LocationService.addSavedAddress(profileAddr);
        list = [profileAddr];
      }
    }

    if (mounted) {
      setState(() {
        _addresses = list;
        _filteredAddresses = list;
        final found = list.indexWhere((element) => element['address'] == widget.currentAddress);
        _selectedIndex = found >= 0 ? found : (list.isNotEmpty ? 0 : -1);
      });
    }
  }

  Future<void> _detectLiveLocation() async {
    if (_isDetecting) return;

    setState(() => _isDetecting = true);

    try {
      final loc = await LocationService.fetchLiveLocation();
      await LocationService.saveAddress(loc);
      if (mounted) {
        Navigator.pop(context, {
          'address': loc,
          'name': 'Customer',
          'phone': '',
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  Future<void> _saveNewAddress() async {
    if (!_addFormKey.currentState!.validate()) return;

    final street = _streetCtrl.text.trim();
    final locality = _localityCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = _selectedState;
    final pincode = _pincodeCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    final fullAddress = '$street, $locality, $city, $state - $pincode';

    final newItem = {
      'name': name.isNotEmpty ? name : 'Customer',
      'phone': phone,
      'address': fullAddress,
      'type': _selectedType,
      'isDefault': 'false',
    };

    await LocationService.addSavedAddress(newItem);
    await LocationService.saveAddress(fullAddress);

    if (mounted) {
      Navigator.pop(context, newItem);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pincodeCtrl.dispose();
    _localityCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 1. Dark Navy Blue Header Banner (Image 1 & Image 2)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1F38), // Dark Navy Blue
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Yellow Location Pin Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107), // Vibrant Yellow
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF0B1F38),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Delivery & Service Address',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF382F00),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFEAB308), width: 1),
                            ),
                            child: const Text(
                              'STEP 1 OF 2',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFACC15),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose where your order or service booking should be delivered',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: _isAddingNewAddress ? _buildAddAddressForm() : _buildSavedAddressesList(),
            ),
          ),

          // 3. Bottom Action Bar (Overflow Proof)
          Container(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (_isAddingNewAddress) {
                      setState(() => _isAddingNewAddress = false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF64748B)),
                  label: const Text(
                    'BACK TO CART',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isAddingNewAddress) {
                          _saveNewAddress();
                        } else if (_addresses.isNotEmpty && _selectedIndex < _addresses.length) {
                          final chosen = _addresses[_selectedIndex];
                          LocationService.saveAddress(chosen['address'] ?? '');
                          Navigator.pop(context, chosen);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1F38), // Dark Navy Blue
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'CONFIRM ADDRESS',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.check_circle_outline, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top GPS Quick Detect Bar
        InkWell(
          onTap: _isDetecting ? null : _detectLiveLocation,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9E7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                if (_isDetecting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF92400E)),
                  )
                else
                  const Icon(Icons.my_location, color: Color(0xFF92400E), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isDetecting ? 'Detecting live GPS location...' : 'Use current location (Auto GPS)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF78350F)),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF78350F), size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // SELECT FROM SAVED ADDRESSES Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SELECT FROM SAVED ADDRESSES',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: () {
                setState(() => _isAddingNewAddress = true);
              },
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 4),
                  Text(
                    'Add New Address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List of Cards (Image 1 Style)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredAddresses.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            final item = _filteredAddresses[index];
            final isSelected = index == _selectedIndex;
            final type = item['type'] ?? 'Home';
            final isWork = type.toLowerCase().contains('work');
            final isDefault = item['isDefault'] == 'true' || item['isPrimary'] == 'true';

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Radio button
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                          width: isSelected ? 6 : 2,
                        ),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                item['name'] ?? 'Saved Address',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              // Type Badge (WORK / HOME)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isWork ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isWork ? const Color(0xFFB45309) : const Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                              if (isDefault && !isWork)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRIMARY PROFILE ADDRESS',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['address'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                          if ((item['phone'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  'Contact: ${item['phone']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddAddressForm() {
    return Form(
      key: _addFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RECEIVER NAME *
          _buildFormLabel('RECEIVER NAME *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            decoration: _buildInputDeco('Full Name / Receiver Name'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Receiver name is required' : null,
          ),
          const SizedBox(height: 14),

          // 10-DIGIT MOBILE NUMBER *
          _buildFormLabel('10-DIGIT MOBILE NUMBER *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: _buildInputDeco('10-digit mobile number').copyWith(counterText: ''),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mobile number is required';
              if (v.trim().length < 10) return 'Must be 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // PINCODE *
          _buildFormLabel('PINCODE *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pincodeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _buildInputDeco('6-Digit Pincode').copyWith(counterText: ''),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Pincode is required';
              if (v.trim().length < 6) return 'Must be 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // LOCALITY / SECTOR *
          _buildFormLabel('LOCALITY / SECTOR *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _localityCtrl,
            decoration: _buildInputDeco('Locality / Area'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Locality is required' : null,
          ),
          const SizedBox(height: 14),

          // FLAT / HOUSE NO / STREET ADDRESS *
          _buildFormLabel('FLAT / HOUSE NO / STREET ADDRESS *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _streetCtrl,
            decoration: _buildInputDeco('Building / House No, Street Name'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Address detail is required' : null,
          ),
          const SizedBox(height: 14),

          // CITY *
          _buildFormLabel('CITY *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cityCtrl,
            decoration: _buildInputDeco('City'),
            validator: (v) => v == null || v.trim().isEmpty ? 'City is required' : null,
          ),
          const SizedBox(height: 14),

          // STATE *
          _buildFormLabel('STATE *'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _indianStates.contains(_selectedState) ? _selectedState : _indianStates.first,
            decoration: _buildInputDeco('Select State'),
            items: _indianStates.map((st) {
              return DropdownMenuItem(
                value: st,
                child: Text(st, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedState = val);
              }
            },
          ),
          const SizedBox(height: 16),

          // SAVE ADDRESS AS *
          _buildFormLabel('SAVE ADDRESS AS *'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypePill('Home'),
              const SizedBox(width: 10),
              _buildTypePill('Work'),
              const SizedBox(width: 10),
              _buildTypePill('Other'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.4,
      ),
    );
  }

  InputDecoration _buildInputDeco(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }

  Widget _buildTypePill(String type) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFB800) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            type,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
