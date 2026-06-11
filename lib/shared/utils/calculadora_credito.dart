class CalculadoraCredito {
  CalculadoraCredito._();

  /// Calcula la cuota mensual usando el sistema de amortización francés.
  ///
  /// [monto] - Monto del préstamo en soles.
  /// [tasaAnual] - Tasa de interés anual en porcentaje (ej. 24.5 para 24.5%).
  /// [plazoMeses] - Número de meses del préstamo.
  ///
  /// Retorna un mapa con:
  /// - cuota: cuota mensual fija
  /// - totalIntereses: suma total de intereses pagados
  /// - totalPagar: monto total a pagar
  /// - calendario: lista de mapas con mes, cuota, interés, amortización, saldo
  static Map<String, dynamic> calcularCuota({
    required double monto,
    required double tasaAnual,
    required int plazoMeses,
  }) {
    final tasaMensual = tasaAnual / 100 / 12;
    return _calcular(monto, tasaMensual, plazoMeses);
  }

  /// Calcula usando TEA (Tasa Efectiva Anual) en formato decimal (ej. 0.25 para 25%).
  static Map<String, dynamic> calcularCuotaTEA({
    required double monto,
    required double tea,
    required int plazoMeses,
  }) {
    final tem = _teaToTem(tea);
    return _calcular(monto, tem, plazoMeses);
  }

  static Map<String, dynamic> _calcular(
      double monto, double tasaMensual, int plazoMeses) {
    final factor = (1 + tasaMensual);
    final factorPow = _powInt(factor, plazoMeses);

    final cuota = monto * (tasaMensual * factorPow) / (factorPow - 1);

    final calendario = <Map<String, dynamic>>[];
    var saldo = monto;
    var totalIntereses = 0.0;

    for (var mes = 1; mes <= plazoMeses; mes++) {
      final interes = saldo * tasaMensual;
      final amortizacion = cuota - interes;
      saldo -= amortizacion;
      if (saldo < 0) saldo = 0;
      totalIntereses += interes;

      calendario.add({
        'mes': mes,
        'cuota': double.parse(cuota.toStringAsFixed(2)),
        'interes': double.parse(interes.toStringAsFixed(2)),
        'amortizacion': double.parse(amortizacion.toStringAsFixed(2)),
        'saldo': double.parse(saldo.toStringAsFixed(2)),
      });
    }

    return {
      'cuota': double.parse(cuota.toStringAsFixed(2)),
      'totalIntereses': double.parse(totalIntereses.toStringAsFixed(2)),
      'totalPagar': double.parse((monto + totalIntereses).toStringAsFixed(2)),
      'calendario': calendario,
    };
  }

  /// Convierte TEA (decimal) a TEM (decimal).
  /// TEM = (1 + TEA)^(1/12) - 1
  static double _teaToTem(double tea) {
    return _pow(1 + tea, 1 / 12) - 1;
  }

  static double _pow(double base, double exp) {
    if (exp == exp.roundToDouble()) {
      return _powInt(base, exp.toInt());
    }
    return base; // simplificación para exponente fraccionario
  }

  static double _powInt(double base, int exp) {
    var result = 1.0;
    for (var i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
