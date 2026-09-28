import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'http://127.0.0.1:8000';

class ApiService {
  // Health check
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // POST /scan/exe — Upload binary bytes (Works in Web + Desktop)
  static Future<Map<String, dynamic>> scanExeBytes(List<int> bytes, String filename) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/scan/exe'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Scan failed: ${response.statusCode} ${response.body}');
  }

  // GET /scan/installed
  static Future<Map<String, dynamic>> scanInstalled() async {
    final response = await http.get(Uri.parse('$_baseUrl/scan/installed'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Installed scan failed: ${response.statusCode}');
  }

  // GET /scan/store
  static Future<List<dynamic>> scanStore() async {
    final response = await http.get(Uri.parse('$_baseUrl/scan/store'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('Store scan failed: ${response.statusCode}');
  }

  // POST /ask
  static Future<String> ask(String contextId, String question) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/ask'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'context_id': contextId, 'question': question}),
    );
    if (response.statusCode == 200) {
      return (json.decode(response.body) as Map<String, dynamic>)['answer'] as String;
    }
    throw Exception('Ask failed: ${response.statusCode}');
  }

  // GET /dashboard/summary
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(Uri.parse('$_baseUrl/dashboard/summary'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Dashboard failed: ${response.statusCode}');
  }

  // GET /dashboard/alternatives/{application}
  static Future<List<dynamic>> getAlternatives(String appName) async {
    final encoded = Uri.encodeComponent(appName);
    final response = await http.get(Uri.parse('$_baseUrl/dashboard/alternatives/$encoded'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['alternatives'] as List<dynamic>;
    }
    throw Exception('Alternatives failed: ${response.statusCode}');
  }
}
