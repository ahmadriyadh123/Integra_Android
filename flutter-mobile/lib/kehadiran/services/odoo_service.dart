import 'dart:convert';
import 'package:http/http.dart' as http;

class OdooService {
  Future<List<Map<String, dynamic>>> searchRead({
    required Uri url,
    required String db,
    required int uid,
    required String password,
    required String model,
    required List<List<dynamic>> domain,
    required List<String> fields,
    int limit = 80,
    String? order,
  }) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'service': 'object',
          'method': 'execute_kw',
          'args': [
            db,
            uid,
            password,
            model,
            'search_read',
            [domain],
            {
              'fields': fields,
              'limit': limit,
              if (order != null) 'order': order,
            },
          ],
        },
        'id': 3,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server mengembalikan status ${response.statusCode}.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['error'] != null) {
      throw Exception(data['error']['message'] ?? 'Gagal membaca data Odoo.');
    }
    return (data['result'] as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<int?> login({
    required Uri url,
    required String db,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "common",
          "method": "login",
          "args": [db, email, password],
        },
        "id": 1,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server mengembalikan status code ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['error'] != null) {
      throw Exception(data['error']['message'] ?? 'Gagal login');
    }

    final uid = data['result'];
    if (uid == false || uid == null) {
      return null;
    }
    return uid as int;
  }

  Future<Map<String, dynamic>> readUserProfile({
    required Uri url,
    required String db,
    required int uid,
    required String password,
  }) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute_kw",
          "args": [
            db,
            uid,
            password,
            "res.users",
            "read",
            [
              [uid],
            ],
            {
              "fields": ["name", "email"],
            },
          ],
        },
        "id": 2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server mengembalikan status ${response.statusCode} saat membaca profil');
    }

    final data = jsonDecode(response.body);
    if (data['error'] != null) {
      throw Exception(data['error']['message']);
    }

    return data['result'][0] as Map<String, dynamic>;
  }
}
