import '../../solicitud/domain/solicitud_model.dart';

enum GrupoEstado {
  enviadas,
  enComite,
  aprobadas,
  desembolsadas,
  rechazadas;

  String get label {
    switch (this) {
      case GrupoEstado.enviadas:
        return 'Enviadas';
      case GrupoEstado.enComite:
        return 'En comité';
      case GrupoEstado.aprobadas:
        return 'Aprobadas';
      case GrupoEstado.desembolsadas:
        return 'Desembolsadas';
      case GrupoEstado.rechazadas:
        return 'Rechazadas';
    }
  }

  static GrupoEstado fromEstadoSolicitud(EstadoSolicitud estado) {
    switch (estado) {
      case EstadoSolicitud.borrador:
      case EstadoSolicitud.enviado:
        return GrupoEstado.enviadas;
      case EstadoSolicitud.recibidoComite:
      case EstadoSolicitud.enEvaluacion:
        return GrupoEstado.enComite;
      case EstadoSolicitud.aprobado:
      case EstadoSolicitud.condicionado:
        return GrupoEstado.aprobadas;
      case EstadoSolicitud.desembolsado:
        return GrupoEstado.desembolsadas;
      case EstadoSolicitud.rechazado:
        return GrupoEstado.rechazadas;
    }
  }
}

extension GrupoEstadoX on GrupoEstado {
  static const colores = {
    GrupoEstado.enviadas: 0xFF2196F3,
    GrupoEstado.enComite: 0xFFFF9800,
    GrupoEstado.aprobadas: 0xFF4CAF50,
    GrupoEstado.desembolsadas: 0xFF009688,
    GrupoEstado.rechazadas: 0xFFF44336,
  };

  int get color => colores[this]!;
}
