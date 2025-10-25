
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String baseUrl = "https://your-backend-api-url.com/api"; // 🔥 Sửa khi dùng thật
  final Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  // -------------------------------------------------------------------------
  // 🧩 MOCK DATA (UI Test)
  // -------------------------------------------------------------------------
  final Map<String, dynamic> _mockResponses = {
    "assignments": [
      {"id": 1, "title": "Mock Assignment 1", "points": 100},
      {"id": 2, "title": "Mock Assignment 2", "points": 50},
    ],
    "quizzes": [
      {"id": 1, "title": "Quiz 1: HTML & CSS", "questions": 10},
      {"id": 2, "title": "Quiz 2: JavaScript Basics", "questions": 8},
    ],
    "auth/login": {"token": "mock-token-123", "user": "student"},
  };

  // -------------------------------------------------------------------------
  // 🌐 REAL API CALLS (commented for now)
  // -------------------------------------------------------------------------

  /*
  Future<http.Response> _sendRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse("$baseUrl/$endpoint");
    final combinedHeaders = {...defaultHeaders, if (headers != null) ...headers};
    http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: combinedHeaders);
        break;
      case 'POST':
        response = await http.post(uri, headers: combinedHeaders, body: jsonEncode(body));
        break;
      case 'PUT':
        response = await http.put(uri, headers: combinedHeaders, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: combinedHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      print("❌ API Error [${response.statusCode}]: ${response.body}");
      throw Exception("API Error: ${response.body}");
    }
  }
  */

  // -------------------------------------------------------------------------
  // 🧱 PUBLIC MOCK METHODS (for UI Testing)
  // -------------------------------------------------------------------------

  Future<List<dynamic>> getList(String endpoint) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockResponses[endpoint] ?? [];
  }

  Future<Map<String, dynamic>?> getItem(String endpoint, int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = _mockResponses[endpoint];
    if (list is List) {
      return list.firstWhere((item) => item["id"] == id, orElse: () => {});
    }
    return null;
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print("📡 Mock POST → $endpoint, data: $body");
    return {"status": "success", "data": body};
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    int id,
    Map<String, dynamic> body,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print("📡 Mock PUT → $endpoint/$id, data: $body");
    return {"status": "success", "data": body};
  }

  Future<bool> delete(String endpoint, int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print("📡 Mock DELETE → $endpoint/$id");
    return true;
  }

  // -------------------------------------------------------------------------
  // 🔥 REAL API ENTRY POINTS (Uncomment when ready)
  // -------------------------------------------------------------------------
  /*
  Future<List<dynamic>> getList(String endpoint) async {
    final response = await _sendRequest('GET', endpoint);
    return jsonDecode(response.body) as List;
  }

  Future<Map<String, dynamic>> getItem(String endpoint, int id) async {
    final response = await _sendRequest('GET', "$endpoint/$id");
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final response = await _sendRequest('POST', endpoint, body: body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> put(String endpoint, int id, Map<String, dynamic> body) async {
    final response = await _sendRequest('PUT', "$endpoint/$id", body: body);
    return jsonDecode(response.body);
  }

  Future<bool> delete(String endpoint, int id) async {
    final response = await _sendRequest('DELETE', "$endpoint/$id");
    return response.statusCode == 200;
  }
  */
}
