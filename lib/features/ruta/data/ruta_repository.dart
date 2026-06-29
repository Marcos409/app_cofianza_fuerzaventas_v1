import '../domain/ruta_models.dart';
import '../../cartera/domain/cartera_model.dart';
import '../../cartera/data/cartera_local_datasource.dart';
import '../../../core/network/api_client.dart';

class RutaRepository {
  final CarteraLocalDatasource _carteraLocal;
  final ApiClient _api;

  RutaRepository(this._carteraLocal, this._api);

  Future<List<CarteraModel>> getClientesCartera() async {
    return _carteraLocal.getCartera();
  }

  Future<List<ZonaTrabajo>> getZonasTrabajo(String asesorId) async {
    try {
      final data = await _api.get<List>(
        '/zonas-trabajo',
        params: {'asesor_id': asesorId},
      );
      return data
          .map((j) => ZonaTrabajo.fromJson(Map<String, dynamic>.from(j)))
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
      await _api.post('/clientes/$clienteId/ubicacion', data: {
        'lat': lat,
        'lng': lng,
      });
    } catch (_) {}
  }
}
