import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/estado_solicitudes/data/estado_repository.dart';
import '../../solicitud/domain/solicitud_model.dart';

final docsSolicitudesProvider =
    FutureProvider.autoDispose.family<List<SolicitudModel>, String>(
        (ref, asesorId) {
  return EstadoRepository().listarPorAsesor(asesorId);
});

class DocumentosSolicitudesScreen extends ConsumerWidget {
  const DocumentosSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asesorId = ref.watch(authProvider).asesor?.id ?? '';
    final solicitudesAsync = ref.watch(docsSolicitudesProvider(asesorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Documentos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: solicitudesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error al cargar solicitudes: ${e.toString().replaceFirst("Exception: ", "")}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (solicitudes) {
          if (solicitudes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No hay solicitudes asignadas',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: solicitudes.length,
            itemBuilder: (_, i) {
              final s = solicitudes[i];
              final nombre = s.nombreCliente.isNotEmpty
                  ? s.nombreCliente
                  : '${s.solicitante.nombres} ${s.solicitante.apellidos}';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () =>
                      context.push('/documentos/${s.id}'),
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.description_outlined,
                        color: AppColors.primary),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.credito.montoSolicitado > 0)
                        Text(
                          Formatters.currency(s.credito.montoSolicitado),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      if (s.fechaCreacion != null)
                        Text(
                          Formatters.date(s.fechaCreacion!),
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
