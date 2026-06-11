import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prospeccion_repository.dart';
import '../domain/prospeccion_models.dart';

class ProspeccionState {
  // Form fields
  final String documento;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final String tipoNegocio;
  final int antiguedadAnios;
  final int antiguedadMeses;
  final double ingresosEstimados;
  final double montoSolicitado;
  final String destinoCredito;

  // Desertor fields
  final MotivoDesercion? motivoDesercion;
  final String institucionMigro;
  final ProbabilidadRetorno? probabilidadRetorno;
  final String observacionesDesercion;

  // UI state
  final bool isLoading;
  final bool isFormValid;
  final String? errorMessage;
  final ResultadoPreEvaluacion? resultado;
  final bool formSubmitting;

  const ProspeccionState({
    this.documento = '',
    this.nombres = '',
    this.apellidos = '',
    this.fechaNacimiento,
    this.tipoNegocio = '',
    this.antiguedadAnios = 0,
    this.antiguedadMeses = 0,
    this.ingresosEstimados = 500,
    this.montoSolicitado = 1000,
    this.destinoCredito = '',
    this.motivoDesercion,
    this.institucionMigro = '',
    this.probabilidadRetorno,
    this.observacionesDesercion = '',
    this.isLoading = false,
    this.isFormValid = false,
    this.errorMessage,
    this.resultado,
    this.formSubmitting = false,
  });

  ProspeccionState copyWith({
    String? documento,
    String? nombres,
    String? apellidos,
    DateTime? fechaNacimiento,
    String? tipoNegocio,
    int? antiguedadAnios,
    int? antiguedadMeses,
    double? ingresosEstimados,
    double? montoSolicitado,
    String? destinoCredito,
    MotivoDesercion? motivoDesercion,
    String? institucionMigro,
    ProbabilidadRetorno? probabilidadRetorno,
    String? observacionesDesercion,
    bool? isLoading,
    bool? isFormValid,
    String? errorMessage,
    ResultadoPreEvaluacion? resultado,
    bool? formSubmitting,
  }) {
    return ProspeccionState(
      documento: documento ?? this.documento,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      tipoNegocio: tipoNegocio ?? this.tipoNegocio,
      antiguedadAnios: antiguedadAnios ?? this.antiguedadAnios,
      antiguedadMeses: antiguedadMeses ?? this.antiguedadMeses,
      ingresosEstimados: ingresosEstimados ?? this.ingresosEstimados,
      montoSolicitado: montoSolicitado ?? this.montoSolicitado,
      destinoCredito: destinoCredito ?? this.destinoCredito,
      motivoDesercion: motivoDesercion ?? this.motivoDesercion,
      institucionMigro: institucionMigro ?? this.institucionMigro,
      probabilidadRetorno: probabilidadRetorno ?? this.probabilidadRetorno,
      observacionesDesercion: observacionesDesercion ?? this.observacionesDesercion,
      isLoading: isLoading ?? this.isLoading,
      isFormValid: isFormValid ?? this.isFormValid,
      errorMessage: errorMessage,
      resultado: resultado ?? this.resultado,
      formSubmitting: formSubmitting ?? this.formSubmitting,
    );
  }

  bool get canPreEvaluar =>
      documento.length == 8 &&
      nombres.trim().isNotEmpty &&
      apellidos.trim().isNotEmpty &&
      tipoNegocio.trim().isNotEmpty &&
      ingresosEstimados > 0 &&
      montoSolicitado >= 500 &&
      montoSolicitado <= 50000 &&
      destinoCredito.trim().isNotEmpty &&
      !formSubmitting;
}

class ProspeccionNotifier extends StateNotifier<ProspeccionState> {
  final ProspeccionRepository _repository;

  ProspeccionNotifier(this._repository) : super(const ProspeccionState());

  void setDocumento(String v) {
    state = state.copyWith(documento: v);
    _validate();
  }

  void setNombres(String v) {
    state = state.copyWith(nombres: v);
    _validate();
  }

  void setApellidos(String v) {
    state = state.copyWith(apellidos: v);
    _validate();
  }

  void setFechaNacimiento(DateTime v) {
    state = state.copyWith(fechaNacimiento: v);
  }

  void setTipoNegocio(String v) {
    state = state.copyWith(tipoNegocio: v);
    _validate();
  }

  void setAntiguedadAnios(int v) {
    state = state.copyWith(antiguedadAnios: v);
  }

  void setAntiguedadMeses(int v) {
    state = state.copyWith(antiguedadMeses: v);
  }

  void setIngresosEstimados(double v) {
    state = state.copyWith(ingresosEstimados: v);
    _validate();
  }

  void setMontoSolicitado(double v) {
    state = state.copyWith(montoSolicitado: v);
    _validate();
  }

  void setDestinoCredito(String v) {
    state = state.copyWith(destinoCredito: v);
    _validate();
  }

  void _validate() {
    state = state.copyWith(isFormValid: state.canPreEvaluar);
  }

  Future<void> preEvaluar(String asesorId) async {
    if (!state.canPreEvaluar) return;

    final prospecto = ProspectoModel(
      asesorId: asesorId,
      documento: state.documento,
      nombres: state.nombres,
      apellidos: state.apellidos,
      fechaNacimiento: state.fechaNacimiento,
      tipoNegocio: state.tipoNegocio,
      antiguedadAnios: state.antiguedadAnios,
      antiguedadMeses: state.antiguedadMeses,
      ingresosEstimados: state.ingresosEstimados,
      montoSolicitado: state.montoSolicitado,
      destinoCredito: state.destinoCredito,
    );

    state = state.copyWith(
      formSubmitting: true,
      errorMessage: null,
      resultado: null,
    );

    final resultado = await _repository.preEvaluar(prospecto);
    state = state.copyWith(
      formSubmitting: false,
      resultado: resultado,
    );
  }

  void resetForm() {
    state = const ProspeccionState();
  }

  void setMotivoDesercion(MotivoDesercion v) {
    state = state.copyWith(motivoDesercion: v);
  }

  void setInstitucionMigro(String v) {
    state = state.copyWith(institucionMigro: v);
  }

  void setProbabilidadRetorno(ProbabilidadRetorno v) {
    state = state.copyWith(probabilidadRetorno: v);
  }

  void setObservacionesDesercion(String v) {
    state = state.copyWith(observacionesDesercion: v);
  }

  Future<void> registrarDesercion() async {
    final motivo = state.motivoDesercion;
    if (motivo == null) return;

    final asesorId = ''; // Will be set from auth
    await _repository.registrarDesercion(
      asesorId: asesorId,
      motivo: motivo,
      institucionMigro: state.institucionMigro,
      probabilidadRetorno: state.probabilidadRetorno,
      observaciones: state.observacionesDesercion,
    );

    state = state.copyWith(
      motivoDesercion: null,
      institucionMigro: '',
      probabilidadRetorno: null,
      observacionesDesercion: '',
    );
  }
}
