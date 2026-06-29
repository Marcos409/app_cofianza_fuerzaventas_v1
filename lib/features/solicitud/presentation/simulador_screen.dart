import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/calculadora_credito.dart';

const double _teaReferencial = 0.25;

class SimuladorScreen extends StatefulWidget {
  const SimuladorScreen({super.key});

  @override
  State<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends State<SimuladorScreen> {
  double _monto = 5000;
  int _plazoMeses = 12;

  static const _plazos = [3, 6, 12, 18, 24, 36, 48, 60];

  Map<String, dynamic> get _resultado {
    try {
      return CalculadoraCredito.calcularCuotaTEA(
        monto: _monto,
        tea: _teaReferencial,
        plazoMeses: _plazoMeses,
      );
    } catch (_) {
      return {'cuota': 0, 'totalPagar': 0, 'totalIntereses': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _resultado;
    final cuota = (result['cuota'] as num?)?.toDouble() ?? 0;
    final totalPagar = (result['totalPagar'] as num?)?.toDouble() ?? 0;
    final totalIntereses = (result['totalIntereses'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Simulador de Crédito'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monto: ${Formatters.currency(_monto)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('S/ 500 — S/ 150,000',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                Slider(
                  value: _monto.clamp(500, 150000),
                  min: 500,
                  max: 150000,
                  divisions: 299,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _monto = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Plazo en meses'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _plazoMeses,
                  isExpanded: true,
                  items: _plazos
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text('$p meses')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _plazoMeses = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            _tarjetaIndicador('Cuota mensual', Formatters.currency(cuota),
                AppColors.primary),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _tarjetaIndicador('Total a pagar',
                      Formatters.currency(totalPagar), AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tarjetaIndicador(
                      'Costo financiero',
                      Formatters.currency(totalIntereses),
                      AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.go('/solicitud',
                      extra: {'monto': _monto, 'plazo': _plazoMeses});
                },
                icon: const Icon(Icons.post_add_outlined, size: 18),
                label: const Text('Crear solicitud con estos datos'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaIndicador(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
