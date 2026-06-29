import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_monitor.dart';
import '../../../shared/services/image_service.dart';
import '../domain/documento_model.dart';
import 'documento_local_datasource.dart';

class DocumentoRepository {
  final DocumentoLocalDatasource _local = DocumentoLocalDatasource();
  final NetworkMonitor _network;
  final ApiClient _api = ApiClient.instance;

  DocumentoRepository(this._network);

  Future<List<DocumentoModel>> listarDocumentos(String solicitudId) async {
    // Local cache first (tiene el estado real)
    final localDocs = await _local.listar(solicitudId);
    if (localDocs.isNotEmpty) return localDocs;
    // Fallback a la API
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

  Future<DocumentoModel> capturarYSubir({
    required String solicitudId,
    required TipoDocumento tipo,
    required String imagePath,
  }) async {
    final id = const Uuid().v4();
    final createdAt = DateTime.now();

    String localPath = imagePath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/documentos/$solicitudId');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }
      final persistentPath = '${docsDir.path}/${tipo.storageName}.jpg';
      await File(imagePath).copy(persistentPath);
      localPath = persistentPath;
    } catch (_) {
      print('[DocumentoRepository] No se pudo copiar imagen, usando path original');
    }

    try {
      final rawBytes = await ImageService.capturarDesdeArchivo(localPath);
      final nitidezScore = ImageService.calcularNitidez(rawBytes);
      final comprimida = await ImageService.comprimir(rawBytes);

      final docModel = DocumentoModel(
        id: id,
        solicitudId: solicitudId,
        tipo: tipo,
        estado: EstadoDocumento.listo,
        nitidezScore: nitidezScore,
        localPath: localPath,
        tamanioKb: comprimida.length ~/ 1024,
        storageUrl: 'uploads/documentos/$solicitudId/${tipo.storageName}.jpg',
        createdAt: createdAt,
      );

      await _local.insertar(docModel);
      _subirStorage(solicitudId, tipo, comprimida, nitidezScore);

      return docModel;
    } catch (e) {
      print('[DocumentoRepository] Error capturando documento: $e');
      final docModel = DocumentoModel(
        id: id,
        solicitudId: solicitudId,
        tipo: tipo,
        estado: EstadoDocumento.listo,
        localPath: localPath,
        nitidezScore: 0,
        tamanioKb: 0,
        storageUrl: 'uploads/documentos/$solicitudId/${tipo.storageName}.jpg',
        createdAt: createdAt,
      );
      try {
        await _local.insertar(docModel);
      } catch (_) {}
      return docModel;
    }
  }

  Future<void> _subirStorage(
    String solicitudId,
    TipoDocumento tipo,
    Uint8List bytes,
    double? nitidezScore,
  ) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/${tipo.storageName}.jpg');
      await tempFile.writeAsBytes(bytes);

      final formData = FormData.fromMap({
        'tipo_documento': tipo.storageName,
        'nitidez_score': nitidezScore?.toStringAsFixed(2),
        'archivo': await MultipartFile.fromFile(
          tempFile.path,
          filename: '${tipo.storageName}.jpg',
        ),
      });

      await _api.dio.post(
        '/documentos/$solicitudId/upload',
        data: formData,
      );

      await tempFile.delete();
    } catch (e) {
      print('[DocumentoRepository] Error subiendo a backend: $e');
    }
  }

  Future<bool> eliminar(DocumentoModel doc) async {
    try {
      await _api.delete('/documentos/${doc.solicitudId}/${doc.id}');
      await _local.eliminar(doc.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> eliminarPorSolicitud(String solicitudId) async {
    try {
      await _api.delete('/documentos/solicitud/$solicitudId');
    } catch (_) {}
    await _local.eliminarPorSolicitud(solicitudId);
  }
}
