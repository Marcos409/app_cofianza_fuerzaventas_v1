import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      }
      if (expediente != null && state.expedienteGenerado == null) {
        state = state.copyWith(expedienteGenerado: expediente);
      }
    });
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
      tieneConsultaBuro: _tieneConsultaBuro,
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
