import '../domain/cartera_model.dart';
import '../../../core/network/api_client.dart';

class CarteraRemoteDatasource {
  final ApiClient _apiClient;
  CarteraRemoteDatasource(this._apiClient);

  Future<List<CarteraModel>> getCarteraDiaria({required String asesorId, required DateTime fecha}) async {
    final data = await _apiClient.get<List>('/cartera');
    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      return CarteraModel.fromMap(map);
    }).toList();
  }

  Future<void> sincronizarVisita(Map<String, dynamic> visitaData) async {
    final id = visitaData['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      await _apiClient.post('/cartera/$id/visita', data: visitaData);
    }
  }

  Future<void> sincronizarVisitas(List<Map<String, dynamic>> visitas) async {
    for (final v in visitas) {
      await sincronizarVisita(v);
    }
  }
}
