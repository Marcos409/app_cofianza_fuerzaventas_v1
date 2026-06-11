class ProductividadAsesor {
  final String asesorId;
  final String nombreAsesor;
  final int enviadas;
  final int aprobadas;
  final int desembolsadas;
  final double montoTotalAprobado;
  final double tasaAprobacion;

  const ProductividadAsesor({
    required this.asesorId,
    required this.nombreAsesor,
    this.enviadas = 0,
    this.aprobadas = 0,
    this.desembolsadas = 0,
    this.montoTotalAprobado = 0,
    this.tasaAprobacion = 0,
  });

  ProductividadAsesor copyWith({
    String? asesorId,
    String? nombreAsesor,
    int? enviadas,
    int? aprobadas,
    int? desembolsadas,
    double? montoTotalAprobado,
    double? tasaAprobacion,
  }) {
    return ProductividadAsesor(
      asesorId: asesorId ?? this.asesorId,
      nombreAsesor: nombreAsesor ?? this.nombreAsesor,
      enviadas: enviadas ?? this.enviadas,
      aprobadas: aprobadas ?? this.aprobadas,
      desembolsadas: desembolsadas ?? this.desembolsadas,
      montoTotalAprobado: montoTotalAprobado ?? this.montoTotalAprobado,
      tasaAprobacion: tasaAprobacion ?? this.tasaAprobacion,
    );
  }
}

class ReporteMensual {
  final List<ProductividadAsesor> asesores;
  final int totalEnviadas;
  final int totalAprobadas;
  final int totalDesembolsadas;
  final double montoTotal;

  const ReporteMensual({
    this.asesores = const [],
    this.totalEnviadas = 0,
    this.totalAprobadas = 0,
    this.totalDesembolsadas = 0,
    this.montoTotal = 0,
  });
}
