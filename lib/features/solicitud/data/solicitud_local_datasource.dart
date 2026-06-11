import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../domain/solicitud_model.dart';
import '../../../core/storage/local_db.dart';

class SolicitudLocalDatasource {
  final LocalDb _localDb;

  SolicitudLocalDatasource(this._localDb);

  Future<Database> get _database => _localDb.database;

  Future<void> saveBorrador(SolicitudModel solicitud) async {
    final db = await _database;
    await db.insert(
      'solicitudes_borrador',
      solicitud.toBorradorMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SolicitudModel>> getBorradores() async {
    final db = await _database;
    final maps = await db.query(
      'solicitudes_borrador',
      orderBy: 'updated_at DESC',
    );
    return maps.map(SolicitudModel.fromBorradorMap).toList();
  }

  Future<void> deleteBorrador(String id) async {
    final db = await _database;
    await db.delete('solicitudes_borrador', where: 'id = ?', whereArgs: [id]);
  }

  Future<SolicitudModel?> getBorrador(String id) async {
    final db = await _database;
    final maps = await db.query(
      'solicitudes_borrador',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SolicitudModel.fromBorradorMap(maps.first);
  }

  Future<void> saveEnviada(SolicitudModel solicitud) async {
    final db = await _database;
    await db.insert(
      'solicitudes_enviadas',
      {
        'id': solicitud.id,
        'asesor_id': solicitud.asesorId,
        'datos_json': jsonEncode(solicitud.toJson()),
        'estado': solicitud.estado.name,
        'pendiente_sync': solicitud.pendienteSync ? 1 : 0,
        'created_at': solicitud.fechaCreacion?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SolicitudModel?> getEnviada(String id) async {
    final db = await _database;
    final maps = await db.query(
      'solicitudes_enviadas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    final datos = m['datos_json']?.toString();
    if (datos != null && datos.isNotEmpty) {
      return SolicitudModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(datos)));
    }
    return SolicitudModel(
      id: m['id']?.toString() ?? '',
      asesorId: m['asesor_id']?.toString() ?? '',
      estado: EstadoSolicitud.fromString(m['estado']?.toString() ?? ''),
      fechaCreacion: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : null,
    );
  }

  Future<List<SolicitudModel>> getSolicitudesDelMes(String asesorId) async {
    final db = await _database;
    final inicioMes = DateTime(DateTime.now().year, DateTime.now().month, 1)
        .toIso8601String();
    final maps = await db.query(
      'solicitudes_enviadas',
      where: 'asesor_id = ? AND created_at >= ?',
      whereArgs: [asesorId, inicioMes],
      orderBy: 'created_at DESC',
    );

    return maps.map((m) {
      final datos = m['datos_json']?.toString();
      if (datos != null && datos.isNotEmpty) {
        return SolicitudModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(datos)));
      }
      return SolicitudModel(
        id: m['id']?.toString() ?? '',
        asesorId: m['asesor_id']?.toString() ?? '',
        estado: EstadoSolicitud.fromString(m['estado']?.toString() ?? ''),
        fechaCreacion: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'].toString())
            : null,
      );
    }).toList();
  }
}
