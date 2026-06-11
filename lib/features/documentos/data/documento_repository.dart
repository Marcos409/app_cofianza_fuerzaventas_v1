import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/network_monitor.dart';
import '../../../shared/services/image_service.dart';
import '../domain/documento_model.dart';
import 'documento_local_datasource.dart';

class DocumentoRepository {
  final DocumentoLocalDatasource _local = DocumentoLocalDatasource();
  final SupabaseClient _supabase;
  final NetworkMonitor _network;

  DocumentoRepository(this._supabase, this._network);

  Future<List<DocumentoModel>> listarDocumentos(String solicitudId) {
    return _local.listar(solicitudId);
  }

  Future<DocumentoModel> capturarYSubir({
    required String solicitudId,
    required TipoDocumento tipo,
    required String imagePath,
  }) async {
    final id = const Uuid().v4();
    final rawBytes = await ImageService.capturarDesdeArchivo(imagePath);

    final nitidezScore = ImageService.calcularNitidez(rawBytes);

    final docModel = DocumentoModel(
      id: id,
      solicitudId: solicitudId,
      tipo: tipo,
      estado: EstadoDocumento.subiendo,
      nitidezScore: nitidezScore,
      localPath: imagePath,
      createdAt: DateTime.now(),
    );
    await _local.insertar(docModel);

    final comprimida = await ImageService.comprimir(rawBytes);
    final subidaOk = await _subirStorage(solicitudId, tipo, comprimida);
    final docFinal = docModel.copyWith(
      estado: subidaOk ? EstadoDocumento.listo : EstadoDocumento.error,
      tamanioKb: comprimida.length ~/ 1024,
      storageUrl: subidaOk
          ? 'documentos/solicitudes/$solicitudId/${tipo.storageName}.jpg'
          : null,
    );
    await _local.actualizar(docFinal);
    return docFinal;
  }

  Future<bool> _subirStorage(
    String solicitudId,
    TipoDocumento tipo,
    Uint8List bytes,
  ) async {
    final connected = await _network.isConnected;
    if (!connected) return false;

    const maxRetries = 3;
    for (var i = 0; i < maxRetries; i++) {
      try {
        await _supabase.storage.from('documentos').uploadBinary(
              'solicitudes/$solicitudId/${tipo.storageName}.jpg',
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        return true;
      } on StorageException {
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 100 * pow(2, i).toInt()));
        }
      }
    }
    return false;
  }

  Future<bool> eliminar(DocumentoModel doc) async {
    try {
      if (doc.storageUrl != null) {
        try {
          await _supabase.storage
              .from('documentos')
              .remove([doc.storageUrl!]);
        } catch (_) {}
      }
      await _local.eliminar(doc.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> eliminarPorSolicitud(String solicitudId) async {
    final docs = await _local.listar(solicitudId);
    for (final doc in docs) {
      await eliminar(doc);
    }
  }
}
