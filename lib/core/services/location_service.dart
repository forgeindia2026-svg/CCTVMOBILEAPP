import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/location/screens/add_address_map_screen.dart';

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
  static Future<String> _fetchIpBasedLocation() async {
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
        return decoded.map((e) => Map<String, String>.from(e)).toList();
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
  List<Map<String, String>> _addresses = [];
  List<Map<String, String>> _filteredAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final list = await LocationService.getSavedAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _filteredAddresses = list;
      });
    }
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredAddresses = _addresses);
      return;
    }

    setState(() {
      _filteredAddresses = _addresses.where((item) {
        final name = (item['name'] ?? '').toLowerCase();
        final addr = (item['address'] ?? '').toLowerCase();
        final type = (item['type'] ?? '').toLowerCase();
        return name.contains(q) || addr.contains(q) || type.contains(q);
      }).toList();
    });
  }

  Future<void> _detectLiveLocation() async {
    if (_isDetecting) return;

    setState(() => _isDetecting = true);

    try {
      final loc = await LocationService.fetchLiveLocation();
      if (mounted) {
        await LocationService.saveAddress(loc);
        Navigator.pop(context, {
          'address': loc,
          'name': '',
          'phone': '',
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  Future<void> _openAddNewAddress() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (ctx) => const AddAddressMapScreen()),
    );
    if (result != null && mounted) {
      final list = await LocationService.getSavedAddresses();
      final latest = list.isNotEmpty ? list.first : {'address': result, 'name': '', 'phone': ''};
      Navigator.pop(context, latest);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header (Flipkart style)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select delivery address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 1. Search Bar (Flipkart Style)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by name, area, street, pincode',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Action Card: Use my current location (Flipkart Cream card style)
          InkWell(
            onTap: _isDetecting ? null : _detectLiveLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9E7), // Flipkart light cream background
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
                    const Icon(Icons.location_on_outlined, color: Color(0xFF92400E), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isDetecting ? 'Fetching high-accuracy GPS location...' : 'Use my current location',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF78350F), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Action Card: + Add New (Flipkart style)
          InkWell(
            onTap: _openAddNewAddress,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Color(0xFF92400E), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFF78350F), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Saved Addresses Heading
          const Text(
            'Saved addresses',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          // 5. Saved Addresses List (Flipkart Exact Cards)
          Expanded(
            child: _filteredAddresses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'No saved addresses yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "Add New" or "Use my current location" above to add your address',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredAddresses.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = _filteredAddresses[i];
                      final type = item['type'] ?? 'Home';
                      final name = item['name'] ?? 'Customer';
                      final address = item['address'] ?? '';
                      final phone = item['phone'] ?? '';
                      final distance = item['distance'] ?? '15 km';
                      final isHome = type.toLowerCase().contains('home');

                      final isCurrentlySelected = widget.currentAddress == address;

                      return InkWell(
                        onTap: () {
                          LocationService.saveAddress(address);
                          Navigator.pop(context, {
                            'name': name,
                            'phone': phone,
                            'address': address,
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrentlySelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: isCurrentlySelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type Badge Icon (Home / Work square)
                              Container(
                                width: 56,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isHome ? Icons.home_outlined : Icons.apartment_outlined,
                                      color: const Color(0xFF1E293B),
                                      size: 22,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      distance,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Address Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (isCurrentlySelected) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDBEAFE),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'SELECTED',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1D4ED8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          phone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 3-dots Menu
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onSelected: (val) async {
                                  if (val == 'delete') {
                                    await LocationService.deleteSavedAddress(i);
                                    _loadAddresses();
                                  } else if (val == 'select') {
                                    LocationService.saveAddress(address);
                                    if (mounted) Navigator.pop(context, address);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'select', child: Text('Deliver to this address')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete address', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
