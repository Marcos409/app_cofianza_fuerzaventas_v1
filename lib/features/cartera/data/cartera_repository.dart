import 'dart:async';
import 'cartera_remote_datasource.dart';
import 'cartera_local_datasource.dart';
import '../domain/cartera_model.dart';
import '../../../core/network/network_monitor.dart';
import '../../../core/supabase/supabase_client.dart';

class CarteraRepository {
  final CarteraRemoteDatasource _remoteDatasource;
  final CarteraLocalDatasource _localDatasource;
  final NetworkMonitor _networkMonitor;
  final SupabaseService _supabase;
  StreamSubscription? _connectivitySubscription;

  CarteraRepository(
    this._remoteDatasource,
    this._localDatasource,
    this._networkMonitor,
    this._supabase,
  ) {
    _connectivitySubscription = _networkMonitor.connectivityStream
        .listen((isConnected) {
      if (isConnected) _sincronizarPendientes();
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<List<CarteraModel>> getCartera() async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final asesorId = _supabase.auth.currentUser?.id;
        if (asesorId == null) throw Exception('Sesión no encontrada');

        final clientes = await _remoteDatasource.getCarteraDiaria(
          asesorId: asesorId,
          fecha: DateTime.now(),
        );

        await _localDatasource.saveCartera(clientes);
        await _sincronizarPendientes();
        return clientes;
      } catch (e) {
        return _getLocales();
      }
    }

    return _getLocales();
  }

  Future<List<CarteraModel>> searchClientes(String query) async {
    if (query.trim().isEmpty) return getCartera();
    return _localDatasource.searchClientes(query.trim());
  }

  Future<void> marcarVisita({
    required String id,
    required EstadoVisita estado,
    String? observacion,
    double? lat,
    double? lng,
  }) async {
    final now = DateTime.now();
    final timestamp = now.toIso8601String();

    await _localDatasource.actualizarVisita(
      id: id,
      estadoVisita: estado.dbValue,
      resultadoVisita: estado.label,
      observacion: observacion,
      timestamp: timestamp,
      lat: lat,
      lng: lng,
    );

    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        await _remoteDatasource.sincronizarVisita({
          'id': id,
          'estado_visita': estado.dbValue,
          'resultado_visita': estado.label,
          'observacion_visita': observacion,
          'timestamp_visita': timestamp,
          'lat_visita': lat,
          'lng_visita': lng,
        });
        await _localDatasource.marcarSincronizadas([id]);
      } catch (_) {}
    }
  }

  Future<void> actualizarOrdenManual(String id, int orden) async {
    await _localDatasource.actualizarOrdenManual(id, orden);
  }

  Future<void> _sincronizarPendientes() async {
    try {
      final pendientes = await _localDatasource.getVisitasPendientes();
      if (pendientes.isEmpty) return;

      final visitasData = pendientes.map((p) {
        return {
          'id': p['cartero_id'],
          'estado_visita': p['resultado'],
          'resultado_visita': p['resultado'],
          'observacion_visita': p['observacion'],
          'timestamp_visita': p['timestamp_visita'],
          'lat_visita': p['lat'],
          'lng_visita': p['lng'],
        };
      }).toList();

      await _remoteDatasource.sincronizarVisitas(visitasData);
      final ids = pendientes
          .map((p) => p['cartero_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      await _localDatasource.marcarSincronizadas(ids);
    } catch (_) {}
  }

  Future<List<CarteraModel>> _getLocales() async {
    final locales = await _localDatasource.getCartera();
    if (locales.isEmpty) {
      throw Exception(
        'No hay datos guardados. Conéctate a internet para descargar la cartera.',
      );
    }
    return locales;
  }
}
