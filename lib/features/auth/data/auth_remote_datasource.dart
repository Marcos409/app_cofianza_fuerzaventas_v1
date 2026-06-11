import 'dart:convert';
import '../domain/asesor_model.dart';
import '../../../core/supabase/supabase_client.dart';

class AuthRemoteDatasource {
  final SupabaseService _supabase;

  AuthRemoteDatasource(this._supabase);

  /// Convierte código de empleado en email interno para Supabase Auth.
  String _codigoToEmail(String codigo) => '$codigo@asesor.confianza.pe';

  Future<AsesorModel> login(String codigoEmpleado, String password) async {
    final email = _codigoToEmail(codigoEmpleado);

    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception('Error al autenticar');

    final asesor = await _fetchAsesorData(user.id);
    return asesor.copyWith(token: response.session?.accessToken);
  }

  Future<AsesorModel> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Sesión no encontrada');

    final user = session.user;
    final asesor = await _fetchAsesorData(user.id);
    return asesor.copyWith(token: session.accessToken);
  }

  Future<AsesorModel> _fetchAsesorData(String userId) async {
    final response = await _supabase.client
        .from('asesores_negocio')
        .select()
        .eq('user_id', userId)
        .single();

    final data = jsonDecode(jsonEncode(response)) as Map<String, dynamic>;
    return AsesorModel.fromJson(data);
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<bool> isSessionValid() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return false;
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000).isAfter(
      DateTime.now(),
    );
  }

  Future<void> refreshSession() async {
    await _supabase.auth.refreshSession();
  }
}
