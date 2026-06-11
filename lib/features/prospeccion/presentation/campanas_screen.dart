import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/prospeccion_models.dart';
import 'prospeccion_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/utils/formatters.dart';

class CampanasScreen extends ConsumerWidget {
  const CampanasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campanasAsync = ref.watch(campanasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.campanasTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: campanasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        data: (campanas) {
          if (campanas.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(AppStrings.sinCampanas,
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campanas.length,
            itemBuilder: (_, i) => _CampanaCard(campana: campanas[i]),
          );
        },
      ),
    );
  }
}

class _CampanaCard extends StatelessWidget {
  final CampanaActivaModel campana;

  const _CampanaCard({required this.campana});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color text, IconData icon) = switch (campana.tipo) {
      TipoCampana.renovacion => (
        AppColors.gestionRenovacionBg,
        AppColors.gestionRenovacionText,
        Icons.refresh_outlined,
      ),
      TipoCampana.ampliacion => (
        AppColors.gestionAmpliacionBg,
        AppColors.gestionAmpliacionText,
        Icons.trending_up_outlined,
      ),
      TipoCampana.productoParalelo => (
        AppColors.gestionNuevaBg,
        AppColors.gestionNuevaText,
        Icons.add_box_outlined,
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: text),
                      const SizedBox(width: 4),
                      Text(
                        campana.tipoLabel,
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _DiasRestantesBadge(dias: campana.diasRestantes),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              campana.nombreCliente,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.currency(campana.montoOfertado),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/solicitud', extra: {
                    'monto': campana.montoOfertado,
                    'clienteId': campana.clienteId,
                  });
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text(AppStrings.btnGestionarAhora),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiasRestantesBadge extends StatelessWidget {
  final int dias;

  const _DiasRestantesBadge({required this.dias});

  @override
  Widget build(BuildContext context) {
    final Color color;

    if (dias <= 3) {
      color = AppColors.error;
    } else if (dias <= 7) {
      color = AppColors.warning;
    } else {
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$dias restantes',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
