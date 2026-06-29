import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/solicitud/domain/solicitud_model.dart';

class _EtapaInfo {
  final String descripcion;
  final bool esTerminal;
  final bool esDesembolso;

  const _EtapaInfo({
    required this.descripcion,
    this.esTerminal = false,
    this.esDesembolso = false,
  });
}

final _etapas = [
  _EtapaInfo(descripcion: 'Solicitud enviada'),
  _EtapaInfo(descripcion: 'Recibida en comité'),
  _EtapaInfo(descripcion: 'En evaluación'),
  _EtapaInfo(descripcion: 'Decisión del comité'),
  _EtapaInfo(descripcion: 'Desembolso', esDesembolso: true, esTerminal: true),
];

class LineaTiempo extends StatelessWidget {
  final EstadoSolicitud estadoActual;

  const LineaTiempo({super.key, required this.estadoActual});

  int get _indiceActual {
    switch (estadoActual) {
      case EstadoSolicitud.borrador:
      case EstadoSolicitud.enviado:
      case EstadoSolicitud.enProceso:
        return 0;
      case EstadoSolicitud.recibidoComite:
        return 1;
      case EstadoSolicitud.enEvaluacion:
        return 2;
      case EstadoSolicitud.aprobado:
      case EstadoSolicitud.condicionado:
      case EstadoSolicitud.rechazado:
        return 3;
      case EstadoSolicitud.desembolsado:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_etapas.length, (i) {
        final etapa = _etapas[i];
        final isCompletado = i < _indiceActual;
        final isActivo = i == _indiceActual;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i > 0)
                    Container(
                      width: 2,
                      height: 28,
                      color: isCompletado
                          ? AppColors.success
                          : AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompletado
                          ? AppColors.success
                          : isActivo
                              ? AppColors.primary
                              : Colors.transparent,
                      border: Border.all(
                        color: isCompletado
                            ? AppColors.success
                            : isActivo
                                ? AppColors.primary
                                : AppColors.textSecondary,
                        width: 2,
                      ),
                    ),
                    child: isCompletado
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : isActivo
                            ? Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                  ),
                  if (i < _etapas.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: isCompletado
                          ? AppColors.success
                          : AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: EdgeInsets.only(
                top: i > 0 ? 28.0 : 2.0,
              ),
              child: Text(
                etapa.descripcion,
                style: TextStyle(
                  fontWeight:
                      isActivo ? FontWeight.bold : FontWeight.normal,
                  color: isCompletado
                      ? AppColors.textPrimary
                      : isActivo
                          ? AppColors.primary
                          : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
