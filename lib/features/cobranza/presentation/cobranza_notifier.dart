import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/notification_service.dart';
import '../data/cobranza_repository.dart';
import '../domain/cliente_mora.dart';
import '../domain/accion_cobranza.dart';

enum CobranzaStatus { initial, loading, data, error, registrando, registroExitoso }

class CobranzaState {
  final CobranzaStatus status;
  final List<ClienteMora> morosos;
  final double totalVencido;
  final String? errorMessage;
  final String? mensajeExito;

  const CobranzaState({
    this.status = CobranzaStatus.initial,
    this.morosos = const [],
    this.totalVencido = 0,
    this.errorMessage,
    this.mensajeExito,
  });

  CobranzaState copyWith({
    CobranzaStatus? status,
    List<ClienteMora>? morosos,
    double? totalVencido,
    String? errorMessage,
    String? mensajeExito,
    bool clearError = false,
  }) {
    return CobranzaState(
      status: status ?? this.status,
      morosos: morosos ?? this.morosos,
      totalVencido: totalVencido ?? this.totalVencido,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      mensajeExito: clearError ? null : mensajeExito ?? this.mensajeExito,
    );
  }
}

class CobranzaNotifier extends StateNotifier<CobranzaState> {
  final CobranzaRepository _repository;
  final String _asesorId;

  CobranzaNotifier(this._repository, this._asesorId)
      : super(const CobranzaState());

  Future<void> cargarMorosos() async {
    state = state.copyWith(status: CobranzaStatus.loading, clearError: true);
    try {
      final morosos = await _repository.getMorosos();
      final total =
          morosos.fold<double>(0, (sum, m) => sum + m.montoVencido);
      state = state.copyWith(
        status: CobranzaStatus.data,
        morosos: morosos,
        totalVencido: total,
      );
    } catch (e) {
      state = state.copyWith(
        status: CobranzaStatus.error,
        errorMessage: 'Error al cargar mora: $e',
      );
    }
  }

  Future<void> registrarAccion({
    required String clienteId,
    required String creditoId,
    required String tipoGestion,
    required String resultado,
    double? montoPagado,
    DateTime? fechaCompromiso,
    double? montoCompromiso,
    String? observaciones,
    double? lat,
    double? lng,
  }) async {
    state = state.copyWith(
      status: CobranzaStatus.registrando,
      clearError: true,
    );
    try {
      final accion = AccionCobranza(
        id: const Uuid().v4(),
        asesorId: _asesorId,
        clienteId: clienteId,
        creditoId: creditoId,
        tipoGestion: tipoGestion,
        resultado: resultado,
        montoPagado: montoPagado,
        fechaCompromiso: fechaCompromiso,
        montoCompromiso: montoCompromiso,
        observaciones: observaciones,
        lat: lat,
        lng: lng,
        timestampGestion: DateTime.now(),
      );
      await _repository.registrarAccion(accion);

      if (fechaCompromiso != null && resultado == 'compromiso_pago') {
        final horaNotif = DateTime(
          fechaCompromiso!.year,
          fechaCompromiso!.month,
          fechaCompromiso!.day,
          8, 0,
        );
        await NotificationService.instance.scheduleNotification(
          id: 'compromiso_${accion.id}'.hashCode,
          title: 'Recordatorio de compromiso de pago',
          body: 'Cliente: ${accion.clienteId} acordó pagar S/${montoCompromiso?.toStringAsFixed(0) ?? ''} hoy.',
          scheduledDate: horaNotif.isAfter(DateTime.now())
              ? horaNotif
              : DateTime.now(),
        );
      }

      state = state.copyWith(
        status: CobranzaStatus.registroExitoso,
        mensajeExito: 'Gestión registrada correctamente',
      );
    } catch (e) {
      state = state.copyWith(
        status: CobranzaStatus.data,
        errorMessage: 'Error al registrar: $e',
      );
    }
  }

  void limpiarMensaje() {
    state = state.copyWith(mensajeExito: null, clearError: true);
  }
}
