import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../domain/solicitud_model.dart';
import 'solicitud_providers.dart';

class BorradoresScreen extends ConsumerWidget {
  const BorradoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borradoresAsync = ref.watch(borradoresProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Borradores'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: borradoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error al cargar borradores: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (borradores) {
          if (borradores.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drafts_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text('No tienes borradores pendientes',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: borradores.length,
            itemBuilder: (context, i) {
              final b = borradores[i];
              final dateStr = b.fechaActualizacion != null
                  ? Formatters.date(b.fechaActualizacion!)
                  : '';
              final name = b.nombreCliente.isNotEmpty
                  ? b.nombreCliente
                  : '${b.solicitante.nombres} ${b.solicitante.apellidos}'.trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    name.isNotEmpty ? name : 'Cliente sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Monto: ${Formatters.currency(b.credito.montoSolicitado)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Última edición: $dateStr',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () {
                        ref.read(solicitudProvider.notifier).loadBorrador(b);
                        context.push('/solicitud');
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
