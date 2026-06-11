import 'package:flutter/foundation.dart';

// TODO: Implementar lógica de cobranza
class CobranzaViewModel extends ChangeNotifier {
  CobranzaViewModel();

  List<Map<String, dynamic>> _cuentas = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get cuentas => _cuentas;
  bool get isLoading => _isLoading;

  // TODO: Obtener cuentas pendientes de cobro
  Future<void> loadCuentas() async {
    _isLoading = true;
    notifyListeners();

    // Simulación
    await Future.delayed(const Duration(seconds: 1));
    _cuentas = [
      {'cliente': 'Carlos López', 'monto': 5000, 'dias_atraso': 15},
    ];

    _isLoading = false;
    notifyListeners();
  }
}
