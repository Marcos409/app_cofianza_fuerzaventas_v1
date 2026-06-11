import 'package:flutter/material.dart';
import '../../features/cartera/domain/cartera_model.dart';
import '../../features/ficha_cliente/domain/ficha_models.dart';
import '../../core/constants/app_colors.dart';

class SemaforoRiesgo extends StatelessWidget {
  final NivelRiesgo? nivel;
  final CalificacionSbs? calificacionSbs;

  const SemaforoRiesgo({super.key, this.nivel, this.calificacionSbs});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (calificacionSbs != null) {
      color = _getSbsColor(calificacionSbs!);
      label = calificacionSbs!.label;
    } else if (nivel != null) {
      color = _getNivelColor(nivel!);
      label = _getNivelLabel(nivel!);
    } else {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getNivelColor(NivelRiesgo nivel) {
    switch (nivel) {
      case NivelRiesgo.bajo:
        return AppColors.sbsNormal;
      case NivelRiesgo.medio:
        return AppColors.sbsCpp;
      case NivelRiesgo.alto:
        return AppColors.sbsDudoso;
    }
  }

  String _getNivelLabel(NivelRiesgo nivel) {
    switch (nivel) {
      case NivelRiesgo.bajo:
        return 'Normal';
      case NivelRiesgo.medio:
        return 'CPP';
      case NivelRiesgo.alto:
        return 'Dudoso';
    }
  }

  Color _getSbsColor(CalificacionSbs cal) {
    switch (cal) {
      case CalificacionSbs.normal:
        return AppColors.sbsNormal;
      case CalificacionSbs.cpp:
        return AppColors.sbsCpp;
      case CalificacionSbs.deficiente:
        return AppColors.sbsDeficiente;
      case CalificacionSbs.dudoso:
        return AppColors.sbsDudoso;
      case CalificacionSbs.perdida:
        return AppColors.sbsPerdida;
    }
  }
}

class SemaforoRiesgoGrande extends StatelessWidget {
  final CalificacionSbs calificacion;

  const SemaforoRiesgoGrande({super.key, required this.calificacion});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(calificacion);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            calificacion.label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(CalificacionSbs cal) {
    switch (cal) {
      case CalificacionSbs.normal:
        return AppColors.sbsNormal;
      case CalificacionSbs.cpp:
        return AppColors.sbsCpp;
      case CalificacionSbs.deficiente:
        return AppColors.sbsDeficiente;
      case CalificacionSbs.dudoso:
        return AppColors.sbsDudoso;
      case CalificacionSbs.perdida:
        return AppColors.sbsPerdida;
    }
  }
}
