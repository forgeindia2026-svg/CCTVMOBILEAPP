import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/product_model.dart';
import 'storage_service.dart';

class ApiService {
  static String? _workingBaseUrl;

  static List<String> get _candidateUrls {
    if (kIsWeb) {
      return [
        'https://65.0.45.64.sslip.io/api',
        'http://localhost:5000/api',
        'http://127.0.0.1:5000/api',
      ];
    } else {
      return [
        'https://65.0.45.64.sslip.io/api',
        'http://localhost:5000/api',       // ADB Reverse mapped port
        'http://10.10.101.8:5000/api',     // Wi-Fi Local Network IP
        'http://10.0.2.2:5000/api',         // Android Emulator loopback
      ];
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();

    // Try cached working URL first
    if (_workingBaseUrl != null) {
      try {
        final url = Uri.parse('$_workingBaseUrl/$endpoint');
        final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
        return _handleResponse(response);
      } on TimeoutException {
        _workingBaseUrl = null;
      } catch (e) {
        // If it's an API Exception (e.g. status code error), rethrow it directly
        if (e is Exception && !e.toString().contains('SocketException')) {
          rethrow;
        }
        _workingBaseUrl = null;
      }
    }

    Object? lastError;
    for (final base in _candidateUrls) {
      try {
        final url = Uri.parse('$base/$endpoint');
        final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
        _workingBaseUrl = base;
        debugPrint('Connected to GET backend at: $base/$endpoint');
        return _handleResponse(response);
      } catch (e) {
        lastError = e;
        // If server responded with an error JSON (400/401/404), rethrow that server error!
        if (e is Exception && e.toString().startsWith('Exception: ')) {
          _workingBaseUrl = base;
          rethrow;
        }
      }
    }

    throw Exception('Network connection error: ${lastError ?? "Server unreachable"}');
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();

    if (_workingBaseUrl != null) {
      try {
        final url = Uri.parse('$_workingBaseUrl/$endpoint');
        final response = await http
            .post(url, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 30));
        return _handleResponse(response);
      } on TimeoutException {
        _workingBaseUrl = null;
      } catch (e) {
        if (e is Exception && !e.toString().contains('SocketException')) {
          rethrow;
        }
        _workingBaseUrl = null;
      }
    }

    Object? lastError;
    for (final base in _candidateUrls) {
      try {
        final url = Uri.parse('$base/$endpoint');
        final response = await http
            .post(url, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 30));
        _workingBaseUrl = base;
        debugPrint('Connected to POST backend at: $base/$endpoint');
        return _handleResponse(response);
      } catch (e) {
        lastError = e;
        if (e is Exception && e.toString().startsWith('Exception: ')) {
          _workingBaseUrl = base;
          rethrow;
        }
      }
    }

    throw Exception('Failed to connect to backend server: ${lastError ?? "Network error"}');
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();

    if (_workingBaseUrl != null) {
      try {
        final url = Uri.parse('$_workingBaseUrl/$endpoint');
        final response = await http
            .put(url, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 30));
        return _handleResponse(response);
      } on TimeoutException {
        _workingBaseUrl = null;
      } catch (e) {
        if (e is Exception && !e.toString().contains('SocketException')) {
          rethrow;
        }
        _workingBaseUrl = null;
      }
    }

    Object? lastError;
    for (final base in _candidateUrls) {
      try {
        final url = Uri.parse('$base/$endpoint');
        final response = await http
            .put(url, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 30));
        _workingBaseUrl = base;
        debugPrint('Connected to PUT backend at: $base/$endpoint');
        return _handleResponse(response);
      } catch (e) {
        lastError = e;
        if (e is Exception && e.toString().startsWith('Exception: ')) {
          _workingBaseUrl = base;
          rethrow;
        }
      }
    }

    throw Exception('Failed to connect to backend server: ${lastError ?? "Network error"}');
  }

  // Helper method to fetch categories from backend API
  static Future<List<Map<String, dynamic>>> fetchCategories({bool featuredOnly = false}) async {
    try {
      String query = featuredOnly ? '?featured=true' : '';
      final res = await get('categories$query');
      if (res != null && res['success'] == true && res['data'] is List) {
        final rawList = res['data'] as List;
        return rawList.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories from backend: $e');
      return [];
    }
  }

  // Helper method to fetch products from backend API
  static Future<List<ProductModel>> fetchProducts({String? category, String? search}) async {
    try {
      String query = '';
      final params = <String>[];
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        params.add('category=${Uri.encodeComponent(category.toLowerCase())}');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(search)}');
      }
      if (params.isNotEmpty) {
        query = '?${params.join('&')}';
      }

      final res = await get('products$query');
      if (res != null && res['success'] == true && res['data'] is List) {
        final rawList = res['data'] as List;
        return rawList.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching products from backend: $e');
      return [];
    }
  }

  // Helper method to fetch live orders from backend API
  static Future<List<OrderModel>> fetchOrders({String? email}) async {
    try {
      if (email == null || email.trim().isEmpty) {
        return [];
      }
      final endpoint = 'orders?email=${Uri.encodeComponent(email.trim())}';
      final res = await get(endpoint);
      if (res != null && res['success'] == true && res['data'] is List) {
        final rawList = res['data'] as List;
        return rawList.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching orders from backend: $e');
      return [];
    }
  }

  static String resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final url = rawUrl.trim();

    if (url.startsWith('local:') || url.startsWith('data:image') || url.startsWith('https://wsrv.nl') || url.startsWith('http://wsrv.nl')) {
      return url;
    }

    // Fix localhost URLs to production host if applicable
    String resolved = url.replaceAll(
      RegExp(r'http://(localhost|127\.0\.0\.1|10\.10\.101\.\d+|10\.0\.2\.2):5000'),
      'https://65.0.45.64.sslip.io',
    );

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      if (kIsWeb) {
        return 'https://wsrv.nl/?url=${Uri.encodeComponent(resolved)}';
      }
      return resolved;
    }

    final host = 'https://65.0.45.64.sslip.io';
    final fullUrl = '$host${resolved.startsWith('/') ? resolved : '/$resolved'}';
    if (kIsWeb) {
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(fullUrl)}';
    }
    return fullUrl;
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String errorMsg = 'An error occurred';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('message')) {
          errorMsg = body['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }
}
