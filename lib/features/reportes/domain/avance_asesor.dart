import 'package:google_maps_flutter/google_maps_flutter.dart';

class AvanceAsesor {
  final String asesorId;
  final String nombreAsesor;
  final int visitados;
  final int totalAsignados;
  final double progreso;
  final String? ultimaSincronizacion;
  final double? lat;
  final double? lng;

  const AvanceAsesor({
    required this.asesorId,
    required this.nombreAsesor,
    this.visitados = 0,
    this.totalAsignados = 0,
    this.progreso = 0,
    this.ultimaSincronizacion,
    this.lat,
    this.lng,
  });

  LatLng? get latLng =>
      lat != null && lng != null ? LatLng(lat!, lng!) : null;

  AvanceAsesor copyWith({
    String? asesorId,
    String? nombreAsesor,
    int? visitados,
    int? totalAsignados,
    double? progreso,
    String? ultimaSincronizacion,
    double? lat,
    double? lng,
  }) {
    return AvanceAsesor(
      asesorId: asesorId ?? this.asesorId,
      nombreAsesor: nombreAsesor ?? this.nombreAsesor,
      visitados: visitados ?? this.visitados,
      totalAsignados: totalAsignados ?? this.totalAsignados,
      progreso: progreso ?? this.progreso,
      ultimaSincronizacion: ultimaSincronizacion ?? this.ultimaSincronizacion,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}
