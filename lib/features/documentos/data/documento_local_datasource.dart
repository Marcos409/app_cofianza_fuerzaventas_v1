import 'package:sqflite/sqflite.dart';
import '../../../core/storage/local_db.dart';
import '../domain/documento_model.dart';

class DocumentoLocalDatasource {
  Future<Database> get _db => LocalDb.instance.database;

  Future<List<DocumentoModel>> listar(String solicitudId) async {
    final db = await _db;
    final rows = await db.query(
      'solicitudes_documentos',
      where: 'solicitud_id = ?',
      whereArgs: [solicitudId],
    );
    return rows.map((r) => DocumentoModel.fromMap(r)).toList();
  }

  Future<void> insertar(DocumentoModel doc) async {
    final db = await _db;
    await db.insert(
      'solicitudes_documentos',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> actualizar(DocumentoModel doc) async {
    final db = await _db;
    await db.update(
      'solicitudes_documentos',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<void> eliminar(String id) async {
    final db = await _db;
    await db.delete('solicitudes_documentos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> eliminarPorSolicitud(String solicitudId) async {
    final db = await _db;
    await db.delete(
      'solicitudes_documentos',
      where: 'solicitud_id = ?',
      whereArgs: [solicitudId],
    );
  }
}
