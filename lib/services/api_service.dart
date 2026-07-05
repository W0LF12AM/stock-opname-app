import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vessel.dart';
import '../models/inventory_item.dart';
import '../models/adjustment.dart';

class APIService {
  static const String baseUrl =
      'https://sertifikasibag.com/inventory_kapal/api';

  static final APIService _instance = APIService._internal();
  factory APIService() => _instance;
  APIService._internal();

  String? _cachedToken;

  // Retrieve auth token from memory or SharedPreferences
  Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  // Clear cached token on logout
  void clearToken() {
    _cachedToken = null;
  }

  // Create common headers
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Basic $token';
      }
    }

    return headers;
  }

  // ==========================================
  // AUTHENTICATION API
  // ==========================================

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth.php');

    try {
      final response = await http
          .post(
            url,
            headers: await _getHeaders(requireAuth: false),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = responseBody['data'];
        final token = data['token'];
        _cachedToken = token;

        // Save session in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('username', username);
        await prefs.setString(
          'password_hash',
          sha256Hash(password),
        ); // for offline verification
        await prefs.setString('full_name', data['user']['full_name']);
        await prefs.setString('role', data['user']['role']);
        await prefs.setInt('user_id', data['user']['id']);

        return data;
      } else {
        throw HttpException(responseBody['message'] ?? 'Login failed');
      }
    } on SocketException {
      throw const SocketException('No Internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // Helper to hash password for offline comparison
  // Stores the raw password since Basic Auth needs it to build auth header during sync
  String sha256Hash(String input) => input;

  // ==========================================
  // VESSEL & INVENTORY SYNC API
  // ==========================================

  Future<List<Vessel>> fetchVessels() async {
    final url = Uri.parse('$baseUrl/vessels.php');

    try {
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (_) {
        final bodySnippet = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        throw FormatException(
          'Respon server bukan JSON valid (Status: ${response.statusCode}). Raw: $bodySnippet',
        );
      }

      if (response.statusCode == 200) {
        final rawData = responseBody['data'];

        // API returns paginated format: {"data": {"total":N, "items": [...]}}
        // Handle both paginated (Map with 'items' key) and flat array formats.
        List<dynamic> list;
        if (rawData is Map && rawData['items'] is List) {
          list = rawData['items'] as List<dynamic>;
        } else if (rawData is List) {
          list = rawData;
        } else {
          list = [];
        }

        return list.map((item) => Vessel.fromJson(item)).toList();
      } else {
        throw HttpException(
          responseBody['message'] ?? 'Failed to fetch vessels',
        );
      }
    } on SocketException {
      throw const SocketException('No Internet connection');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<InventoryItem>> fetchInventory(int vesselId) async {
    final url = Uri.parse('$baseUrl/inventory.php?vessel_id=$vesselId');

    try {
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 8));

      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (_) {
        final bodySnippet = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        throw FormatException(
          'Respon server bukan JSON valid (Status: ${response.statusCode}). Raw: $bodySnippet',
        );
      }

      if (response.statusCode == 200) {
        final rawData = responseBody['data'];

        // API may return paginated format: {"data": {"total":N, "items": [...]}}
        // OR flat format: {"data": [...]}
        List<dynamic> list;
        if (rawData is Map && rawData['items'] is List) {
          list = rawData['items'] as List<dynamic>;
        } else if (rawData is List) {
          list = rawData;
        } else {
          list = [];
        }

        return list
            .map((item) => InventoryItem.fromJson(item, vesselId))
            .toList();
      } else {
        throw HttpException(
          responseBody['message'] ?? 'Failed to fetch inventory',
        );
      }
    } on SocketException {
      throw const SocketException('No Internet connection');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchComponents(int vesselId) async {
    final url = Uri.parse('$baseUrl/components.php?vessel_id=$vesselId');

    try {
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 8));

      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (_) {
        final bodySnippet = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        throw FormatException(
          'Respon server bukan JSON valid (Status: ${response.statusCode}). Raw: $bodySnippet',
        );
      }

      if (response.statusCode == 200) {
        final rawData = responseBody['data'];
        // Defensive: ensure we return a Map
        return (rawData is Map<String, dynamic>) ? rawData : {};
      } else {
        throw HttpException(
          responseBody['message'] ?? 'Failed to fetch components',
        );
      }
    } on SocketException {
      throw const SocketException('No Internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // SYNC SUBMISSION API
  // ==========================================

  Future<void> submitAdjustment(Adjustment adj) async {
    final Uri url;
    final Map<String, dynamic> body;

    if (adj.isExisting) {
      url = Uri.parse('$baseUrl/submit_adjustment.php');
      body = adj.toApiJson();
    } else {
      url = Uri.parse('$baseUrl/create_item.php');
      body = {
        'vessel_id': adj.vesselId,
        'part_name': adj.partName,
        'part_number': adj.partNumber ?? '',
        'satuan': adj.satuan,
        'initial_qty': adj.physicalQty,
        'price': adj.hargaSatuan,
      };

      if (adj.newMainComponent != null && adj.newMainComponent!.isNotEmpty) {
        body['main_component'] = adj.newMainComponent;
      } else {
        body['main_component_id'] = adj.mainComponentId;
      }

      if (adj.newSubComponent != null && adj.newSubComponent!.isNotEmpty) {
        body['sub_component'] = adj.newSubComponent;
      } else if (adj.subComponentId != null && adj.subComponentId != 0) {
        body['sub_component_id'] = adj.subComponentId;
      }
    }

    try {
      final response = await http
          .post(
            url,
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (_) {
        final bodySnippet = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        throw FormatException(
          'Respon server bukan JSON valid (Status: ${response.statusCode}). Raw: $bodySnippet',
        );
      }

      // create_item.php returns 201 Created on success, submit_adjustment returns 200 OK
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw HttpException(
          responseBody['message'] ?? 'Failed to submit adjustment/item',
        );
      }
    } on SocketException {
      throw const SocketException('No Internet connection');
    } catch (e) {
      rethrow;
    }
  }
}
