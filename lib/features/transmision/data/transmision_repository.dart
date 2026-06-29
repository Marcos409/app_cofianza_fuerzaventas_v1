import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_monitor.dart';
import '../../../features/documentos/domain/documento_model.dart';
import '../../../features/solicitud/domain/solicitud_model.dart';
import '../domain/transmision_model.dart';

class TransmisionRepository {
  final NetworkMonitor _network;
  final LocalCache _cache;
  final ApiClient _api = ApiClient.instance;

  TransmisionRepository(this._network, this._cache);

  Future<TransmisionEstado?> cargarEstado(String solicitudId) async {
    final cached = await _cache.getCached('solicitudes_cache', solicitudId);
    if (cached == null) return null;
    return TransmisionEstado.fromMap(Map<String, dynamic>.from(cached));
  }

  Future<void> guardarEstado(TransmisionEstado estado) async {
    await _cache.cacheJson(
      'solicitudes_cache',
      estado.solicitudId,
      '',
      estado.toMap(),
    );
  }

  Future<void> limpiarEstado(String solicitudId) async {
    await _cache.deleteCached('solicitudes_cache', solicitudId);
  }

  Future<List<String>> validarPreRequisitos({
    required String solicitudId,
    required SolicitudModel solicitud,
    required List<DocumentoModel> documentos,
  }) async {
    final errores = <String>[];

    if (solicitud.estado != EstadoSolicitud.enProceso &&
        solicitud.estado != EstadoSolicitud.enviado) {
      errores.add('La solicitud debe estar en estado "en proceso"');
    }

    final obligatorios = TipoDocumento.values.where((t) => t.esObligatorio);
    for (final tipo in obligatorios) {
      final doc = documentos.cast<DocumentoModel?>().firstWhere(
            (d) => d?.tipo == tipo && d?.estado == EstadoDocumento.listo,
            orElse: () => null,
          );
      if (doc == null) {
        errores.add('Falta ${tipo.label}');
      }
    }

    return errores;
  }

  Future<void> enviar({
    required String solicitudId,
    required SolicitudModel solicitud,
    required List<DocumentoModel> documentos,
    required void Function(int paso, int docsOk) onProgress,
  }) async {
    onProgress(1, 0);

    // Step 1: asegurar que la solicitud existe en el backend
    try {
      final garantiaMap = {
        TipoGarantia.sinGarantia: 'sin_garantia',
        TipoGarantia.aval: 'aval',
        TipoGarantia.hipotecaria: 'hipotecaria',
        TipoGarantia.prendaria: 'prendaria',
      };
      final payload = {
        'id': solicitud.id,
        'numero_documento': solicitud.solicitante.documento,
        'nombres': solicitud.solicitante.nombres,
        'apellidos': solicitud.solicitante.apellidos,
        'telefono': solicitud.solicitante.telefono,
        'email': solicitud.solicitante.email,
        'fecha_nacimiento': solicitud.solicitante.fechaNacimiento
            ?.toIso8601String(),
        'estado_civil': solicitud.solicitante.estadoCivil,
        'grado_instruccion': solicitud.solicitante.gradoInstruccion,
        'tipo_negocio': solicitud.negocio.tipoNegocio,
        'nombre_negocio': solicitud.negocio.nombreNegocio,
        'direccion_negocio': solicitud.negocio.direccionNegocio,
        'antiguedad_anios': solicitud.negocio.antiguedadAnios,
        'antiguedad_meses': solicitud.negocio.antiguedadMeses,
        'ingresos_estimados': solicitud.negocio.ingresosMensuales,
        'gastos_mensuales': solicitud.negocio.gastosMensuales,
        'patrimonio': solicitud.negocio.patrimonio,
        'destino_credito': solicitud.negocio.destinoCredito,
        'actividad_economica': solicitud.negocio.actividadEconomica,
        'monto_solicitado': solicitud.credito.montoSolicitado,
        'plazo_meses': solicitud.credito.plazoMeses,
        'moneda': solicitud.credito.moneda,
        'tipo_cuota': solicitud.credito.tipoCuota.name,
        'garantia':
            garantiaMap[solicitud.credito.garantia] ?? 'sin_garantia',
        'cuota_estimada': solicitud.cuotaEstimada,
        'tea_referencial': solicitud.teaReferencial,
        'firma_cliente_base64': solicitud.firmaBase64,
      };
      final response = await _api.dio.post('/solicitudes', data: payload);
      final backendExpediente =
          response.data?['numero_expediente']?.toString();
      if (backendExpediente != null && backendExpediente.isNotEmpty) {
        final updated = solicitud.copyWith(
          numeroExpediente: backendExpediente,
        );
        await _cache.cacheJson('solicitudes_cache', solicitudId, '',
            updated.toJson());
      }
    } on DioException catch (_) {}

    // Step 2: obtener cliente_id desde el backend
    String clienteId = '';
    try {
      final solicitudData = await _api
          .get<Map<String, dynamic>>('/solicitudes/$solicitudId');
      clienteId = solicitudData['cliente_id']?.toString() ?? '';
    } catch (_) {}

    try {
      await _api.dio.post('/solicitudes/$solicitudId/enviar-comite');
    } on DioException catch (e) {
      print('[TransmisionRepository] Error llamando enviar-comite: $e');
      throw Exception(
          'Error al enviar al comité: ${e.response?.data ?? e.message}');
    }

    final updated = solicitud.copyWith(
      estado: EstadoSolicitud.recibidoComite,
      fechaActualizacion: DateTime.now(),
    );

    onProgress(3, documentos.length);

    await _cache.cacheJson(
        'solicitudes_cache', solicitudId, '', updated.toJson());

    if (clienteId.isNotEmpty) {
      try {
        await _api.post('/notificaciones', data: {
          'destinatario_tipo': 'cliente',
          'cliente_id': clienteId,
          'titulo': 'Solicitud recibida en comité',
          'cuerpo':
              'Su expediente ha sido recibido por el comité de evaluación.',
          'tipo': 'recibido_comite',
        });
      } catch (_) {}
    }

    onProgress(4, documentos.length);
  }

  String _generarExpediente(String solicitudId) {
    final now = DateTime.now();
    final sufijo = solicitudId.split('-').last;
    return 'EXP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$sufijo';
  }

  Stream<List<Map<String, dynamic>>> obtenerStreamEstado(
      String solicitudId) {
    return Stream.value([]);
  }
}
