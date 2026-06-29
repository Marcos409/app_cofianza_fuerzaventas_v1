import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/responsive.dart';
import '../domain/avance_asesor.dart';
import 'reportes_providers.dart';
import 'reportes_notifier.dart';

class SupervisionScreen extends ConsumerStatefulWidget {
  final String agenciaId;

  const SupervisionScreen({super.key, required this.agenciaId});

  @override
  ConsumerState<SupervisionScreen> createState() => _SupervisionScreenState();
}

class _SupervisionScreenState extends ConsumerState<SupervisionScreen> {
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(supervisionProvider(widget.agenciaId).notifier)
          .cargarAvance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supervisionProvider(widget.agenciaId));

    if (state.status == ReportesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ReportesStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(state.errorMessage ?? 'Error',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref
                  .read(supervisionProvider(widget.agenciaId).notifier)
                  .cargarAvance(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    _actualizarMarcadores(state.asesores);

    return Column(
      children: [
        Expanded(flex: 3, child: _buildMap(state.asesores)),
        Expanded(flex: 2, child: _buildPanel(state.asesores)),
      ],
    );
  }

  Widget _buildMap(List<AvanceAsesor> asesores) {
    final center = _calcularCentro(asesores);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 13,
      ),
      markers: _markers,
      myLocationEnabled: true,
      zoomControlsEnabled: true,
    );
  }

  Widget _buildPanel(List<AvanceAsesor> asesores) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('Avance del día',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('${asesores.length} asesores',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: context.wp(3.2)),
              itemCount: asesores.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _buildFilaAsesor(asesores[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaAsesor(AvanceAsesor a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              a.nombreAsesor.isNotEmpty
                  ? a.nombreAsesor.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.nombreAsesor,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: a.progreso,
                    backgroundColor: AppColors.surface,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.success),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${a.visitados}/${a.totalAsignados}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(a.progreso * 100).toInt()}%',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _actualizarMarcadores(List<AvanceAsesor> asesores) {
    _markers.clear();
    for (final a in asesores) {
      final ll = a.latLng;
      if (ll == null) continue;
      _markers.add(Marker(
        markerId: MarkerId(a.asesorId),
        position: ll,
        infoWindow: InfoWindow(
          title: a.nombreAsesor,
          snippet: '${a.visitados}/${a.totalAsignados} gestiones',
        ),
      ));
    }
  }

  LatLng _calcularCentro(List<AvanceAsesor> asesores) {
    final conUbicacion =
        asesores.where((a) => a.latLng != null).map((a) => a.latLng!).toList();
    if (conUbicacion.isEmpty) return const LatLng(-12.046374, -77.042793);
    final lat =
        conUbicacion.fold(0.0, (s, l) => s + l.latitude) / conUbicacion.length;
    final lng =
        conUbicacion.fold(0.0, (s, l) => s + l.longitude) / conUbicacion.length;
    return LatLng(lat, lng);
  }
}
