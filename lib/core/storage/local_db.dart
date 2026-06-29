import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDb {
  static const _prefix = 'app_cfv';

  static final LocalDb instance = LocalDb._();
  LocalDb._();

  final _secureStorage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  Future<void> saveToken(String token) => _secureStorage.write(key: '$_prefix/auth_token', value: token);
  Future<String?> getToken() => _secureStorage.read(key: '$_prefix/auth_token');
  Future<void> deleteToken() => _secureStorage.delete(key: '$_prefix/auth_token');

  Future<void> saveSession(String sessionJson) => _secureStorage.write(key: '$_prefix/session', value: sessionJson);
  Future<String?> getSession() => _secureStorage.read(key: '$_prefix/session');
  Future<void> deleteSession() => _secureStorage.delete(key: '$_prefix/session');

  Future<void> saveUserData(String userDataJson) =>
      _secureStorage.write(key: '$_prefix/user_data', value: userDataJson);
  Future<String?> getUserData() => _secureStorage.read(key: '$_prefix/user_data');

  Future<void> saveAttempts(int count) => _secureStorage.write(key: '$_prefix/login_attempts', value: count.toString());
  Future<int> getAttempts() async {
    final v = await _secureStorage.read(key: '$_prefix/login_attempts');
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> saveBlockTime(DateTime time) =>
      _secureStorage.write(key: '$_prefix/block_until', value: time.toIso8601String());
  Future<DateTime?> getBlockTime() async {
    final v = await _secureStorage.read(key: '$_prefix/block_until');
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<void> saveLastActivity(DateTime time) =>
      _secureStorage.write(key: '$_prefix/last_activity', value: time.toIso8601String());
  Future<DateTime?> getLastActivity() async {
    final v = await _secureStorage.read(key: '$_prefix/last_activity');
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
