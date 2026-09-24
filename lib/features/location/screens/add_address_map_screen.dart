import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';

class AddAddressMapScreen extends StatefulWidget {
  final String? initialAddress;

  const AddAddressMapScreen({super.key, this.initialAddress});

  @override
  State<AddAddressMapScreen> createState() => _AddAddressMapScreenState();
}

class _AddAddressMapScreenState extends State<AddAddressMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _houseCtrl = TextEditingController();
  final TextEditingController _buildingCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String _selectedType = 'Home'; // Home, Work, Site
  String _areaTitle = 'Bengaluru';
  String _fullAddress = 'Loading live location...';
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final bool _showDetailsForm = false;

  // Real Map Center Coordinates (Default: Bengaluru 12.9716, 77.5946)
  LatLng _centerLatLng = const LatLng(12.9716, 77.5946);
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _parseAddress(widget.initialAddress!);
    }
    // Small delay to ensure MapController is mounted before moving
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentGpsLocation();
    });
  }

  Future<void> _fetchCurrentGpsLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      final locData = await LocationService.fetchLiveCoordinatesAndAddress();
      final double lat = (locData['lat'] as num?)?.toDouble() ?? 12.6644;
      final double lon = (locData['lon'] as num?)?.toDouble() ?? 77.9734;
      final String addr = locData['address'] as String? ?? LocationService.defaultAddress;

      final target = LatLng(lat, lon);
      if (mounted) {
        setState(() {
          _centerLatLng = target;
        });
        _parseAddress(addr);
        try {
          _mapController.move(target, 17.0);
        } catch (_) {}
      }
    } catch (_) {
      final loc = await LocationService.fetchLiveLocation();
      if (mounted) _parseAddress(loc);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _parseAddress(String addr) {
    setState(() {
      _fullAddress = addr;
      final parts = addr.split(',');
      if (parts.isNotEmpty) {
        _areaTitle = parts[0].trim();
      }
    });
  }

  /// Live Reverse-Geocode when user moves the map
  Future<void> _reverseGeocodeLatLng(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1&zoom=18',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'CCTV_InteractiveMap/1.0',
        'Accept-Language': 'en-US,en;q=0.9',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null && mounted) {
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

          String mainTitle = streetParts.take(2).join(', ');
          if (mainTitle.isEmpty) mainTitle = city.isNotEmpty ? city : (state.isNotEmpty ? state : 'Current Location');

          String fullAddr;
          if (streetParts.isNotEmpty) {
            fullAddr = '${streetParts.join(', ')}, ${city.isNotEmpty ? city : state}$postcode';
          } else {
            fullAddr = '${city.isNotEmpty ? city : state}$postcode';
          }

          setState(() {
            _areaTitle = mainTitle;
            _fullAddress = LocationService.cleanAddress(fullAddr);
          });
        }
      }
    } catch (_) {}
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _centerLatLng = camera.center;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        _reverseGeocodeLatLng(camera.center.latitude, camera.center.longitude);
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&countrycodes=in&limit=6',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'CCTVApp_AddressSearch/1.0',
        'Accept-Language': 'en-US,en;q=0.9',
      }).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        if (mounted) {
          setState(() {
            _searchResults = list.map<Map<String, dynamic>>((e) {
              return {
                'display_name': e['display_name'] ?? '',
                'lat': double.tryParse(e['lat'].toString()) ?? 12.9716,
                'lon': double.tryParse(e['lon'].toString()) ?? 77.5946,
                'name': e['name'] ?? e['display_name']?.split(',')?.first ?? 'Location',
              };
            }).toList();
            _isSearching = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> item) {
    final lat = item['lat'] as double;
    final lon = item['lon'] as double;
    final target = LatLng(lat, lon);
    final name = item['name'] as String? ?? '';
    final full = item['display_name'] as String? ?? '';

    setState(() {
      _centerLatLng = target;
      _areaTitle = name.isNotEmpty ? name : (full.split(',').first);
      _fullAddress = LocationService.cleanAddress(full);
      _searchResults = [];
      _searchCtrl.clear();
      FocusScope.of(context).unfocus();
    });

    _mapController.move(target, 17.0);
  }

  Future<void> _saveAddressAndReturn() async {
    final house = _houseCtrl.text.trim();
    final building = _buildingCtrl.text.trim();
    final landmark = _landmarkCtrl.text.trim();
    final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Customer';
    final phone = _phoneCtrl.text.trim();

    final List<String> finalParts = [];
    if (house.isNotEmpty) finalParts.add(house);
    if (building.isNotEmpty) finalParts.add(building);
    if (_fullAddress.isNotEmpty) finalParts.add(_fullAddress);
    if (landmark.isNotEmpty) finalParts.add('Near $landmark');

    final completeAddress = finalParts.join(', ');

    final newAddrMap = {
      'type': _selectedType,
      'name': name,
      'address': completeAddress,
      'phone': phone,
      'distance': 'Local Hub',
      'isDefault': 'true',
    };

    await LocationService.addSavedAddress(newAddrMap);
    await LocationService.saveAddress(completeAddress);

    if (mounted) {
      Navigator.pop(context, completeAddress);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    _searchCtrl.dispose();
    _houseCtrl.dispose();
    _buildingCtrl.dispose();
    _landmarkCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add new address',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          // 1. REAL Interactive Map Layer (OpenStreetMap with Real Streets, Roads & Building Names)
          Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _centerLatLng,
                        initialZoom: 16.5,
                        minZoom: 4.0,
                        maxZoom: 19.0,
                        onPositionChanged: _onMapPositionChanged,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                          userAgentPackageName: 'com.cctv.mobileapp',
                          maxZoom: 20,
                        ),
                      ],
                    ),

                    // Central Pin Marker with CCTV Serviceable Badge
                    IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_rounded, size: 13, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 5),
                                Text(
                                  '$_areaTitle • CCTV Serviceable',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE11D48),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48).withValues(alpha: 0.45),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: const Icon(
                              Icons.location_searching_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 38),
                        ],
                      ),
                    ),

                    // Floating "Use my current location" Pill Button
                    Positioned(
                      bottom: 16,
                      child: InkWell(
                        onTap: _fetchCurrentGpsLocation,
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoadingLocation)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE11D48)),
                                )
                              else
                                const Icon(Icons.my_location_rounded, color: Color(0xFFE11D48), size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Use my current location',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Deliver To Bottom Card
              _buildDeliverToCard(),
            ],
          ),

          // 3. Top Floating Search Bar with Live Suggestions
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by area, name, street, pincode...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE11D48)),
                              ),
                            )
                          : _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                // Search Auto-Complete Dropdown
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final item = _searchResults[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: Color(0xFFE11D48), size: 20),
                          title: Text(
                            item['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            item['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
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
                    const SizedBox(height: 14),

                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add address details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Detected Location Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFE11D48), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fullAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // House / Flat No
                    TextField(
                      controller: _houseCtrl,
                      decoration: InputDecoration(
                        labelText: 'House No. / Building Name *',
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                        floatingLabelStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        hintText: 'e.g. Flat 101, Galaxy Enclave',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Building / Apartment / Street Name
                    TextField(
                      controller: _buildingCtrl,
                      decoration: InputDecoration(
                        labelText: 'Road Name / Area / Colony *',
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                        floatingLabelStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        hintText: 'e.g. 6th Cross, 4th Main Road',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Landmark
                    TextField(
                      controller: _landmarkCtrl,
                      decoration: InputDecoration(
                        labelText: 'Add Nearby Landmark (Optional)',
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                        floatingLabelStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        hintText: 'e.g. Near Apollo Hospital',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Contact Details
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                              floatingLabelStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                              hintText: 'e.g. Ramesh Kumar',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              labelText: '10-digit Mobile *',
                              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                              floatingLabelStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                              hintText: 'e.g. 9876543210',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address Type Selection
                    const Text(
                      'Save address as',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        {'type': 'Home', 'icon': Icons.home_outlined},
                        {'type': 'Work', 'icon': Icons.apartment_outlined},
                        {'type': 'Site', 'icon': Icons.videocam_outlined},
                      ].map((item) {
                        final type = item['type'] as String;
                        final icon = item['icon'] as IconData;
                        final isSelected = _selectedType == type;

                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () {
                              setModalState(() => _selectedType = type);
                              setState(() => _selectedType = type);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF1E293B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(modalCtx);
                          await _saveAddressAndReturn();
                        },
                        child: const Text(
                          'Save Address & Deliver Here',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeliverToCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Deliver To',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 11, color: Color(0xFF15803D)),
                    SizedBox(width: 3),
                    Text(
                      'Direct CCTV Hub Dispatch',
                      style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Address Summary Container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on, color: Color(0xFFE11D48), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _areaTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        side: const BorderSide(color: Color(0xFFE11D48)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Focus on search bar to change
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: const Text('Change', style: TextStyle(color: Color(0xFFE11D48), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _fullAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          if (_showDetailsForm) ...[
            const SizedBox(height: 16),
            // House / Flat No
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _houseCtrl,
                    decoration: InputDecoration(
                      labelText: 'House / Flat / Door No',
                      hintText: 'e.g. 14/A, Flat 302',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _buildingCtrl,
                    decoration: InputDecoration(
                      labelText: 'Building / Society',
                      hintText: 'e.g. Bunt Solar Apt',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _landmarkCtrl,
              decoration: InputDecoration(
                labelText: 'Landmark (Optional)',
                hintText: 'e.g. Near Cine Cube / Main Road',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            // Address Type Chips
            Row(
              children: ['Home', 'Work', 'Site'].map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = type);
                    },
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _showAddressDetailsBottomSheet,
              child: const Text(
                'Add address Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
