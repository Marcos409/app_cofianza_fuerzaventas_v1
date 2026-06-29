import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../domain/solicitud_model.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';

class SolicitudLocalDatasource {
  final LocalCache _cache = LocalCache.instance;
  final ApiClient _api = ApiClient.instance;

  Future<void> saveBorrador(SolicitudModel solicitud) async {
    await _cache.cacheJson(
      'solicitudes_borrador_cache',
      solicitud.id,
      solicitud.asesorId,
      solicitud.toBorradorMap(),
    );
  }

  Future<List<SolicitudModel>> getBorradores() async {
    final db = await _cache.database;
    final rows = await db.query(
      'solicitudes_borrador_cache',
      orderBy: 'updated_at DESC',
    );
    return rows.map((r) {
      final data = jsonDecode(r['data_json'] as String);
      return SolicitudModel.fromBorradorMap(Map<String, dynamic>.from(data));
    }).toList();
  }

  Future<void> deleteBorrador(String id) async {
    await _cache.deleteCached('solicitudes_borrador_cache', id);
  }

  Future<SolicitudModel?> getBorrador(String id) async {
    final data = await _cache.getCached('solicitudes_borrador_cache', id);
    if (data == null) return null;
    return SolicitudModel.fromBorradorMap(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveEnviada(SolicitudModel solicitud) async {
    await _api.post('/solicitudes', data: solicitud.toJson());
  }

  Future<SolicitudModel?> getEnviada(String id) async {
    try {
      final apiData = await _api.get<Map<String, dynamic>>('/solicitudes/$id');
      if (apiData != null) {
        return SolicitudModel.fromJson(apiData);
      }
    } catch (_) {}
    try {
      final cached = await _cache.getCached('solicitudes_cache', id);
      if (cached != null) {
        return SolicitudModel.fromJson(Map<String, dynamic>.from(cached));
      }
    } catch (_) {}
    return null;
  }

  Future<List<SolicitudModel>> getAsignadasDesdeServidor(String asesorId) async {
    try {
      final list = await _api.get<List>('/solicitudes/asignadas', params: {'asesor_id': asesorId});
      if (list == null) return [];
      return list.map((item) {
        final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
        return SolicitudModel.fromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SolicitudModel>> getSolicitudesDelMes(String asesorId) async {
    try {
      final list = await _api.get<List>('/solicitudes', params: {'asesor_id': asesorId});
      if (list == null) return [];
      return list.map((item) {
        final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
        return SolicitudModel.fromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
