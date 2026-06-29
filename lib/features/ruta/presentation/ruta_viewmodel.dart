import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/ruta_repository.dart';
import '../data/directions_service.dart';
import '../domain/ruta_models.dart';
import '../../cartera/domain/cartera_model.dart';
// ════════════════════════════════════════════════════════════
// 🔧 SUPABASE_COMENTADO: Desarrollando solo con PostgreSQL local - Junio 2026
// ════════════════════════════════════════════════════════════
// import '../../../core/supabase/supabase_client.dart';
// ════════════════════════════════════════════════════════════

enum RutaStatus { initial, loading, data, error }

class RutaState {
  final RutaStatus status;
  final List<CarteraModel> clientes;
  final String? errorMessage;
  final Position? currentPosition;
  final List<CarteraModel> rutaOptimizada;
  final List<ZonaTrabajo> zonas;
  final bool isOptimizing;
  final List<LatLng>? rutaPolylinePoints;
  final Set<Polygon> polygons;
  final String? zonaActual;
  final String? gpsError;

  const RutaState({
    this.status = RutaStatus.initial,
    this.clientes = const [],
    this.errorMessage,
    this.currentPosition,
    this.rutaOptimizada = const [],
    this.zonas = const [],
    this.isOptimizing = false,
    this.rutaPolylinePoints,
    this.polygons = const {},
    this.zonaActual,
    this.gpsError,
  });

  RutaState copyWith({
    RutaStatus? status,
    List<CarteraModel>? clientes,
    String? errorMessage,
    Position? currentPosition,
    List<CarteraModel>? rutaOptimizada,
    List<ZonaTrabajo>? zonas,
    bool? isOptimizing,
    List<LatLng>? rutaPolylinePoints,
    Set<Polygon>? polygons,
    String? zonaActual,
    String? gpsError,
    bool clearGpsError = false,
    bool clearPolyline = false,
  }) {
    return RutaState(
      status: status ?? this.status,
      clientes: clientes ?? this.clientes,
      errorMessage: errorMessage,
      currentPosition: currentPosition ?? this.currentPosition,
      rutaOptimizada: rutaOptimizada ?? this.rutaOptimizada,
      zonas: zonas ?? this.zonas,
      isOptimizing: isOptimizing ?? this.isOptimizing,
      rutaPolylinePoints: clearPolyline ? null : rutaPolylinePoints ?? this.rutaPolylinePoints,
      polygons: polygons ?? this.polygons,
      zonaActual: zonaActual ?? this.zonaActual,
      gpsError: clearGpsError ? null : gpsError ?? this.gpsError,
    );
  }
}

class RutaNotifier extends StateNotifier<RutaState> {
  final RutaRepository _repository;
  final DirectionsService _directionsService;
  // ════════════════════════════════════════════════════════════
  // 🔧 SUPABASE_COMENTADO: _supabase field eliminado para desarrollo local
  // ════════════════════════════════════════════════════════════
  // final SupabaseService _supabase;
  // ════════════════════════════════════════════════════════════

  // ════════════════════════════════════════════════════════════
  // 🔧 SUPABASE_COMENTADO: Constructor sin Supabase
  // ════════════════════════════════════════════════════════════
  // RutaNotifier(this._repository, this._directionsService, this._supabase)
  RutaNotifier(this._repository, this._directionsService)
  // ════════════════════════════════════════════════════════════
      : super(const RutaState());

  Future<void> loadData() async {
    state = state.copyWith(status: RutaStatus.loading);

    try {
      final clientes = await _repository.getClientesCartera();
      final noVisitados =
          clientes.where((c) => c.estadoVisita != EstadoVisita.visitado).toList();
      // ════════════════════════════════════════════════════════════
      // 🔧 SUPABASE_COMENTADO: asesorId de Supabase desactivado - usando string vacío
      // ════════════════════════════════════════════════════════════
      // final asesorId = _supabase.auth.currentUser?.id ?? '';
      // final zonas = await _repository.getZonasTrabajo(asesorId);
      final zonas = await _repository.getZonasTrabajo('');
      // ════════════════════════════════════════════════════════════

      final polygons = <Polygon>{};
      for (final zona in zonas) {
        if (zona.poligono.length < 3) continue;
        polygons.add(Polygon(
          polygonId: PolygonId(zona.id),
          points: zona.poligono
              .map((p) => LatLng(p.lat, p.lng))
              .toList(),
          fillColor: Color.fromARGB(
            zona.color.a,
            zona.color.r,
            zona.color.g,
            zona.color.b,
          ).withValues(alpha: 0.15),
          strokeColor: Color.fromARGB(
            zona.color.a,
            zona.color.r,
            zona.color.g,
            zona.color.b,
          ).withValues(alpha: 0.6),
          strokeWidth: 2,
          geodesic: true,
        ));
      }

      state = state.copyWith(
        status: RutaStatus.data,
        clientes: clientes,
        rutaOptimizada: noVisitados,
        zonas: zonas,
        polygons: polygons,
      );
    } catch (e) {
      state = state.copyWith(
        status: RutaStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        gpsError: 'service_disabled',
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          gpsError: 'permission_denied',
        );
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          gpsError: 'permission_denied_forever',
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        gpsError: 'permission_denied_forever',
      );
      return false;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      state = state.copyWith(
        currentPosition: position,
        gpsError: null,
      );
      _checkZonaActual();

      if (state.rutaOptimizada.isNotEmpty) {
        _optimizeRoute();
      }
      return true;
    } catch (_) {
      state = state.copyWith(
        gpsError: 'gps_failed',
        currentPosition: null,
      );
      return false;
    }
  }

  void clearGpsError() {
    state = state.copyWith(clearGpsError: true);
  }

  void _checkZonaActual() {
    final pos = state.currentPosition;
    if (pos == null) return;
    final point = LatLngPoint(lat: pos.latitude, lng: pos.longitude);
    for (final zona in state.zonas) {
      if (zona.poligono.length >= 3 && isInsidePolygon(point, zona.poligono)) {
        state = state.copyWith(zonaActual: zona.nombre);
        return;
      }
    }
    state = state.copyWith(zonaActual: null);
  }

  void optimizeRoute() {
    _optimizeRoute();
  }

  void _optimizeRoute() {
    final pos = state.currentPosition;
    if (pos == null) return;

    state = state.copyWith(isOptimizing: true);

    final current = LatLngPoint(lat: pos.latitude, lng: pos.longitude);
    final noVisitados = state.clientes
        .where((c) => c.estadoVisita != EstadoVisita.visitado)
        .toList();

    final optimizada = _nearestNeighbor(current, noVisitados);
    state = state.copyWith(rutaOptimizada: optimizada, isOptimizing: false);
    _fetchRoutePolyline();
  }

  Future<void> _fetchRoutePolyline() async {
    final pos = state.currentPosition;
    final ruta = state.rutaOptimizada;
    if (pos == null || ruta.isEmpty) return;

    final origin = LatLng(pos.latitude, pos.longitude);
    final waypoints = ruta
        .take(ruta.length - 1)
        .where((c) => c.latVisita != null && c.lngVisita != null)
        .map((c) => LatLng(c.latVisita!, c.lngVisita!))
        .toList();
    final dest = ruta.last;
    if (dest.latVisita == null || dest.lngVisita == null) return;
    final destination = LatLng(dest.latVisita!, dest.lngVisita!);

    final route = await _directionsService.getRoute(
      origin: origin,
      waypoints: waypoints,
      destination: destination,
    );

    state = state.copyWith(rutaPolylinePoints: route);
  }

  List<CarteraModel> _nearestNeighbor(
    LatLngPoint start,
    List<CarteraModel> puntos,
  ) {
    if (puntos.isEmpty) return [];
    if (puntos.length == 1) return puntos;

    final result = <CarteraModel>[];
    final remaining = List<CarteraModel>.from(puntos);
    var current = start;

    while (remaining.isNotEmpty) {
      var nearestIdx = 0;
      var nearestDist = double.infinity;

      for (var i = 0; i < remaining.length; i++) {
        if (remaining[i].latVisita == null || remaining[i].lngVisita == null) {
          continue;
        }
        final p = LatLngPoint(
          lat: remaining[i].latVisita!,
          lng: remaining[i].lngVisita!,
        );
        final dist = current.distanceTo(p);
        if (dist < nearestDist) {
          nearestDist = dist;
          nearestIdx = i;
        }
      }

      final picked = remaining.removeAt(nearestIdx);
      result.add(picked);
      current = LatLngPoint(
        lat: picked.latVisita ?? 0,
        lng: picked.lngVisita ?? 0,
      );
    }

    return result;
  }

  bool isInsidePolygon(LatLngPoint point, List<LatLngPoint> polygon) {
    var inside = false;
    var j = polygon.length - 1;

    for (var i = 0; i < polygon.length; i++) {
      if ((polygon[i].lng > point.lng) != (polygon[j].lng > point.lng) &&
          point.lat <
              (polygon[j].lat - polygon[i].lat) *
                      (point.lng - polygon[i].lng) /
                      (polygon[j].lng - polygon[i].lng) +
                  polygon[i].lat) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  Future<void> actualizarUbicacionCliente({
    required String clienteId,
    required double lat,
    required double lng,
  }) async {
    await _repository.actualizarUbicacionCliente(
      clienteId: clienteId,
      lat: lat,
      lng: lng,
    );

    final actualizados = state.clientes.map((c) {
      if (c.clienteId == clienteId) {
        return c.copyWith(latVisita: lat, lngVisita: lng);
      }
      return c;
    }).toList();

    state = state.copyWith(clientes: actualizados);
  }
}
