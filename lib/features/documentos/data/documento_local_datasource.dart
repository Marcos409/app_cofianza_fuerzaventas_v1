import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';
import '../domain/documento_model.dart';

class DocumentoLocalDatasource {
  final LocalCache _cache = LocalCache.instance;
  final ApiClient _api = ApiClient.instance;

  Future<List<DocumentoModel>> listar(String solicitudId) async {
    // Local cache first (tiene el estado real: listo, pendiente, etc.)
    try {
      final db = await _cache.database;
      final rows = await db.query(
        'documentos_cache',
        where: 'solicitud_id = ?',
        whereArgs: [solicitudId],
      );
      if (rows.isNotEmpty) {
        return rows.map((r) {
          final data = r['data_json'] as String;
          return DocumentoModel.fromMap(Map<String, dynamic>.from(jsonDecode(data)));
        }).toList();
      }
    } catch (_) {}
    // Fallback a la API (backend no guarda estado, asumir listo)
    try {
      final list = await _api.get<List>('/documentos/$solicitudId/documentos');
      if (list != null && list.isNotEmpty) {
        return list.map((item) {
          final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
          return DocumentoModel.fromMap({...map, 'estado': 'listo'});
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> insertar(DocumentoModel doc, {String? asesorId}) async {
    final db = await _cache.database;
    await db.insert(
      'documentos_cache',
      {
        'solicitud_id': doc.solicitudId,
        'documento_id': doc.id,
        'asesor_id': asesorId ?? doc.solicitudId,
        'data_json': jsonEncode(doc.toMap()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> actualizar(DocumentoModel doc, {String? asesorId}) async {
    final db = await _cache.database;
    await db.insert(
      'documentos_cache',
      {
        'solicitud_id': doc.solicitudId,
        'documento_id': doc.id,
        'asesor_id': asesorId ?? doc.solicitudId,
        'data_json': jsonEncode(doc.toMap()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> eliminar(String id) async {
    final db = await _cache.database;
    await db.delete(
      'documentos_cache',
      where: 'documento_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> eliminarPorSolicitud(String solicitudId) async {
    final db = await _cache.database;
    await db.delete(
      'documentos_cache',
      where: 'solicitud_id = ?',
      whereArgs: [solicitudId],
    );
  }
}
