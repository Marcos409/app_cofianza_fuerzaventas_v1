import '../../../../core/supabase/supabase_client.dart';
import '../domain/cartera_model.dart';

class CarteraRemoteDatasource {
  final SupabaseService _supabase;

  CarteraRemoteDatasource(this._supabase);

  Future<List<CarteraModel>> getCarteraDiaria({
    required String asesorId,
    required DateTime fecha,
  }) async {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

    final response = await _supabase.client
        .from('cartera_diaria')
        .select('''
          *,
          clientes!inner(
            nombre,
            documento,
            direccion,
            telefono
          )
        ''')
        .eq('asesor_id', asesorId)
        .eq('fecha_asignacion', fechaStr)
        .order('score_prioridad', ascending: false);

    return _parseResponse(response);
  }

  Future<void> sincronizarVisita(Map<String, dynamic> visitaData) async {
    await _supabase.client
        .from('cartera_diaria')
        .update(visitaData)
        .eq('id', visitaData['id']);
  }

  Future<void> sincronizarVisitas(List<Map<String, dynamic>> visitas) async {
    for (final v in visitas) {
      await sincronizarVisita(v);
    }
  }

  List<CarteraModel> _parseResponse(List<dynamic> response) {
    return response.map((json) {
      final clienteData = json['clientes'] as Map<String, dynamic>?;
      final map = Map<String, dynamic>.from(json as Map);
      map['nombre_cliente'] = clienteData?['nombre'] ?? '';
      map['documento_cliente'] = clienteData?['documento'] ?? '';
      map['direccion_cliente'] = clienteData?['direccion'] ?? '';
      map['telefono_cliente'] = clienteData?['telefono'];
      return CarteraModel.fromMap(map);
    }).toList();
  }
}
