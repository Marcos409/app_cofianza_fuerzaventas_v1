import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/documentos/domain/documento_model.dart';
import '../../../features/solicitud/domain/solicitud_model.dart';
import '../data/transmision_repository.dart';
import '../domain/transmision_model.dart';

class TransmisionState {
  final PasoTransmision pasoActual;
  final bool isTransmitiendo;
  final List<PasoTransmision> pasos;
  final int documentosOk;
  final int documentosTotal;
  final String? expedienteGenerado;
  final List<String> erroresPreValidacion;
  final String? errorTransmision;
  final TransmisionEstado? estadoReanudacion;
  final String? estadoRealtime;

  const TransmisionState({
    this.pasoActual = PasoTransmision.pendiente,
    this.isTransmitiendo = false,
    this.pasos = PasoTransmision.values,
    this.documentosOk = 0,
    this.documentosTotal = 0,
    this.expedienteGenerado,
    this.erroresPreValidacion = const [],
    this.errorTransmision,
    this.estadoReanudacion,
    this.estadoRealtime,
  });

  TransmisionState copyWith({
    PasoTransmision? pasoActual,
    bool? isTransmitiendo,
    List<PasoTransmision>? pasos,
    int? documentosOk,
    int? documentosTotal,
    String? expedienteGenerado,
    List<String>? erroresPreValidacion,
    String? errorTransmision,
    TransmisionEstado? estadoReanudacion,
    String? estadoRealtime,
    bool clearErroresPre = false,
    bool clearError = false,
    bool clearRealtime = false,
  }) {
    return TransmisionState(
      pasoActual: pasoActual ?? this.pasoActual,
      isTransmitiendo: isTransmitiendo ?? this.isTransmitiendo,
      pasos: pasos ?? this.pasos,
      documentosOk: documentosOk ?? this.documentosOk,
      documentosTotal: documentosTotal ?? this.documentosTotal,
      expedienteGenerado: expedienteGenerado ?? this.expedienteGenerado,
      erroresPreValidacion:
          clearErroresPre ? [] : erroresPreValidacion ?? this.erroresPreValidacion,
      errorTransmision: clearError ? null : errorTransmision ?? this.errorTransmision,
      estadoReanudacion: estadoReanudacion ?? this.estadoReanudacion,
      estadoRealtime: clearRealtime ? null : estadoRealtime ?? this.estadoRealtime,
    );
  }

  EstadoItemTransmision estadoPaso(PasoTransmision paso) {
    if (paso.order < pasoActual.order) return EstadoItemTransmision.completado;
    if (paso == pasoActual) {
      return isTransmitiendo
          ? EstadoItemTransmision.enProceso
          : EstadoItemTransmision.pendiente;
    }
    return EstadoItemTransmision.pendiente;
  }
}

class TransmisionNotifier extends StateNotifier<TransmisionState> {
  final TransmisionRepository _repository;
  final String _solicitudId;
  final SolicitudModel _solicitud;
  final List<DocumentoModel> _documentos;
  final bool _tieneConsultaBuro;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  String? _estadoAnterior;

  TransmisionNotifier(
    this._repository, {
    required String solicitudId,
    required SolicitudModel solicitud,
    required List<DocumentoModel> documentos,
    required bool tieneConsultaBuro,
  })  : _solicitudId = solicitudId,
        _solicitud = solicitud,
        _documentos = documentos,
        _tieneConsultaBuro = tieneConsultaBuro,
        super(const TransmisionState());

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _suscribirRealtime() {
    _realtimeSubscription?.cancel();
    final stream = _repository.obtenerStreamEstado(_solicitudId);
    _realtimeSubscription = stream.listen((rows) {
      if (rows.isEmpty) return;
      final estado = rows.first['estado']?.toString();
      final expediente = rows.first['numero_expediente']?.toString();
      if (estado != null) {
        state = state.copyWith(estadoRealtime: estado);
        if (_estadoAnterior != null && _estadoAnterior != estado) {
          _notificarCambioEstado(estado, rows.first);
        }
        _estadoAnterior = estado;
      }
      if (expediente != null && state.expedienteGenerado == null) {
        state = state.copyWith(expedienteGenerado: expediente);
      }
    });
  }

  void _notificarCambioEstado(String estado, Map<String, dynamic> row) {
    final cliente = row['nombre_cliente']?.toString() ?? 'Cliente';
    final expediente = row['numero_expediente']?.toString() ?? '';
    final monto = double.tryParse(row['monto_aprobado']?.toString() ?? '');
    final fechaDesembolso = row['fecha_desembolso_estimada']?.toString();
    final motivoRechazo = row['motivo_rechazo']?.toString();
    final condicion = row['condicion_adicional']?.toString();

    String title;
    String body;

    switch (estado) {
      case 'recibido_comite':
        title = 'Solicitud recibida';
        body = '$cliente — Expediente $expediente en evaluación';
      case 'aprobado':
        title = 'Crédito aprobado';
        final montoStr = monto != null ? 'S/${monto.toStringAsFixed(0)}' : '';
        final fecha = fechaDesembolso != null ? ' Desembolso: $fechaDesembolso' : '';
        body = '$cliente — $montoStr aprobado.$fecha';
      case 'condicionado':
        title = 'Solicitud condicionada';
        body = '$cliente — ${condicion ?? 'Ver condiciones adicionales'}';
      case 'rechazado':
        title = 'Solicitud rechazada';
        body = '$cliente — ${motivoRechazo ?? 'Sin motivo especificado'}';
      case 'desembolsado':
        title = 'Crédito desembolsado';
        body = '$cliente puede retirar en agencia';
      default:
        return;
    }

    NotificationService.instance.showNotification(
      id: _solicitudId.hashCode,
      title: title,
      body: body,
    );
  }

  Future<void> verificarReanudacion() async {
    final estado = await _repository.cargarEstado(_solicitudId);
    if (estado != null) {
      state = state.copyWith(
        estadoReanudacion: estado,
        pasoActual: PasoTransmision.values.firstWhere(
          (p) => p.order == estado.pasoCompletado + 1,
          orElse: () => PasoTransmision.pendiente,
        ),
      );
    }
  }

  Future<List<String>> validarPreRequisitos() async {
    final errores = await _repository.validarPreRequisitos(
      solicitudId: _solicitudId,
      solicitud: _solicitud,
      documentos: _documentos,
    );
    state = state.copyWith(erroresPreValidacion: errores);
    return errores;
  }

  Future<void> iniciarEnvio() async {
    _suscribirRealtime();

    state = state.copyWith(
      isTransmitiendo: true,
      clearError: true,
      clearErroresPre: true,
    );

    try {
      await _repository.enviar(
        solicitudId: _solicitudId,
        solicitud: _solicitud,
        documentos: _documentos,
        onProgress: (paso, docsOk) {
          final pasoActual = PasoTransmision.values.firstWhere(
            (p) => p.order == paso,
          );
          state = state.copyWith(
            pasoActual: pasoActual,
            documentosOk: docsOk,
            isTransmitiendo: paso < 5,
          );
        },
      );

      state = state.copyWith(
        pasoActual: PasoTransmision.completado,
        isTransmitiendo: false,
        expedienteGenerado: _generarExpedienteFallback(),
      );
    } catch (e) {
      state = state.copyWith(
        isTransmitiendo: false,
        errorTransmision: e.toString(),
      );
    }
  }

  Future<void> reanudarEnvio() async {
    state = state.copyWith(clearError: true);
    await iniciarEnvio();
  }

  String _generarExpedienteFallback() {
    final now = DateTime.now();
    final sufijo = _solicitudId.split('-').last;
    return 'EXP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$sufijo';
  }
}
