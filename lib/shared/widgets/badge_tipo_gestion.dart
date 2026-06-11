import 'package:flutter/material.dart';
import '../../features/cartera/domain/cartera_model.dart';
import '../../core/constants/app_colors.dart';

class BadgeTipoGestion extends StatelessWidget {
  final TipoGestion tipo;

  const BadgeTipoGestion({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _BadgeData _getConfig(TipoGestion tipo) {
    switch (tipo) {
      case TipoGestion.renovacion:
        return _BadgeData(
          'Renovación',
          AppColors.gestionRenovacionBg,
          AppColors.gestionRenovacionText,
        );
      case TipoGestion.ampliacion:
        return _BadgeData(
          'Ampliación',
          AppColors.gestionAmpliacionBg,
          AppColors.gestionAmpliacionText,
        );
      case TipoGestion.nuevaSolicitud:
        return _BadgeData(
          'Nueva solicitud',
          AppColors.gestionNuevaBg,
          AppColors.gestionNuevaText,
        );
      case TipoGestion.seguimiento:
        return _BadgeData(
          'Seguimiento',
          AppColors.gestionSeguimientoBg,
          AppColors.gestionSeguimientoText,
        );
      case TipoGestion.recuperacionMora:
        return _BadgeData(
          'Recuperación mora',
          AppColors.gestionMoraBg,
          AppColors.gestionMoraText,
        );
      case TipoGestion.desertor:
        return _BadgeData(
          'Desertor',
          AppColors.gestionDesertorBg,
          AppColors.gestionDesertorText,
        );
    }
  }
}

class _BadgeData {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _BadgeData(this.label, this.bgColor, this.textColor);
}
