import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../auth/domain/asesor_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/local_cache.dart';

class AdminRepository {
  final ApiClient _api;
  final LocalCache _cache;
  static final _uuid = const Uuid();

  AdminRepository(this._api, this._cache);

  AsesorModel _fromJson(Map<String, dynamic> json) {
    return AsesorModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      codigoEmpleado: json['codigo_empleado']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      agenciaId: json['agencia_id']?.toString(),
      rol: Role.fromString(json['perfil']?.toString() ?? 'operador'),
      activo: json['activo'] ?? true,
      email: json['email']?.toString(),
      telefono: json['telefono']?.toString(),
    );
  }

  Future<List<AsesorModel>> listUsuarios() async {
    final data = await _api.get<List>('/api/v1/usuarios');
    return data
        .map((j) => _fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<AsesorModel?> getUsuario(String id) async {
    try {
      final data = await _api.get<Map<String, dynamic>>('/api/v1/usuarios/$id');
      return _fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<AsesorModel?> getUsuarioByCodigo(String codigo) async {
    try {
      final data = await _api.get<List>(
        '/api/v1/usuarios',
        params: {'codigo_empleado': codigo},
      );
      if (data.isEmpty) return null;
      return _fromJson(Map<String, dynamic>.from(data.first));
    } catch (_) {
      return null;
    }
  }

  Future<bool> existeCodigoEmpleado(String codigo,
      {String? excludeId}) async {
    final params = <String, dynamic>{'codigo_empleado': codigo};
    if (excludeId != null) params['exclude_id'] = excludeId;
    final data = await _api.get<List>('/api/v1/usuarios', params: params);
    return data.isNotEmpty;
  }

  Future<void> crearUsuario({
    required AsesorModel usuario,
    required String password,
    required String creadoPor,
  }) async {
    await _api.post('/api/v1/usuarios', data: {
      'id': usuario.id,
      'codigo_empleado': usuario.codigoEmpleado,
      'nombres': usuario.nombres,
      'apellidos': usuario.apellidos,
      'email': usuario.email,
      'telefono': usuario.telefono,
      'password': password,
      'perfil': usuario.rol.jsonValue,
      'agencia_id': usuario.agenciaId,
      'activo': usuario.activo,
    });
    await _registrarAuditoria(
      usuarioId: usuario.id,
      accion: 'CREAR',
      detalle:
          'Usuario creado: ${usuario.nombreCompleto} (${usuario.rol.label})',
      realizadoPor: creadoPor,
    );
  }

  Future<void> editarUsuario({
    required AsesorModel usuario,
    required String realizadoPor,
  }) async {
    await _api.put('/api/v1/usuarios/${usuario.id}', data: {
      'nombres': usuario.nombres,
      'apellidos': usuario.apellidos,
      'email': usuario.email,
      'telefono': usuario.telefono,
      'agencia_id': usuario.agenciaId,
      'perfil': usuario.rol.jsonValue,
      'activo': usuario.activo,
    });
    await _registrarAuditoria(
      usuarioId: usuario.id,
      accion: 'EDITAR',
      detalle: 'Datos actualizados: ${usuario.nombreCompleto}',
      realizadoPor: realizadoPor,
    );
  }

  Future<void> cambiarRol({
    required String usuarioId,
    required Role nuevoRol,
    required String realizadoPor,
  }) async {
    await _api.patch('/api/v1/usuarios/$usuarioId', data: {
      'perfil': nuevoRol.jsonValue,
    });
    await _registrarAuditoria(
      usuarioId: usuarioId,
      accion: 'CAMBIAR_ROL',
      detalle: 'Rol cambiado a ${nuevoRol.label}',
      realizadoPor: realizadoPor,
    );
  }

  Future<void> toggleActivo({
    required String usuarioId,
    required bool activo,
    required String realizadoPor,
  }) async {
    await _api.patch('/api/v1/usuarios/$usuarioId', data: {
      'activo': activo,
    });
    await _registrarAuditoria(
      usuarioId: usuarioId,
      accion: activo ? 'ACTIVAR' : 'DESACTIVAR',
      detalle: 'Usuario ${activo ? 'activado' : 'desactivado'}',
      realizadoPor: realizadoPor,
    );
  }

  Future<void> cambiarPassword({
    required String usuarioId,
    required String nuevaPassword,
    required String realizadoPor,
  }) async {
    await _api.patch('/api/v1/usuarios/$usuarioId', data: {
      'password': nuevaPassword,
    });
    await _registrarAuditoria(
      usuarioId: usuarioId,
      accion: 'CAMBIAR_PASSWORD',
      detalle: 'Contraseña actualizada',
      realizadoPor: realizadoPor,
    );
  }

  Future<void> eliminarUsuario({
    required String usuarioId,
    required String codigoEmpleado,
  }) async {
    await _api.delete('/api/v1/usuarios/$usuarioId');
  }

  Future<void> _registrarAuditoria({
    required String usuarioId,
    required String accion,
    String? detalle,
    required String realizadoPor,
  }) async {
    try {
      await _api.post('/api/v1/auditoria', data: {
        'id': _uuid.v4(),
        'usuario_id': usuarioId,
        'accion': accion,
        'detalle': detalle,
        'realizado_por': realizadoPor,
      });
    } catch (_) {
      await _cache.enqueueSync('auditoria', _uuid.v4(), 'INSERT', {
        'usuario_id': usuarioId,
        'accion': accion,
        'detalle': detalle,
        'realizado_por': realizadoPor,
      });
    }
  }
}
