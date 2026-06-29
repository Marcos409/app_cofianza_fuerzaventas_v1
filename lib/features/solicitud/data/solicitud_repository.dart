import 'dart:async';
import 'package:dio/dio.dart';
import 'solicitud_local_datasource.dart';
import '../domain/solicitud_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_monitor.dart';

class SolicitudRepository {
  final SolicitudLocalDatasource _localDatasource;
  final NetworkMonitor _networkMonitor;
  final ApiClient _api = ApiClient.instance;

  SolicitudRepository(
    this._localDatasource,
    this._networkMonitor,
  );

  Future<void> saveBorrador(SolicitudModel solicitud) {
    return _localDatasource.saveBorrador(solicitud);
  }

  Future<List<SolicitudModel>> getBorradores() {
    return _localDatasource.getBorradores();
  }

  Future<void> deleteBorrador(String id) {
    return _localDatasource.deleteBorrador(id);
  }

  Future<SolicitudModel?> getBorrador(String id) {
    return _localDatasource.getBorrador(id);
  }

  Future<String> enviarSolicitud(SolicitudModel solicitud) async {
    final enviada = solicitud.copyWith(
      estado: EstadoSolicitud.enviado,
      numeroExpediente: _generarExpedienteLocal(),
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );

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
        'fecha_nacimiento': solicitud.solicitante.fechaNacimiento?.toIso8601String(),
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
        'garantia': garantiaMap[solicitud.credito.garantia] ?? 'sin_garantia',
        'cuota_estimada': solicitud.cuotaEstimada,
        'tea_referencial': solicitud.teaReferencial,
        'firma_cliente_base64': solicitud.firmaBase64,
      };
      final response = await _api.dio.post('/solicitudes', data: payload);
      final backendExpediente = response.data?['numero_expediente']?.toString();
      if (backendExpediente != null && backendExpediente.isNotEmpty) {
        return backendExpediente;
      }
    } on DioException catch (e) {
      print('[SolicitudRepository] Error creando solicitud en backend: $e');
    }

    return enviada.numeroExpediente;
  }

  Future<void> sincronizarAsignadas(String asesorId) async {
    try {
      final list = await _api.get<List>('/solicitudes/asignadas', params: {'asesor_id': asesorId});
      if (list == null) return;
      for (final item in list) {
        final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
        final sol = SolicitudModel.fromJson(map);
        await _localDatasource.saveBorrador(sol);
      }
    } catch (e) {
      print('[SolicitudRepository] Error sincronizando asignadas: $e');
    }
  }

  Future<List<SolicitudModel>> getSolicitudesDelMes(String asesorId) async {
    try {
      final list = await _api.get<List>('/solicitudes', params: {'asesor_id': asesorId});
      if (list == null) return [];
      return list.map((item) {
        final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
        return SolicitudModel.fromJson(map);
      }).toList();
    } catch (e) {
      print('[SolicitudRepository] Error obteniendo solicitudes: $e');
      return [];
    }
  }

  String _generarExpedienteLocal() {
    final now = DateTime.now();
    final rand = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'EXP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rand';
  }
}
