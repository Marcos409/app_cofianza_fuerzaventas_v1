import '../domain/ruta_models.dart';
import '../../cartera/domain/cartera_model.dart';
import '../../cartera/data/cartera_local_datasource.dart';
import '../../../core/supabase/supabase_client.dart';

class RutaRepository {
  final CarteraLocalDatasource _carteraLocal;
  final SupabaseService _supabase;

  RutaRepository(this._carteraLocal, this._supabase);

  Future<List<CarteraModel>> getClientesCartera() async {
    return _carteraLocal.getCartera();
  }

  Future<List<ZonaTrabajo>> getZonasTrabajo(String asesorId) async {
    try {
      final response = await _supabase.client
          .from('zonas_trabajo')
          .select()
          .contains('asesores_ids', [asesorId]);

      return (response as List<dynamic>)
          .map((j) => ZonaTrabajo.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> actualizarUbicacionCliente({
    required String clienteId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _supabase.client
          .from('clientes')
          .update({'lat': lat, 'lng': lng}).eq('id', clienteId);
    } catch (_) {}
  }
}
