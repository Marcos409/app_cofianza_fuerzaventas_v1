import 'dart:convert';
import '../domain/cartera_model.dart';
import '../../../core/cache/local_cache.dart';

class CarteraLocalDatasource {
  final LocalCache _cache;

  CarteraLocalDatasource(this._cache);

  Future<void> saveCartera(List<CarteraModel> items, String asesorId) async {
    await _cache.clearTable('cartera_cache', asesorId);
    final list = items.map((e) => e.toMap()).toList();
    await _cache.cacheList('cartera_cache', asesorId, list, 'id');
  }

  Future<List<CarteraModel>> getCartera({String? asesorId}) async {
    if (asesorId == null) return [];
    final items = await _cache.getCachedList('cartera_cache', asesorId);
    return items.map((e) => CarteraModel.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<CarteraModel>> searchClientes(String query, {String? asesorId}) async {
    final all = await getCartera(asesorId: asesorId);
    final q = query.trim().toLowerCase();
    return all.where((c) =>
      c.nombreCliente.toLowerCase().contains(q) ||
      c.documentoCliente.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> actualizarVisita({
    required String id, required String estadoVisita, String? resultadoVisita,
    String? observacion, String? timestamp, double? lat, double? lng,
  }) async {}

  Future<void> actualizarOrdenManual(String id, int orden) async {}

  Future<List<Map<String, dynamic>>> getVisitasPendientes() async {
    return [];
  }

  Future<void> marcarSincronizadas(List<String> ids) async {}

  Future<void> clearAll() async {
    await _cache.clearAll();
  }
}
