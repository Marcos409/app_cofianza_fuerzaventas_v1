import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/solicitud_repository.dart';
import '../domain/solicitud_model.dart';
import '../../../shared/utils/calculadora_credito.dart';

const double teaReferencialDefault = 0.25;

class SolicitudFormState {
  final int pasoActual;
  final DatosSolicitante solicitante;
  final DatosNegocio negocio;
  final DatosCredito credito;
  final bool datosVeraces;
  final String firmaBase64;
  final bool isSubmitting;
  final String? errorMessage;
  final String? expedienteGenerado;
  final String? camposError;
  final bool isEditMode;
  final String? solicitudId;

  const SolicitudFormState({
    this.pasoActual = 0,
    this.solicitante = const DatosSolicitante(),
    this.negocio = const DatosNegocio(),
    this.credito = const DatosCredito(),
    this.datosVeraces = false,
    this.firmaBase64 = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.expedienteGenerado,
    this.camposError,
    this.isEditMode = false,
    this.solicitudId,
  });

  SolicitudFormState copyWith({
    int? pasoActual,
    DatosSolicitante? solicitante,
    DatosNegocio? negocio,
    DatosCredito? credito,
    bool? datosVeraces,
    String? firmaBase64,
    bool? isSubmitting,
    String? errorMessage,
    String? expedienteGenerado,
    String? camposError,
    bool? isEditMode,
    String? solicitudId,
  }) {
    return SolicitudFormState(
      pasoActual: pasoActual ?? this.pasoActual,
      solicitante: solicitante ?? this.solicitante,
      negocio: negocio ?? this.negocio,
      credito: credito ?? this.credito,
      datosVeraces: datosVeraces ?? this.datosVeraces,
      firmaBase64: firmaBase64 ?? this.firmaBase64,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      expedienteGenerado: expedienteGenerado ?? this.expedienteGenerado,
      camposError: camposError,
      isEditMode: isEditMode ?? this.isEditMode,
      solicitudId: solicitudId ?? this.solicitudId,
    );
  }

  bool get paso1Valido {
    final s = solicitante;
    final emailValido = s.email.isEmpty || 
        RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(s.email);
    return s.nombres.trim().isNotEmpty &&
        s.apellidos.trim().isNotEmpty &&
        s.documento.length == 8 &&
        int.tryParse(s.documento) != null &&
        s.fechaNacimiento != null &&
        _edad(s.fechaNacimiento!) >= 18 &&
        _edad(s.fechaNacimiento!) <= 75 &&
        s.estadoCivil.isNotEmpty &&
        s.telefono.length == 9 &&
        int.tryParse(s.telefono) != null &&
        emailValido;
  }

  bool get paso2Valido {
    final n = negocio;
    return n.tipoNegocio.isNotEmpty &&
        n.nombreNegocio.trim().isNotEmpty &&
        n.direccionNegocio.trim().isNotEmpty &&
        (n.antiguedadAnios * 12 + n.antiguedadMeses) >= 6 &&
        n.ingresosMensuales > 0 &&
        n.gastosMensuales >= 0 &&
        n.destinoCredito.trim().isNotEmpty &&
        n.destinoCredito.length <= 500;
  }

  bool get paso3Valido {
    final c = credito;
    return c.montoSolicitado >= 500 &&
        c.montoSolicitado <= 150000 &&
        c.plazoMeses > 0;
  }

  bool get paso4Valido => datosVeraces && firmaBase64.isNotEmpty;

  double get cuotaEstimada {
    if (credito.montoSolicitado <= 0 || credito.plazoMeses <= 0) return 0;
    try {
      final result = CalculadoraCredito.calcularCuotaTEA(
        monto: credito.montoSolicitado,
        tea: teaReferencialDefault,
        plazoMeses: credito.plazoMeses,
      );
      return (result['cuota'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  double get totalPagarEstimado => cuotaEstimada * credito.plazoMeses;

  double get costoFinancieroEstimado => totalPagarEstimado - credito.montoSolicitado;

  static int _edad(DateTime fecha) {
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad;
  }
}

class SolicitudNotifier extends StateNotifier<SolicitudFormState> {
  final SolicitudRepository _repository;

  SolicitudNotifier(this._repository) : super(const SolicitudFormState());

  void loadBorrador(SolicitudModel model) {
    state = state.copyWith(
      pasoActual: model.pasoActual,
      solicitante: model.solicitante,
      negocio: model.negocio,
      credito: model.credito,
      firmaBase64: model.firmaBase64,
      datosVeraces: model.datosVeraces,
      isEditMode: true,
      solicitudId: model.id,
    );
  }

  void setPaso(int paso) {
    state = state.copyWith(pasoActual: paso.clamp(0, 3));
  }

  void updateSolicitante(DatosSolicitante s) {
    state = state.copyWith(solicitante: s);
  }

  void updateNegocio(DatosNegocio n) {
    state = state.copyWith(negocio: n);
  }

  void updateCredito(DatosCredito c) {
    state = state.copyWith(credito: c);
  }

  void setDatosVeraces(bool v) {
    state = state.copyWith(datosVeraces: v);
  }

  void setFirma(String base64) {
    state = state.copyWith(firmaBase64: base64);
  }

  bool avanzarPaso() {
    if (!_pasoValido(state.pasoActual)) {
      state = state.copyWith(camposError: _pasoActualLabel(state.pasoActual));
      return false;
    }
    state = state.copyWith(
      pasoActual: state.pasoActual + 1,
      camposError: null,
    );
    return true;
  }

  void retrocederPaso() {
    state = state.copyWith(
      pasoActual: (state.pasoActual - 1).clamp(0, 3),
      camposError: null,
    );
  }

  bool _pasoValido(int paso) {
    switch (paso) {
      case 0:
        return state.paso1Valido;
      case 1:
        return state.paso2Valido;
      case 2:
        return state.paso3Valido;
      default:
        return true;
    }
  }

  String _pasoActualLabel(int paso) {
    switch (paso) {
      case 0:
        return 'Complete todos los campos del solicitante';
      case 1:
        return 'Complete todos los campos del negocio';
      case 2:
        return 'Verifique las condiciones del crédito';
      default:
        return '';
    }
  }

  Future<void> guardarBorrador(String asesorId) async {
    final solicitud = _buildSolicitud(asesorId, EstadoSolicitud.borrador);
    await _repository.saveBorrador(solicitud);
  }

  Future<void> enviarSolicitud(String asesorId) async {
    if (!state.datosVeraces || state.firmaBase64.isEmpty) {
      state = state.copyWith(camposError: 'Debe aceptar los términos y firmar');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final solicitud = _buildSolicitud(asesorId, EstadoSolicitud.enviado);
      final expediente = await _repository.enviarSolicitud(solicitud);
      state = state.copyWith(
        isSubmitting: false,
        expedienteGenerado: expediente,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void resetForm() {
    state = const SolicitudFormState();
  }

  void clearCamposError() {
    state = state.copyWith(camposError: null);
  }

  SolicitudModel _buildSolicitud(String asesorId, EstadoSolicitud estado) {
    return SolicitudModel(
      id: state.solicitudId ?? const Uuid().v4(),
      asesorId: asesorId,
      estado: estado,
      pasoActual: state.pasoActual,
      solicitante: state.solicitante,
      negocio: state.negocio,
      credito: state.credito,
      cuotaEstimada: state.cuotaEstimada,
      teaReferencial: teaReferencialDefault,
      firmaBase64: state.firmaBase64,
      datosVeraces: state.datosVeraces,
      pendienteSync: true,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> simularCuota({
    required double monto,
    required int plazoMeses,
    double tea = teaReferencialDefault,
  }) async {
    return CalculadoraCredito.calcularCuotaTEA(
      monto: monto,
      tea: tea,
      plazoMeses: plazoMeses,
    );
  }
}
