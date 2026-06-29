import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ficha_repository.dart';
import '../domain/ficha_models.dart';

class FichaState {
  final bool isLoading;
  final String? errorMessage;
  final FichaClienteModel? cliente;
  final PosicionCliente? posicion;
  final List<CreditoHistorico> historial;
  final List<PagoMensual> comportamiento;
  final OfertaPreaprobada? oferta;

  const FichaState({
    this.isLoading = false,
    this.errorMessage,
    this.cliente,
    this.posicion,
    this.historial = const [],
    this.comportamiento = const [],
    this.oferta,
  });

  FichaState copyWith({
    bool? isLoading,
    String? errorMessage,
    FichaClienteModel? cliente,
    PosicionCliente? posicion,
    List<CreditoHistorico>? historial,
    List<PagoMensual>? comportamiento,
    OfertaPreaprobada? oferta,
  }) {
    return FichaState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      cliente: cliente ?? this.cliente,
      posicion: posicion ?? this.posicion,
      historial: historial ?? this.historial,
      comportamiento: comportamiento ?? this.comportamiento,
      oferta: oferta ?? this.oferta,
    );
  }

  double get pctPuntual {
    if (comportamiento.isEmpty) return 0;
    final total = comportamiento.length;
    if (total == 0) return 0;
    final puntuales =
        comportamiento.where((p) => p.status == StatusPago.puntual).length;
    return (puntuales / total) * 100;
  }

  double get promedioDiasMora {
    final conMora = comportamiento.where((p) => p.status == StatusPago.mora).toList();
    if (conMora.isEmpty) return 0;
    final totalDias = conMora.fold<int>(0, (sum, p) {
      final now = DateTime.now();
      final fechaPago = DateTime(p.anio, p.mes);
      final diff = now.difference(fechaPago).inDays;
      return sum + (diff > 0 ? diff : 30);
    });
    return totalDias / conMora.length;
  }

  double get montoTotalPagado {
    return comportamiento
        .where((p) => p.status != StatusPago.sinCuota)
        .fold(0.0, (sum, p) => sum + p.montoPagado);
  }
}

class FichaNotifier extends StateNotifier<FichaState> {
  final FichaRepository _repository;

  FichaNotifier(this._repository) : super(const FichaState());

  Future<void> loadFicha(String clienteId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await Future.wait([
        _repository.getCliente(clienteId),
        _repository.getPosicionCliente(clienteId),
        _repository.getHistorialCrediticio(clienteId),
        _repository.getComportamientoPagos(clienteId),
        _repository.getOfertaPreaprobada(clienteId),
      ]);

      state = state.copyWith(
        isLoading: false,
        cliente: results[0] as FichaClienteModel,
        posicion: results[1] as PosicionCliente,
        historial: results[2] as List<CreditoHistorico>,
        comportamiento: results[3] as List<PagoMensual>,
        oferta: results[4] as OfertaPreaprobada?,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void usarOferta() {
    final oferta = state.oferta;
    if (oferta == null) return;
  }

  Future<void> actualizarUbicacion(
      String clienteId, double lat, double lng, {String direccion = ''}) async {
    await _repository.actualizarUbicacion(clienteId, lat, lng, direccion);
  }

  Future<void> registrarVisita({
    required String clienteId,
    required String estado,
    String? observacion,
    double? lat,
    double? lng,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.registrarVisita(
        clienteId: clienteId,
        estado: estado,
        observacion: observacion,
        lat: lat,
        lng: lng,
      );
      await loadFicha(clienteId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> getEstadoVisita(String clienteId) async {
    return _repository.getEstadoVisitaLocal(clienteId);
  }
}
