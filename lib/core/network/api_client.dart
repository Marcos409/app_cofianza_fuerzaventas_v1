import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _baseUrl = 'http://192.168.1.2:8003';

  static final ApiClient instance = ApiClient._();
  ApiClient._() {
    _init();
  }

  final _secureStorage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static const _tokenKey = 'app_cfv/jwt_token';
  static const _userKey = 'app_cfv/user_data';

  late final Dio dio;
  String? _jwtToken;
  String? _asesorId;

  void _init() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_jwtToken != null) {
          options.headers['Authorization'] = 'Bearer $_jwtToken';
        }
        if (_asesorId != null) {
          options.headers['X-Asesor-Id'] = _asesorId;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _clearToken();
        }
        handler.next(error);
      },
    ));
  }

  Future<String?> getToken() => _secureStorage.read(key: _tokenKey);

  Future<void> setToken(String token) async {
    _jwtToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> _clearToken() async {
    _jwtToken = null;
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<void> clearSession() async {
    _jwtToken = null;
    _asesorId = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  void setAsesorId(String id) => _asesorId = id;

  bool get hasToken => _jwtToken != null;

  Future<Map<String, dynamic>> login(String codigoEmpleado, String password) async {
    final response = await dio.post('/auth/login', data: {
      'codigo_empleado': codigoEmpleado,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    await setToken(data['access_token'] as String);
    final asesor = data['asesor'] as Map<String, dynamic>;
    setAsesorId(asesor['id']?.toString() ?? '');
    await _secureStorage.write(key: _userKey, value: data['asesor'].toString());
    return data;
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? params, T Function(dynamic)? parser}) async {
    final response = await dio.get(path, queryParameters: params);
    if (parser != null) return parser(response.data);
    return response.data as T;
  }

  Future<T> post<T>(String path, {dynamic data, T Function(dynamic)? parser}) async {
    final response = await dio.post(path, data: data);
    if (parser != null) return parser(response.data);
    return response.data as T;
  }

  Future<T> put<T>(String path, {dynamic data, T Function(dynamic)? parser}) async {
    final response = await dio.put(path, data: data);
    if (parser != null) return parser(response.data);
    return response.data as T;
  }

  Future<T> patch<T>(String path, {dynamic data, T Function(dynamic)? parser}) async {
    final response = await dio.patch(path, data: data);
    if (parser != null) return parser(response.data);
    return response.data as T;
  }

  Future<T> delete<T>(String path, {dynamic data, T Function(dynamic)? parser}) async {
    final response = await dio.delete(path, data: data);
    if (parser != null) return parser(response.data);
    return response.data as T;
  }

  Future<Response> uploadFile(String path, String filePath, String fieldName) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return dio.post(path, data: formData, options: Options(contentType: 'multipart/form-data'));
  }
}
