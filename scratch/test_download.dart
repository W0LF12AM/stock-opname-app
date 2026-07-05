import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://sertifikasibag.com/inventory_kapal/api';
  
  print('=== DIAGNOSTIC API TEST ===');
  
  // admin:admin123
  final String basicAuth = 'Basic ' + base64Encode(utf8.encode('admin:admin123'));
  print('Using Basic Auth for test: $basicAuth');

  try {
    print('1. Fetching inventory for vessel ID 21...');
    final invResponse = await http.get(
      Uri.parse('$baseUrl/inventory.php?vessel_id=21'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': basicAuth,
      },
    ).timeout(const Duration(seconds: 10));
    
    print('Inventory Status: ${invResponse.statusCode}');
    print('Inventory Body length: ${invResponse.body.length}');
    if (invResponse.statusCode == 200) {
      final body = jsonDecode(invResponse.body);
      print('Inventory result keys: ${body.keys}');
      if (body['data'] is Map) {
        print('Inventory items count: ${body['data']['items']?.length}');
      } else {
        print('Inventory items count (flat): ${body['data']?.length}');
      }
    } else {
      print('Inventory Body: ${invResponse.body}');
    }
  } catch (e) {
    print('Error during diagnosis: $e');
  }
}
