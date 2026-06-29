import 'dart:async';
import 'cartera_remote_datasource.dart';
import 'cartera_local_datasource.dart';
import '../domain/cartera_model.dart';
import '../../../core/network/network_monitor.dart';

class CarteraRepository {
  final CarteraRemoteDatasource _remoteDatasource;
  final CarteraLocalDatasource _localDatasource;
  final NetworkMonitor _networkMonitor;
  StreamSubscription? _connectivitySubscription;

  CarteraRepository(
    this._remoteDatasource,
    this._localDatasource,
    this._networkMonitor,
  ) {
    _connectivitySubscription = _networkMonitor.connectivityStream
        .listen((isConnected) {
      if (isConnected) _sincronizarPendientes();
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<List<CarteraModel>> getCartera({String? asesorId}) async {
    final isOnline = await _networkMonitor.isConnected;
    if (isOnline && asesorId != null) {
      try {
        final items = await _remoteDatasource.getCarteraDiaria(asesorId: asesorId, fecha: DateTime.now());
        await _localDatasource.saveCartera(items, asesorId);
        return items;
      } catch (_) {}
    }
    final locales = await _localDatasource.getCartera(asesorId: asesorId);
    if (locales.isEmpty) {
      throw Exception('No hay datos guardados. Conéctate a internet para descargar la cartera.');
    }
    return locales;
  }

  Future<List<CarteraModel>> searchClientes(String query, {String? asesorId}) async {
    if (query.trim().isEmpty) return getCartera(asesorId: asesorId);
    return _localDatasource.searchClientes(query.trim(), asesorId: asesorId);
  }

  Future<void> marcarVisita({
    required String id, required EstadoVisita estado,
    String? observacion, double? lat, double? lng,
  }) async {
    final now = DateTime.now().toIso8601String();
    final visitaData = {
      'estado_visita': estado.dbValue,
      'resultado_visita': estado.label,
      'observacion_visita': observacion,
      'timestamp_visita': now,
      'lat_visita': lat,
      'lng_visita': lng,
    };
    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        await _remoteDatasource.sincronizarVisita({'id': id, ...visitaData});
      } catch (_) {}
    }
  }

  Future<void> actualizarOrdenManual(String id, int orden) async {
    // Se maneja localmente
  }

  Future<void> _sincronizarPendientes() async {}

  Future<List<CarteraModel>> _getLocales({String? asesorId}) async {
    return _localDatasource.getCartera(asesorId: asesorId);
  }
}
