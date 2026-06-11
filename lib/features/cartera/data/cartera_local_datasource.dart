import 'package:sqflite/sqflite.dart';
import '../domain/cartera_model.dart';
import '../../../core/storage/local_db.dart';

class CarteraLocalDatasource {
  final LocalDb _localDb;

  CarteraLocalDatasource(this._localDb);

  Future<Database> get database => _localDb.database;

  Future<void> saveCartera(List<CarteraModel> items) async {
    final db = await database;
    final batch = db.batch();

    for (final item in items) {
      batch.insert('cartera', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<CarteraModel>> getCartera() async {
    final db = await database;
    final maps = await db.query(
      'cartera',
      orderBy: 'orden_manual ASC, score_prioridad DESC',
    );
    return maps.map(CarteraModel.fromMap).toList();
  }

  Future<List<CarteraModel>> searchClientes(String query) async {
    final db = await database;
    final q = '%${query.trim()}%';
    final maps = await db.query(
      'cartera',
      where: 'nombre_cliente LIKE ? OR documento_cliente LIKE ?',
      whereArgs: [q, q],
      orderBy: 'orden_manual ASC, score_prioridad DESC',
    );
    return maps.map(CarteraModel.fromMap).toList();
  }

  Future<void> actualizarVisita({
    required String id,
    required String estadoVisita,
    String? resultadoVisita,
    String? observacion,
    String? timestamp,
    double? lat,
    double? lng,
  }) async {
    final db = await database;

    await db.update(
      'cartera',
      {
        'estado_visita': estadoVisita,
        'resultado_visita': resultadoVisita,
        'observacion_visita': observacion,
        'timestamp_visita': timestamp,
        'lat_visita': lat,
        'lng_visita': lng,
        'pendiente_sync': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await db.insert('visitas_pendientes', {
      'id': '${id}_${DateTime.now().millisecondsSinceEpoch}',
      'cartero_id': id,
      'resultado': estadoVisita,
      'observacion': observacion,
      'timestamp_visita': timestamp ?? DateTime.now().toIso8601String(),
      'lat': lat,
      'lng': lng,
      'pendiente_sync': 1,
    });
  }

  Future<void> actualizarOrdenManual(String id, int orden) async {
    final db = await database;
    await db.update(
      'cartera',
      {'orden_manual': orden},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getVisitasPendientes() async {
    final db = await database;
    return db.query(
      'visitas_pendientes',
      where: 'pendiente_sync = 1',
      orderBy: 'timestamp_visita ASC',
    );
  }

  Future<void> marcarSincronizadas(List<String> ids) async {
    final db = await database;
    final batch = db.batch();

    for (final id in ids) {
      batch.update(
        'visitas_pendientes',
        {'pendiente_sync': 0},
        where: 'cartero_id = ?',
        whereArgs: [id],
      );
    }

    batch.update(
      'cartera',
      {'pendiente_sync': 0},
      where: 'pendiente_sync = 1',
    );

    await batch.commit(noResult: true);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cartera');
    await db.delete('visitas_pendientes');
  }
}
