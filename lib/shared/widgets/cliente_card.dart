import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/cartera/domain/cartera_model.dart';
import 'badge_tipo_gestion.dart';
import 'semaforo_riesgo.dart';

class ClienteCard extends StatelessWidget {
  final CarteraModel cliente;
  final VoidCallback? onTap;
  final VoidCallback? onMarcarVisita;

  const ClienteCard({
    super.key,
    required this.cliente,
    this.onTap,
    this.onMarcarVisita,
  });

  @override
  Widget build(BuildContext context) {
    final isVisitado = cliente.estadoVisita == EstadoVisita.visitado;
    final isCerrado = cliente.estadoVisita == EstadoVisita.negocioCerrado;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isVisitado
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
          width: isVisitado ? 0.5 : 0.5,
        ),
      ),
      color: isVisitado ? AppColors.surface : AppColors.background,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(isVisitado, isCerrado),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo(context)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (cliente.montoCredito != null)
                    Text(
                      'S/ ${cliente.montoCredito!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cliente.scorePrioridad >= 70
                            ? AppColors.error
                            : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  BadgeTipoGestion(tipo: cliente.tipoGestion),
                  const SizedBox(height: 4),
                  SemaforoRiesgo(nivel: cliente.nivelRiesgo),
                  if (isVisitado || isCerrado) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isVisitado
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.textSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isVisitado ? 'Visitado' : 'Cerrado',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isVisitado ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (cliente.pendienteSync)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 14,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isVisitado, bool isCerrado) {
    return CircleAvatar(
      backgroundColor: isVisitado
          ? AppColors.success
          : isCerrado
              ? AppColors.textSecondary
              : AppColors.primary,
      radius: 20,
      child: Text(
        cliente.nombreCliente.isNotEmpty
            ? cliente.nombreCliente[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cliente.nombreCliente,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          cliente.documentoCensurado,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          cliente.direccionCliente,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildPriorityBadge(),
      ],
    );
  }

  Widget _buildPriorityBadge() {
    Color bgColor;
    Color textColor;
    String label;

    if (cliente.scorePrioridad >= 70) {
      bgColor = AppColors.priorityHigh.withValues(alpha: 0.12);
      textColor = AppColors.priorityHigh;
      label = 'ALTA';
    } else if (cliente.scorePrioridad >= 40) {
      bgColor = AppColors.priorityMedium.withValues(alpha: 0.12);
      textColor = AppColors.priorityMedium;
      label = 'MEDIA';
    } else {
      bgColor = AppColors.priorityNormal.withValues(alpha: 0.12);
      textColor = AppColors.priorityNormal;
      label = 'NORMAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
