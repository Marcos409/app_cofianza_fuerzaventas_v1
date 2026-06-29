import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'solicitud_providers.dart';
import '../domain/solicitud_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/estado_solicitudes/presentation/detalle_solicitud_screen.dart';

final misSolicitudesProvider = FutureProvider.autoDispose
    .family<List<SolicitudModel>, String>((ref, asesorId) {
  return ref.watch(solicitudRepositoryProvider).getSolicitudesDelMes(asesorId);
});

class MisSolicitudesScreen extends ConsumerWidget {
  const MisSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asesorId = ref.watch(authProvider).asesor?.id ?? '';
    final solicitudesAsync = ref.watch(misSolicitudesProvider(asesorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mis solicitudes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: solicitudesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (solicitudes) {
          if (solicitudes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No hay solicitudes asignadas',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          final totalEnviadas = solicitudes.length;
          final aprobadas = solicitudes
              .where((s) => s.estado == EstadoSolicitud.aprobado)
              .length;
          final desembolsadas = solicitudes
              .where((s) => s.estado == EstadoSolicitud.desembolsado)
              .length;
          final montoTotal = solicitudes.fold<double>(
              0, (sum, s) => sum + s.credito.montoSolicitado);
          final tasaAprobacion =
              totalEnviadas > 0 ? (aprobadas / totalEnviadas) * 100 : 0.0;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Row(
                  children: [
                    _indicador('Enviadas', '$totalEnviadas',
                        AppColors.primary),
                    _indicador('Aprobadas', '$aprobadas',
                        AppColors.success),
                    _indicador('Desembolsadas',
                        '$desembolsadas', AppColors.secondary),
                    _indicador('Monto total',
                        Formatters.currency(montoTotal),
                        AppColors.warning),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Tasa de aprobación: ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text('${tasaAprobacion.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: solicitudes.length,
                  itemBuilder: (_, i) => _SolicitudCard(
                      solicitud: solicitudes[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetalleSolicitudScreen(
                              solicitud: solicitudes[i]),
                        ),
                      ),),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _indicador(
      String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final SolicitudModel solicitud;
  final VoidCallback? onTap;

  const _SolicitudCard({required this.solicitud, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(solicitud.estado);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          solicitud.credito.montoSolicitado > 0
              ? Formatters.currency(solicitud.credito.montoSolicitado)
              : 'Solicitud',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (solicitud.nombreCliente.isNotEmpty)
              Text(solicitud.nombreCliente,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (solicitud.fechaCreacion != null)
              Text(Formatters.date(solicitud.fechaCreacion!),
                  style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            solicitud.estado.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Color _estadoColor(EstadoSolicitud estado) {
    switch (estado) {
      case EstadoSolicitud.borrador:
        return AppColors.textHint;
      case EstadoSolicitud.enviado:
        return AppColors.info;
      case EstadoSolicitud.enProceso:
        return AppColors.info;
      case EstadoSolicitud.recibidoComite:
        return AppColors.info;
      case EstadoSolicitud.enEvaluacion:
        return AppColors.warning;
      case EstadoSolicitud.aprobado:
        return AppColors.success;
      case EstadoSolicitud.condicionado:
        return AppColors.warning;
      case EstadoSolicitud.rechazado:
        return AppColors.error;
      case EstadoSolicitud.desembolsado:
        return AppColors.success;
    }
  }
}
