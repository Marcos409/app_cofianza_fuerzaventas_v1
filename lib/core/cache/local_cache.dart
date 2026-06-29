import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalCache {
  static final LocalCache instance = LocalCache._();
  LocalCache._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'confianza_fdv_cache.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cartera_cache (
        id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ficha_cache (
        cliente_id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solicitudes_cache (
        id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS creditos_cache (
        cliente_id TEXT NOT NULL,
        credito_id TEXT NOT NULL,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (cliente_id, credito_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pagos_cache (
        cliente_id TEXT NOT NULL,
        mes INTEGER NOT NULL,
        anio INTEGER NOT NULL,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (cliente_id, anio, mes)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ofertas_cache (
        cliente_id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS campanas_cache (
        id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documentos_cache (
        solicitud_id TEXT NOT NULL,
        documento_id TEXT NOT NULL,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (solicitud_id, documento_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS buro_cache (
        cliente_id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notificaciones_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        leida INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entidad TEXT NOT NULL,
        entidad_id TEXT NOT NULL,
        operacion TEXT NOT NULL,
        payload TEXT,
        created_at INTEGER NOT NULL,
        estado TEXT DEFAULT 'pendiente'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solicitudes_borrador_cache (
        id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mora_cache (
        id TEXT PRIMARY KEY,
        asesor_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> clearAll() async {
    final db = await database;
    final tables = [
      'cartera_cache', 'ficha_cache', 'solicitudes_cache', 'creditos_cache',
      'pagos_cache', 'ofertas_cache', 'campanas_cache', 'documentos_cache',
      'buro_cache', 'notificaciones_cache', 'sync_queue',
      'solicitudes_borrador_cache', 'mora_cache',
    ];
    for (final t in tables) {
      await db.delete(t);
    }
  }

  Future<void> cacheList(String table, String asesorId, List<dynamic> items, String idField) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in items) {
      final id = item[idField]?.toString() ?? '';
      if (id.isEmpty) continue;
      batch.insert(
        table,
        {
          'id': id,
          'asesor_id': asesorId,
          'data_json': jsonEncode(item),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheJson(String table, String id, String asesorId, dynamic data) async {
    final db = await database;
    await db.insert(
      table,
      {
        'id': id,
        'asesor_id': asesorId,
        'data_json': jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<dynamic> getCached(String table, String id) async {
    final db = await database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data_json'] as String);
  }

  Future<List<dynamic>> getCachedList(String table, String asesorId) async {
    final db = await database;
    final rows = await db.query(table, where: 'asesor_id = ?', whereArgs: [asesorId]);
    return rows.map((r) => jsonDecode(r['data_json'] as String)).toList();
  }

  Future<void> deleteCached(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTable(String table, String asesorId) async {
    final db = await database;
    await db.delete(table, where: 'asesor_id = ?', whereArgs: [asesorId]);
  }

  Future<void> enqueueSync(String entidad, String entidadId, String operacion, dynamic payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'entidad': entidad,
      'entidad_id': entidadId,
      'operacion': operacion,
      'payload': payload != null ? jsonEncode(payload) : null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'estado': 'pendiente',
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await database;
    return db.query('sync_queue', where: 'estado = ?', whereArgs: ['pendiente'], orderBy: 'created_at ASC');
  }

  Future<void> markSynced(int syncId) async {
    final db = await database;
    await db.update('sync_queue', {'estado': 'sincronizado'}, where: 'id = ?', whereArgs: [syncId]);
  }

  Future<void> markSyncError(int syncId) async {
    final db = await database;
    await db.update('sync_queue', {'estado': 'error'}, where: 'id = ?', whereArgs: [syncId]);
  }
}
