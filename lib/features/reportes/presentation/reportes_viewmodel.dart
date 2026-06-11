import 'package:flutter/foundation.dart';

// TODO: Implementar lógica de generación de reportes
class ReportesViewModel extends ChangeNotifier {
  ReportesViewModel();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // TODO: Generar reporte de actividad
  Future<Map<String, dynamic>> generarReporte({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Simulación
    await Future.delayed(const Duration(seconds: 2));
    final reporte = {
      'visitas_realizadas': 15,
      'solicitudes_generadas': 8,
      'monto_total': 120000,
    };

    _isLoading = false;
    notifyListeners();
    return reporte;
  }
}
