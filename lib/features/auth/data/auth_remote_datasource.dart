import 'package:dio/dio.dart';
import '../domain/asesor_model.dart';
import '../../../core/network/api_client.dart';

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource(this._apiClient);

  Future<AsesorModel> login(String codigoEmpleado, String password) async {
    try {
      final data = await _apiClient.login(codigoEmpleado, password);
      final asesorData = data['asesor'] as Map<String, dynamic>;
      return AsesorModel(
        id: asesorData['id']?.toString() ?? '',
        userId: asesorData['user_id']?.toString() ?? asesorData['id']?.toString() ?? '',
        codigoEmpleado: asesorData['codigo_empleado']?.toString() ?? codigoEmpleado,
        nombres: asesorData['nombres']?.toString() ?? '',
        apellidos: asesorData['apellidos']?.toString() ?? '',
        agenciaId: asesorData['agencia_id']?.toString(),
        rol: Role.fromString(asesorData['perfil']?.toString() ?? 'operador'),
        activo: asesorData['activo'] == true,
        email: asesorData['email']?.toString(),
        telefono: asesorData['telefono']?.toString(),
        token: data['access_token'] as String?,
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail']?.toString() : null;
      throw Exception(detail ?? 'Error de conexión. Verifica que el servidor esté encendido.');
    }
  }

  Future<AsesorModel> getCurrentUser() async {
    final data = await _apiClient.get<Map<String, dynamic>>('/auth/me');
    return AsesorModel(
      id: data['id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? data['id']?.toString() ?? '',
      codigoEmpleado: data['codigo_empleado']?.toString() ?? '',
      nombres: data['nombres']?.toString() ?? '',
      apellidos: data['apellidos']?.toString() ?? '',
      agenciaId: data['agencia_id']?.toString(),
      rol: Role.fromString(data['perfil']?.toString() ?? 'operador'),
      activo: data['activo'] == true,
      email: data['email']?.toString(),
      telefono: data['telefono']?.toString(),
    );
  }

  Future<void> logout() async {
    await _apiClient.clearSession();
  }

  Future<bool> isSessionValid() async {
    try {
      await _apiClient.get('/auth/me');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshSession() async {
    try {
      await _apiClient.post('/auth/refresh');
    } catch (_) {}
  }
}
