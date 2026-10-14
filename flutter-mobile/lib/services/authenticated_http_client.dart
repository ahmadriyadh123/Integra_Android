import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/auth/local/auth_local_storage.dart';
import 'tenant_api_config.dart';

class _TokenPair {
  const _TokenPair(this.accessToken, this.refreshToken);

  final String accessToken;
  final String refreshToken;
}

class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient({
    required String baseUrl,
    required TenantApiConfig tenantApiConfig,
    required AuthLocalStorage authStorage,
    http.Client? innerClient,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _tenantApiConfig = tenantApiConfig,
       _authStorage = authStorage,
       _innerClient = innerClient ?? http.Client();

  final String _baseUrl;
  final TenantApiConfig _tenantApiConfig;
  final AuthLocalStorage _authStorage;
  final http.Client _innerClient;
  Future<_TokenPair?>? _refreshInFlight;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final originalAuthorization = request.headers['Authorization'];
    final shouldRefresh =
        originalAuthorization != null &&
        originalAuthorization.startsWith('Bearer ') &&
        !request.url.path.endsWith('/auth/login') &&
        !request.url.path.endsWith('/auth/refresh') &&
        !request.url.path.endsWith('/auth/logout');

    if (!shouldRefresh) return _innerClient.send(request);

    final initialTokens = await _loadTokens();
    if (initialTokens != null) {
      request.headers['Authorization'] = 'Bearer ${initialTokens.accessToken}';
    }
    if (request is http.MultipartRequest || request is http.StreamedRequest) {
      final response = await _innerClient.send(request);
      if (response.statusCode != 401) return response;
      if (initialTokens == null) {
        await _expireSession();
        return response;
      }

      final rejectedResponse = await http.Response.fromStream(response);
      await _refreshTokens(initialTokens.accessToken);
      return _asStreamedResponse(rejectedResponse);
    }

    final requestBody = await request.finalize().toBytes();
    final headers = Map<String, String>.from(request.headers);
    final response = await _send(request, headers, requestBody);
    if (response.statusCode != 401) return response;
    if (initialTokens == null) {
      await _expireSession();
      return response;
    }

    final rejectedResponse = await http.Response.fromStream(response);
    final rotatedTokens = await _refreshTokens(initialTokens.accessToken);
    if (rotatedTokens == null) {
      return _asStreamedResponse(rejectedResponse);
    }

    headers['Authorization'] = 'Bearer ${rotatedTokens.accessToken}';
    return _send(request, headers, requestBody);
  }

  http.StreamedResponse _asStreamedResponse(http.Response response) =>
      http.StreamedResponse(
        http.ByteStream.fromBytes(response.bodyBytes),
        response.statusCode,
        contentLength: response.bodyBytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );

  Future<void> _expireSession() async {
    final callback = _tenantApiConfig.onSessionExpired;
    if (callback != null) {
      await callback();
    } else {
      await _authStorage.clearStoredTokens();
    }
  }

  Future<_TokenPair?> _loadTokens() async {
    final auth = await _authStorage.loadAuth();
    final accessToken = auth?['access_token'];
    final refreshToken = await _authStorage.loadRefreshToken();
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }
    return _TokenPair(accessToken, refreshToken);
  }

  Future<_TokenPair?> _refreshTokens(String rejectedAccessToken) {
    final pending = _refreshInFlight;
    if (pending != null) return pending;

    final refresh = _rotateTokens(rejectedAccessToken);
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    });
  }

  Future<_TokenPair?> _rotateTokens(String rejectedAccessToken) async {
    final current = await _loadTokens();
    if (current == null) return null;
    if (current.accessToken != rejectedAccessToken) return current;

    final response = await _innerClient.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        if (_tenantApiConfig.schoolId.isNotEmpty)
          'X-School-ID': _tenantApiConfig.schoolId,
      },
      body: jsonEncode({'refresh_token': current.refreshToken}),
    );
    if (response.statusCode == 401 ||
        response.statusCode == 400 ||
        response.statusCode == 403) {
      await _expireSession();
      return null;
    }
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['success'] != true) {
      throw const FormatException('Respons refresh token tidak valid.');
    }
    final data = decoded['data'];
    if (data is! Map ||
        data['access_token'] is! String ||
        data['refresh_token'] is! String ||
        (data['access_token'] as String).isEmpty ||
        (data['refresh_token'] as String).isEmpty) {
      throw const FormatException('Data refresh token tidak valid.');
    }

    final tokens = _TokenPair(
      data['access_token'] as String,
      data['refresh_token'] as String,
    );
    await _authStorage.saveRefreshedTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  Future<http.StreamedResponse> _send(
    http.BaseRequest original,
    Map<String, String> headers,
    List<int> body,
  ) {
    final replay = http.Request(original.method, original.url)
      ..headers.addAll(headers)
      ..bodyBytes = body;
    return _innerClient.send(replay);
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }
}
