import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/network/network_monitor.dart';
import '../../../features/documentos/domain/documento_model.dart';
import '../../../features/solicitud/domain/solicitud_model.dart';
import '../../../shared/services/image_service.dart';
import '../domain/transmision_model.dart';

class TransmisionRepository {
  final SupabaseClient _supabase;
  final NetworkMonitor _network;
  final LocalDb _localDb;

  TransmisionRepository(this._supabase, this._network, this._localDb);

  Future<TransmisionEstado?> cargarEstado(String solicitudId) async {
    final db = await _localDb.database;
    final rows = await db.query(
      'transmision_estado',
      where: 'solicitud_id = ?',
      whereArgs: [solicitudId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TransmisionEstado.fromMap(rows.first);
  }

  Future<void> guardarEstado(TransmisionEstado estado) async {
    final db = await _localDb.database;
    await db.insert(
      'transmision_estado',
      estado.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> limpiarEstado(String solicitudId) async {
    final db = await _localDb.database;
    await db.delete(
      'transmision_estado',
      where: 'solicitud_id = ?',
      whereArgs: [solicitudId],
    );
  }

  Future<List<String>> validarPreRequisitos({
    required String solicitudId,
    required SolicitudModel solicitud,
    required List<DocumentoModel> documentos,
    required bool tieneConsultaBuro,
  }) async {
    final errores = <String>[];

    if (solicitud.solicitante.nombres.isEmpty ||
        solicitud.solicitante.apellidos.isEmpty ||
        solicitud.solicitante.documento.isEmpty) {
      errores.add('Faltan datos del solicitante (paso 1)');
    }

    if (solicitud.negocio.tipoNegocio.isEmpty ||
        solicitud.negocio.ingresosMensuales <= 0) {
      errores.add('Faltan datos del negocio (paso 2)');
    }

    if (solicitud.credito.montoSolicitado <= 0 ||
        solicitud.credito.plazoMeses <= 0) {
      errores.add('Faltan condiciones del crédito (paso 3)');
    }

    if (solicitud.firmaBase64.isEmpty) {
      errores.add('Falta la firma del cliente');
    }

    final obligatorios = TipoDocumento.values.where((t) => t.esObligatorio);
    for (final tipo in obligatorios) {
      final doc = documentos.cast<DocumentoModel?>().firstWhere(
            (d) => d?.tipo == tipo && d?.estado == EstadoDocumento.listo,
            orElse: () => null,
          );
      if (doc == null) {
        errores.add('Falta documento obligatorio: ${tipo.label}');
      }
    }

    if (!tieneConsultaBuro) {
      errores.add('Falta consulta de buró o justificación de omisión');
    }

    return errores;
  }

  Future<void> enviar({
    required String solicitudId,
    required SolicitudModel solicitud,
    required List<DocumentoModel> documentos,
    required void Function(int paso, int docsOk) onProgress,
  }) async {
    final connected = await _network.isConnected;
    if (!connected) {
      throw Exception('No hay conexión a internet');
    }

    onProgress(1, 0);

    // Paso 1: Validar datos
    await guardarEstado(TransmisionEstado(
      solicitudId: solicitudId,
      pasoCompletado: 1,
      updatedAt: DateTime.now(),
    ));

    final docsParaSubir =
        documentos.where((d) => d.estado == EstadoDocumento.listo).toList();
    final subidos = <String>[];

    // Paso 2: Subir documentos reales en paralelo
    onProgress(2, 0);
    final uploadFutures = docsParaSubir.map((doc) async {
      try {
        await _subirDocumentoReal(solicitudId, doc);
      } catch (e) {
        throw Exception('Error al subir ${doc.tipo.label}: $e');
      }
    });
    await Future.wait(uploadFutures);
    subidos.addAll(docsParaSubir.map((d) => d.tipo.storageName));
    await guardarEstado(TransmisionEstado(
      solicitudId: solicitudId,
      pasoCompletado: 2,
      documentosSubidos: subidos,
      updatedAt: DateTime.now(),
    ));
    onProgress(2, subidos.length);

    // Paso 3: Llamar Edge Function para registrar en sistema central
    onProgress(3, docsParaSubir.length);
    String? expediente;
    try {
      final response = await _supabase.functions.invoke(
        'registrar-solicitud',
        body: {
          'solicitud_id': solicitudId,
          'solicitud': solicitud.toJson(),
          'documentos_subidos': subidos,
          'fecha_envio': DateTime.now().toIso8601String(),
        },
      );
      if (response.data is Map) {
        expediente = (response.data as Map)['expediente']?.toString();
      }
    } catch (_) {
      // Fallback: actualizar directamente en la tabla
      await _supabase.from('solicitudes_credito').update({
        'estado': 'enviado',
        'fecha_envio': DateTime.now().toIso8601String(),
      }).eq('id', solicitudId);
    }
    await guardarEstado(TransmisionEstado(
      solicitudId: solicitudId,
      pasoCompletado: 3,
      documentosSubidos: subidos,
      updatedAt: DateTime.now(),
    ));

    // Paso 4: Asignar expediente
    onProgress(4, docsParaSubir.length);
    expediente ??= _generarExpediente(solicitudId);
    try {
      await _supabase.from('solicitudes_credito').update({
        'numero_expediente': expediente,
      }).eq('id', solicitudId);
    } catch (_) {}
    await guardarEstado(TransmisionEstado(
      solicitudId: solicitudId,
      pasoCompletado: 4,
      documentosSubidos: subidos,
      expedienteGenerado: expediente,
      updatedAt: DateTime.now(),
    ));

    // Paso 5: Completado
    onProgress(5, docsParaSubir.length);
    await limpiarEstado(solicitudId);
  }

  Future<void> _subirDocumentoReal(
    String solicitudId,
    DocumentoModel doc,
  ) async {
    Uint8List bytes;
    if (doc.localPath != null && File(doc.localPath!).existsSync()) {
      bytes = await ImageService.capturarDesdeArchivo(doc.localPath!);
      bytes = await ImageService.comprimir(bytes);
    } else {
      throw Exception('Archivo no encontrado en: ${doc.localPath}');
    }

    final contentType = doc.tipo.storageName.endsWith('.pdf')
        ? 'application/pdf'
        : 'image/jpeg';

    await _supabase.storage.from('documentos').uploadBinary(
          'solicitudes/$solicitudId/${doc.tipo.storageName}',
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
  }

  String _generarExpediente(String solicitudId) {
    final now = DateTime.now();
    final sufijo = solicitudId.split('-').last;
    return 'EXP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$sufijo';
  }

  Stream<List<Map<String, dynamic>>> obtenerStreamEstado(String solicitudId) {
    return _supabase
        .from('solicitudes_credito')
        .stream(primaryKey: ['id'])
        .eq('id', solicitudId)
        .map((list) => list.map((j) => Map<String, dynamic>.from(j)).toList());
  }
}
