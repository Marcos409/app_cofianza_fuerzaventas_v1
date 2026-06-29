import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../solicitud/domain/solicitud_model.dart';
import '../domain/nota_interna_model.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';

class EstadoRepository {
  final LocalCache _cache = LocalCache.instance;
  final ApiClient _api = ApiClient.instance;

  Future<void> sincronizarAsignadas(String asesorId) async {
    try {
      final list = await _api.get<List>('/solicitudes/asignadas', params: {'asesor_id': asesorId});
      if (list == null) return;
      await _cache.cacheList('solicitudes_cache', asesorId, list, 'id');
    } catch (e) {
      print('[EstadoRepository] Error sincronizando asignadas: $e');
      print('[EstadoRepository] Stack: ${StackTrace.current}');
    }
  }

  Future<List<SolicitudModel>> listarPorAsesor(String asesorId) async {
    print('[EstadoRepository] listarPorAsesor asesorId=$asesorId');
    try {
      final list = await _api.get<List>('/solicitudes', params: {'asesor_id': asesorId});
      if (list != null) {
        print('[EstadoRepository] listarPorAsesor => ${list.length} desde API');
        return list.map((item) {
          final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
          return SolicitudModel.fromJson(map);
        }).toList();
      }
    } catch (e) {
      print('[EstadoRepository] Error listarPorAsesor desde API: $e');
    }
    try {
      final cached = await _cache.getCachedList('solicitudes_cache', asesorId);
      print('[EstadoRepository] listarPorAsesor => ${cached.length} desde cache');
      return cached.map((item) => SolicitudModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      print('[EstadoRepository] Error listarPorAsesor desde cache: $e');
      return [];
    }
  }

  Stream<List<SolicitudModel>> streamPorAsesor(String asesorId) {
    final controller = StreamController<List<SolicitudModel>>();
    listarPorAsesor(asesorId).then((list) {
      controller.add(list);
    });
    return controller.stream;
  }

  Future<List<NotaInterna>> listarNotas(String solicitudId) async {
    try {
      final db = await _cache.database;
      await _ensureNotasTable(db);
      final rows = await db.query(
        'solicitudes_notas_internas',
        where: 'solicitud_id = ?',
        whereArgs: [solicitudId],
        orderBy: 'created_at DESC',
      );
      return rows.map((item) => NotaInterna.fromMap(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> agregarNota(NotaInterna nota) async {
    try {
      final db = await _cache.database;
      await _ensureNotasTable(db);
      await db.insert('solicitudes_notas_internas', nota.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<void> _ensureNotasTable(db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solicitudes_notas_internas (
        id TEXT PRIMARY KEY,
        solicitud_id TEXT NOT NULL,
        contenido TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
