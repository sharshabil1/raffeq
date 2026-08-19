import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DebugLogEntry {
  final String method;
  final String path;
  final dynamic status;
  final bool ok;
  final String reqPreview;
  final String respPreview;
  final String time;

  DebugLogEntry({
    required this.method,
    required this.path,
    required this.status,
    required this.ok,
    required this.reqPreview,
    required this.respPreview,
    required this.time,
  });
}

class ApiResponse {
  final dynamic status;
  final bool ok;
  final dynamic data;
  final String? errorMsg;

  ApiResponse({
    required this.status,
    required this.ok,
    required this.data,
    this.errorMsg,
  });
}

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String _baseUrl = 'http://localhost:8000';
  String? _token;
  final List<DebugLogEntry> debugLogs = [];

  String get baseUrl => _baseUrl;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? 'http://localhost:8000';
    _token = prefs.getString('api_token');
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrl);
  }

  Future<bool> testConnection([String? targetUrl]) async {
    final urlStr = (targetUrl ?? _baseUrl).replaceAll(RegExp(r'/+$'), '');
    try {
      final uri = Uri.parse('$urlStr/api/v1/support/resources');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 1800));
      return res.statusCode >= 200 && res.statusCode < 500;
    } catch (_) {
      try {
        final uriDoc = Uri.parse('$urlStr/docs');
        final resDoc = await http.get(uriDoc).timeout(const Duration(milliseconds: 1800));
        return resDoc.statusCode >= 200 && resDoc.statusCode < 500;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('api_token', token);
    } else {
      await prefs.remove('api_token');
    }
  }

  void _pushDebugLog(
    String method,
    String path,
    dynamic status,
    bool ok,
    String reqPreview,
    String respPreview,
  ) {
    final timeStr = DateTime.now().toIso8601String().split('T').last.split('.').first;
    debugLogs.insert(
      0,
      DebugLogEntry(
        method: method,
        path: path,
        status: status,
        ok: ok,
        reqPreview: reqPreview,
        respPreview: respPreview,
        time: timeStr,
      ),
    );
    if (debugLogs.length > 50) debugLogs.removeLast();
  }

  String formatErrorDetail(dynamic data) {
    if (data is Map) {
      if (data['detail'] is List) {
        final list = data['detail'] as List;
        return list.map((d) {
          final loc = (d['loc'] is List)
              ? (d['loc'] as List).where((x) => x != 'body').join('.')
              : '';
          return loc.isNotEmpty ? '$loc: ${d['msg']}' : '${d['msg']}';
        }).join('\n');
      }
      if (data['detail'] is String) return data['detail'];
      if (data['error'] != null) return data['error'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Something went wrong talking to the API.';
  }

  Future<ApiResponse> request({
    String method = 'GET',
    required String path,
    dynamic body,
    bool auth = true,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{};
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    String reqPreview = body != null ? jsonEncode(body) : '';
    dynamic status = 0;
    bool ok = false;
    dynamic data;
    String? errorMsg;

    try {
      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (method == 'POST') {
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (method == 'PUT') {
        response = await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else {
        throw UnimplementedError();
      }

      status = response.statusCode;
      ok = status >= 200 && status < 300;

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        data = jsonDecode(response.body);
      } else {
        data = response.body;
      }
      if (!ok) {
        errorMsg = formatErrorDetail(data);
      }
    } catch (e) {
      status = 'Network Error';
      ok = false;
      data = {'error': 'Could not reach $url. Check connection & base URL.'};
      errorMsg = 'Could not reach $url';
    }

    _pushDebugLog(
      method,
      path,
      status,
      ok,
      reqPreview,
      data is String ? data : jsonEncode(data),
    );

    return ApiResponse(status: status, ok: ok, data: data, errorMsg: errorMsg);
  }

  Future<ApiResponse> uploadAudio({
    required String path,
    required String filePath,
    required List<int> bytes,
    required String filename,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', url);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    dynamic status = 0;
    bool ok = false;
    dynamic data;
    String? errorMsg;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      status = response.statusCode;
      ok = status >= 200 && status < 300;

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        data = jsonDecode(response.body);
      } else {
        data = response.body;
      }
      if (!ok) {
        errorMsg = formatErrorDetail(data);
      }
    } catch (e) {
      status = 'Network Error';
      ok = false;
      data = {'error': 'Failed uploading audio file.'};
      errorMsg = 'Failed uploading audio file.';
    }

    _pushDebugLog(
      'POST (Multipart)',
      path,
      status,
      ok,
      'filename: $filename, bytes: ${bytes.length}',
      data is String ? data : jsonEncode(data),
    );

    return ApiResponse(status: status, ok: ok, data: data, errorMsg: errorMsg);
  }

  // --- Specific Endpoints ---

  Future<ApiResponse> signup(String email, String password) {
    return request(
      method: 'POST',
      path: '/api/v1/auth/signup',
      body: {'email': email, 'password': password},
      auth: false,
    );
  }

  Future<ApiResponse> login(String email, String password) {
    return request(
      method: 'POST',
      path: '/api/v1/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
  }

  Future<ApiResponse> getMe() {
    return request(method: 'GET', path: '/api/v1/auth/me');
  }

  Future<ApiResponse> getProfile() {
    return request(method: 'GET', path: '/api/v1/profile');
  }

  Future<ApiResponse> submitOnboarding(Map<String, dynamic> answers) {
    return request(
      method: 'POST',
      path: '/api/v1/profile/onboarding',
      body: answers,
    );
  }

  Future<ApiResponse> getProfileHistory() {
    return request(method: 'GET', path: '/api/v1/profile/history');
  }

  Future<ApiResponse> recalibrateProfile(String reflection) {
    return request(
      method: 'PUT',
      path: '/api/v1/profile/recalibrate',
      body: {'reflection': reflection},
    );
  }

  Future<ApiResponse> submitTextJob(String textPrompt) {
    return request(
      method: 'POST',
      path: '/api/v1/jobs/text',
      body: {'text_prompt': textPrompt},
    );
  }

  Future<ApiResponse> getJobStatus(String jobId) {
    return request(
      method: 'GET',
      path: '/api/v1/jobs/${Uri.encodeComponent(jobId)}/status',
    );
  }

  Future<ApiResponse> getJobResults(String jobId) {
    return request(
      method: 'GET',
      path: '/api/v1/jobs/${Uri.encodeComponent(jobId)}/results',
    );
  }

  Future<ApiResponse> getJournals() {
    return request(method: 'GET', path: '/api/v1/journals');
  }

  Future<ApiResponse> deleteJournal(String journalId) {
    return request(
      method: 'DELETE',
      path: '/api/v1/journals/${Uri.encodeComponent(journalId)}',
    );
  }

  Future<ApiResponse> getChatHistory() {
    return request(method: 'GET', path: '/api/v1/chat/history');
  }

  Future<ApiResponse> sendChatMessage(String message) {
    return request(
      method: 'POST',
      path: '/api/v1/chat/message',
      body: {'message': message},
    );
  }

  Future<ApiResponse> getSupportResources({String? country}) {
    final query = country != null ? '?country=${Uri.encodeComponent(country)}' : '';
    return request(method: 'GET', path: '/api/v1/support/resources$query');
  }
}
