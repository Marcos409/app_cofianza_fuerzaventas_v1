import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../prospeccion/domain/prospeccion_models.dart';
import '../../prospeccion/presentation/prospeccion_providers.dart';

class PreEvaluacionScreen extends ConsumerStatefulWidget {
  const PreEvaluacionScreen({super.key});

  @override
  ConsumerState<PreEvaluacionScreen> createState() => _PreEvaluacionScreenState();
}

class _PreEvaluacionScreenState extends ConsumerState<PreEvaluacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentoCtrl = TextEditingController();
  final _nombresApellidosCtrl = TextEditingController();
  final _ingresosCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();
  double _montoSolicitado = 5000;

  bool _isLoading = false;
  ResultadoPreEvaluacion? _resultado;

  @override
  void dispose() {
    _documentoCtrl.dispose();
    _nombresApellidosCtrl.dispose();
    _ingresosCtrl.dispose();
    _destinoCtrl.dispose();
    super.dispose();
  }

  Future<void> _preEvaluar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _resultado = null;
    });

    final nombresApellidos = _nombresApellidosCtrl.text.trim();
    final parts = nombresApellidos.split(' ');
    final nombres = parts.isNotEmpty ? parts.first : '';
    final apellidos = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final prospecto = ProspectoModel(
      documento: _documentoCtrl.text.trim(),
      nombres: nombres,
      apellidos: apellidos,
      fechaNacimiento: DateTime(1990, 1, 1), // default/fallback
      tipoNegocio: 'Comercio', // default/fallback
      antiguedadAnios: 1,
      antiguedadMeses: 0,
      ingresosEstimados: double.tryParse(_ingresosCtrl.text.trim()) ?? 0,
      montoSolicitado: _montoSolicitado,
      destinoCredito: _destinoCtrl.text.trim(),
      asesorId: ref.read(authProvider).asesor?.id ?? '',
    );

    try {
      final repo = ref.read(prospeccionRepositoryProvider);
      final res = await repo.preEvaluar(prospecto);
      setState(() {
        _resultado = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultado = const ResultadoPreEvaluacion(
          calificacion: ResultadoCalificacion.revisar,
          motivo: 'Ocurrió un error inesperado. Se procesará al reconectar.',
          pendienteSync: true,
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pre-Evaluación'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos de la Pre-Evaluación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _documentoCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        decoration: const InputDecoration(
                          labelText: 'Número de documento',
                          prefixIcon: Icon(Icons.badge_outlined),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El número de documento es obligatorio';
                          }
                          if (value.trim().length != 8 || int.tryParse(value) == null) {
                            return 'Debe tener exactamente 8 dígitos numéricos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nombresApellidosCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombres y apellidos',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nombres y apellidos son obligatorios';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ingresosCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Ingresos mensuales estimados',
                          prefixText: 'S/ ',
                          prefixIcon: Icon(Icons.monetization_on_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Los ingresos mensuales son obligatorios';
                          }
                          final numVal = double.tryParse(value);
                          if (numVal == null || numVal <= 0) {
                            return 'Ingrese un monto mayor a cero';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monto solicitado: ${Formatters.currency(_montoSolicitado)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'S/ 500 — S/ 50,000',
                                style: TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                            ],
                          ),
                          Slider(
                            value: _montoSolicitado,
                            min: 500,
                            max: 50000,
                            divisions: 99,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _montoSolicitado = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _destinoCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Destino del crédito',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _preEvaluar,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search_outlined),
                          label: Text(_isLoading ? 'EVALUANDO...' : 'PRE-EVALUAR'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_resultado != null) ...[
                const SizedBox(height: 16),
                _ResultadoCard(
                  resultado: _resultado!,
                  nombre: _nombresApellidosCtrl.text.trim(),
                  documento: _documentoCtrl.text.trim(),
                  monto: _montoSolicitado,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  final ResultadoPreEvaluacion resultado;
  final String nombre;
  final String documento;
  final double monto;

  const _ResultadoCard({
    required this.resultado,
    required this.nombre,
    required this.documento,
    required this.monto,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String message;

    switch (resultado.calificacion) {
      case ResultadoCalificacion.apto:
        bg = const Color(0xE8F5E9FF); // light green
        border = Colors.green.shade300;
        text = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        message = 'Puede continuar';
        break;
      case ResultadoCalificacion.revisar:
        bg = const Color(0xFFFFFDE7); // light yellow
        border = Colors.yellow.shade600;
        text = Colors.yellow.shade900;
        icon = Icons.warning_amber_outlined;
        message = 'Requiere análisis adicional';
        break;
      case ResultadoCalificacion.noProcede:
        bg = const Color(0xFFFFEBEE); // light red
        border = Colors.red.shade300;
        text = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        message = 'No califica';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: text, size: 48),
          const SizedBox(height: 12),
          Text(
            resultado.calificacionLabel,
            style: TextStyle(
              color: text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (resultado.motivo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              resultado.motivo,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
          if (resultado.calificacion == ResultadoCalificacion.apto) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  context.push('/solicitud/nueva', extra: {
                    'nombre': nombre,
                    'documento': documento,
                    'monto': monto,
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Iniciar solicitud'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
