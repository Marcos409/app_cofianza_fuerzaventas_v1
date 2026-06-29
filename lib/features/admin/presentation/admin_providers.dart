import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/asesor_model.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/local_cache.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    ApiClient.instance,
    LocalCache.instance,
  );
});

enum AdminUsuariosStatus { initial, loading, loaded, error }

class AdminUsuariosState {
  final AdminUsuariosStatus status;
  final List<AsesorModel> usuarios;
  final String? errorMessage;
  final String? successMessage;

  const AdminUsuariosState({
    this.status = AdminUsuariosStatus.initial,
    this.usuarios = const [],
    this.errorMessage,
    this.successMessage,
  });

  AdminUsuariosState copyWith({
    AdminUsuariosStatus? status,
    List<AsesorModel>? usuarios,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminUsuariosState(
      status: status ?? this.status,
      usuarios: usuarios ?? this.usuarios,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AdminUsuariosNotifier extends StateNotifier<AdminUsuariosState> {
  final AdminRepository _repository;
  final AuthState Function() _getAuth;

  AdminUsuariosNotifier(this._repository, this._getAuth)
      : super(const AdminUsuariosState());

  String? get _userId => _getAuth().asesor?.id;

  Future<void> loadUsuarios() async {
    state = state.copyWith(status: AdminUsuariosStatus.loading);
    try {
      final usuarios = await _repository.listUsuarios();
      state = AdminUsuariosState(
        status: AdminUsuariosStatus.loaded,
        usuarios: usuarios,
      );
    } catch (e) {
      state = AdminUsuariosState(
        status: AdminUsuariosStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> crearUsuario({
    required AsesorModel usuario,
    required String password,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      final exists =
          await _repository.existeCodigoEmpleado(usuario.codigoEmpleado);
      if (exists) {
        state = state.copyWith(
          errorMessage: 'El código de empleado ya está registrado',
        );
        return false;
      }
      await _repository.crearUsuario(
        usuario: usuario,
        password: password,
        creadoPor: userId,
      );
      await loadUsuarios();
      state = state.copyWith(successMessage: 'Usuario creado exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> editarUsuario({
    required AsesorModel usuario,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _repository.editarUsuario(
        usuario: usuario,
        realizadoPor: userId,
      );
      await loadUsuarios();
      state = state.copyWith(successMessage: 'Usuario actualizado exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> cambiarRol({
    required String usuarioId,
    required Role nuevoRol,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _repository.cambiarRol(
        usuarioId: usuarioId,
        nuevoRol: nuevoRol,
        realizadoPor: userId,
      );
      await loadUsuarios();
      state = state.copyWith(successMessage: 'Rol actualizado exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleActivo({
    required String usuarioId,
    required bool activo,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _repository.toggleActivo(
        usuarioId: usuarioId,
        activo: activo,
        realizadoPor: userId,
      );
      await loadUsuarios();
      state = state.copyWith(
        successMessage:
            'Usuario ${activo ? 'activado' : 'desactivado'} exitosamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> cambiarPassword({
    required String usuarioId,
    required String nuevaPassword,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _repository.cambiarPassword(
        usuarioId: usuarioId,
        nuevaPassword: nuevaPassword,
        realizadoPor: userId,
      );
      state =
          state.copyWith(successMessage: 'Contraseña actualizada exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> eliminarUsuario(String usuarioId) async {
    final authState = _getAuth();
    final codigo = authState.asesor?.codigoEmpleado;
    print('[DELETE_PROVIDER] intentando eliminar usuario_id=$usuarioId codigo_ejecutor=$codigo');
    if (codigo == null) {
      state = state.copyWith(errorMessage: 'No hay sesión activa');
      return false;
    }
    try {
      await _repository.eliminarUsuario(usuarioId: usuarioId, codigoEmpleado: codigo);
      await loadUsuarios();
      print('[DELETE_PROVIDER] eliminación exitosa usuario_id=$usuarioId');
      state = state.copyWith(successMessage: 'Usuario eliminado exitosamente');
      return true;
    } catch (e) {
      print('[DELETE_PROVIDER] error al eliminar usuario_id=$usuarioId — $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final adminUsuariosProvider =
    StateNotifierProvider<AdminUsuariosNotifier, AdminUsuariosState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  final getAuth = () => ref.read(authProvider);
  return AdminUsuariosNotifier(repository, getAuth);
});

final adminUsuarioProvider =
    FutureProvider.family<AsesorModel?, String>((ref, id) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getUsuario(id);
});
