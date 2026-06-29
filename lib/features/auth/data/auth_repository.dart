import 'dart:convert';
import 'auth_remote_datasource.dart';
import '../domain/asesor_model.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/cache/local_cache.dart';

class AuthRepository {
  static const int maxAttempts = 5;
  static const Duration blockDuration = Duration(minutes: 30);

  final AuthRemoteDatasource _remoteDatasource;
  final LocalDb _localDb;

  AuthRepository(this._remoteDatasource, this._localDb);

  Future<AsesorModel> login(String codigoEmpleado, String password) async {
    await _checkBlock();

    try {
      final asesor = await _remoteDatasource.login(codigoEmpleado, password);
      await _localDb.saveToken(asesor.token ?? '');
      await _localDb.saveSession('');
      await _localDb.saveUserData(jsonEncode(asesor.toJson()));
      await _localDb.saveAttempts(0);
      return asesor;
    } catch (e) {
      await _registerFailedAttempt();
      rethrow;
    }
  }

  Future<AsesorModel> getCurrentUser() async {
    try {
      final asesor = await _remoteDatasource.getCurrentUser();
      await _localDb.saveUserData(jsonEncode(asesor.toJson()));
      return asesor;
    } catch (_) {
      return _getLocalUser();
    }
  }

  Future<AsesorModel> _getLocalUser() async {
    final userData = await _localDb.getUserData();
    if (userData == null) throw Exception('No hay datos de usuario en caché');
    return AsesorModel.fromJson(
      jsonDecode(userData) as Map<String, dynamic>,
    );
  }

  Future<void> logout() async {
    try {
      await _remoteDatasource.logout();
    } catch (_) {}
    await _localDb.clearAll();
  }

  Future<String?> getStoredToken() async {
    return _localDb.getToken();
  }

  Future<bool> isSessionValid() async {
    final token = await _localDb.getToken();
    if (token == null) return false;
    return _remoteDatasource.isSessionValid();
  }

  Future<bool> hasStoredSession() async {
    final token = await _localDb.getToken();
    return token != null;
  }

  Future<void> restoreSession() async {
    final token = await _localDb.getToken();
    if (token != null) {
      await _remoteDatasource.refreshSession();
    }
  }

  Future<void> _checkBlock() async {
    final blockTime = await _localDb.getBlockTime();
    if (blockTime == null) return;

    if (DateTime.now().isBefore(blockTime)) {
      final remaining = blockTime.difference(DateTime.now());
      throw Exception(
        'Demasiados intentos. Intenta de nuevo en ${remaining.inMinutes} minutos.',
      );
    }

    await _localDb.saveAttempts(0);
    await _localDb.saveBlockTime(DateTime.now());
  }

  Future<void> _registerFailedAttempt() async {
    final attempts = await _localDb.getAttempts();
    final newAttempts = attempts + 1;
    await _localDb.saveAttempts(newAttempts);

    if (newAttempts >= maxAttempts) {
      await _localDb.saveBlockTime(DateTime.now().add(blockDuration));
      throw Exception(
        'Has superado el límite de intentos. Bloqueado por 30 minutos.',
      );
    }

    throw Exception(
      'Credenciales incorrectas. Intentos restantes: ${maxAttempts - newAttempts}',
    );
  }

  Future<int> getRemainingAttempts() async {
    final attempts = await _localDb.getAttempts();
    return maxAttempts - attempts;
  }

  Future<DateTime?> getBlockTime() async {
    return _localDb.getBlockTime();
  }

  Future<void> markActivity() async {
    await _localDb.saveLastActivity(DateTime.now());
  }

  Future<DateTime?> getLastActivity() async {
    return _localDb.getLastActivity();
  }

  Future<int> getPendingSyncCount() async {
    final pendientes = await LocalCache.instance.getPendingSync();
    return pendientes.length;
  }
}
