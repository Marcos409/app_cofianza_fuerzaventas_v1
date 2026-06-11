import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/buro_interpreter.dart';
import '../data/buro_repository.dart';
import '../domain/consulta_buro_model.dart';

enum FlujoBuro {
  cargandoConsultaReciente,
  esperandoConsentimiento,
  firmando,
  consultando,
  resultado,
  bloqueado,
  error,
}

class BuroState {
  final FlujoBuro flujo;
  final ConsultaBuroModel? consultaReciente;
  final ConsultaBuroModel? consultaActual;
  final String firmaBase64;
  final String interpretacion;
  final String? errorMessage;
  final String? motivoBloqueo;

  const BuroState({
    this.flujo = FlujoBuro.esperandoConsentimiento,
    this.consultaReciente,
    this.consultaActual,
    this.firmaBase64 = '',
    this.interpretacion = '',
    this.errorMessage,
    this.motivoBloqueo,
  });

  BuroState copyWith({
    FlujoBuro? flujo,
    ConsultaBuroModel? consultaReciente,
    ConsultaBuroModel? consultaActual,
    String? firmaBase64,
    String? interpretacion,
    String? errorMessage,
    String? motivoBloqueo,
    bool clearConsultaReciente = false,
    bool clearErrorMessage = false,
  }) {
    return BuroState(
      flujo: flujo ?? this.flujo,
      consultaReciente: clearConsultaReciente ? null : consultaReciente ?? this.consultaReciente,
      consultaActual: consultaActual ?? this.consultaActual,
      firmaBase64: firmaBase64 ?? this.firmaBase64,
      interpretacion: interpretacion ?? this.interpretacion,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      motivoBloqueo: motivoBloqueo ?? this.motivoBloqueo,
    );
  }
}

class BuroNotifier extends StateNotifier<BuroState> {
  final BuroRepository _repository;
  final String _asesorId;
  final String _clienteId;
  final String _dniCliente;
  final String? _solicitudId;

  BuroNotifier(
    this._repository, {
    required String asesorId,
    required String clienteId,
    required String dniCliente,
    String? solicitudId,
  })  : _asesorId = asesorId,
        _clienteId = clienteId,
        _dniCliente = dniCliente,
        _solicitudId = solicitudId,
        super(const BuroState());

  Future<void> verificarConsultaReciente() async {
    state = state.copyWith(
      flujo: FlujoBuro.cargandoConsultaReciente,
      clearErrorMessage: true,
    );
    final reciente = await _repository.consultarReciente(_clienteId);
    if (reciente != null) {
      state = state.copyWith(
        flujo: FlujoBuro.esperandoConsentimiento,
        consultaReciente: reciente,
      );
    } else {
      state = state.copyWith(flujo: FlujoBuro.esperandoConsentimiento);
    }
  }

  void setFirma(String base64) {
    state = state.copyWith(firmaBase64: base64, flujo: FlujoBuro.firmando);
  }

  void reutilizarConsultaReciente() {
    if (state.consultaReciente == null) return;
    final interpretacion =
        interpretarResultadoBuro(state.consultaReciente!.resultado);
    state = state.copyWith(
      flujo: FlujoBuro.resultado,
      consultaActual: state.consultaReciente,
      interpretacion: interpretacion,
    );
    _repository.guardarReutilizacion(state.consultaReciente!);
  }

  void solicitarNuevaConsulta() {
    state = state.copyWith(
      flujo: FlujoBuro.esperandoConsentimiento,
      clearConsultaReciente: true,
    );
  }

  Future<void> ejecutarConsulta() async {
    if (state.firmaBase64.isEmpty) {
      state = state.copyWith(flujo: FlujoBuro.esperandoConsentimiento);
      return;
    }

    state = state.copyWith(flujo: FlujoBuro.consultando, clearErrorMessage: true);

    final resultado = await _repository.consultar(
      asesorId: _asesorId,
      clienteId: _clienteId,
      dniCliente: _dniCliente,
      firmaBase64: state.firmaBase64,
      solicitudId: _solicitudId,
    );

    if (resultado.enListaNegra) {
      state = state.copyWith(
        flujo: FlujoBuro.bloqueado,
        consultaActual: resultado,
        motivoBloqueo: resultado.motivoBloqueo,
      );
      return;
    }

    final interpretacion = interpretarResultadoBuro(resultado.resultado);
    state = state.copyWith(
      flujo: FlujoBuro.resultado,
      consultaActual: resultado,
      interpretacion: interpretacion,
    );
  }
}
