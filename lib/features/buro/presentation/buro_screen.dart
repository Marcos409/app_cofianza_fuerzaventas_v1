import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/signature_pad.dart';
import '../domain/consulta_buro_model.dart';
import 'buro_providers.dart';
import 'buro_viewmodel.dart';

class BuroScreen extends ConsumerStatefulWidget {
  final String asesorId;
  final String clienteId;
  final String dniCliente;
  final String nombreCliente;
  final String? solicitudId;

  const BuroScreen({
    super.key,
    required this.asesorId,
    required this.clienteId,
    required this.dniCliente,
    required this.nombreCliente,
    this.solicitudId,
  });

  @override
  ConsumerState<BuroScreen> createState() => _BuroScreenState();
}

class _BuroScreenState extends ConsumerState<BuroScreen> {
  late final BuroParams _params;

  @override
  void initState() {
    super.initState();
    _params = BuroParams(
      asesorId: widget.asesorId,
      clienteId: widget.clienteId,
      dniCliente: widget.dniCliente,
      solicitudId: widget.solicitudId,
    );
    Future.microtask(() {
      ref.read(buroNotifierProvider(_params).notifier).verificarConsultaReciente();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buroNotifierProvider(_params));
    final notifier = ref.read(buroNotifierProvider(_params).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Consulta de Buró')),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(BuroState state, BuroNotifier notifier) {
    switch (state.flujo) {
      case FlujoBuro.cargandoConsultaReciente:
        return const Center(child: CircularProgressIndicator());
      case FlujoBuro.esperandoConsentimiento:
        return _buildConsentimiento(state, notifier);
      case FlujoBuro.firmando:
        return _buildSignaturePad(notifier);
      case FlujoBuro.consultando:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Consultando central de riesgo...'),
            ],
          ),
        );
      case FlujoBuro.resultado:
        return _buildResultado(state, notifier);
      case FlujoBuro.bloqueado:
        return _buildBloqueado(state);
      case FlujoBuro.error:
        return Center(
          child: Text(
            state.errorMessage ?? 'Error en la consulta',
            style: const TextStyle(color: AppColors.error),
          ),
        );
    }
  }

  Widget _buildConsentimiento(BuroState state, BuroNotifier notifier) {
    return SingleChildScrollView(
      padding: context.respPad(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.consultaReciente != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Existe una consulta de hace ${DateTime.now().difference(state.consultaReciente!.createdAt).inDays} días. ¿Usar ese resultado o realizar una nueva?',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: notifier.reutilizarConsultaReciente,
                    child: const Text('USAR RESULTADO EXISTENTE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: notifier.solicitarNuevaConsulta,
                    child: const Text('NUEVA CONSULTA'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
          ],
          Text(
            'Autorización para consulta de central de riesgos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const Text(
            'LEY N° 29733 — LEY DE PROTECCIÓN DE DATOS PERSONALES\n\n'
            'Autorizo expresamente a [Nombre de la Institución] a consultar '
            'mi historial crediticio en las centrales de riesgo, así como a '
            'verificar mi información en listas de restricción del sistema '
            'financiero, con la finalidad de evaluar mi solicitud de crédito.\n\n'
            'Declaro haber sido informado de mis derechos conforme a la Ley '
            '29733 y su reglamento.\n\n'
            'Esta autorización tiene carácter obligatorio para la evaluación '
            'del crédito solicitado.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => notifier.setFirma(''),
                icon: const Icon(Icons.draw),
                label: const Text('FIRMAR AUTORIZACIÓN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignaturePad(BuroNotifier notifier) {
    return Padding(
      padding: context.respPad(all: 16),
      child: Column(
        children: [
          const Text(
            'Firme aquí para autorizar la consulta',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
            Expanded(
              child: SignaturePad(
                onSignatureChanged: (base64) => notifier.setFirma(base64),
              ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => notifier.ejecutarConsulta(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('CONSULTAR BURÓ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado(BuroState state, BuroNotifier notifier) {
    final consulta = state.consultaActual!;
    return SingleChildScrollView(
      padding: context.respPad(all: 16),
      child: Column(
        children: [
          _SemaforoRiesgoGrande(
            calificacion: consulta.resultado.calificacionSbs,
          ),
          const SizedBox(height: 20),
          _InfoRow(
            label: 'Calificación SBS',
            value: consulta.resultado.calificacionSbs.label,
          ),
          _InfoRow(
            label: 'Entidades con deuda',
            value: '${consulta.resultado.numEntidadesDeuda}',
          ),
          _InfoRow(
            label: 'Deuda total',
            value: 'S/${consulta.resultado.deudaTotal.toStringAsFixed(0)}',
          ),
          _InfoRow(
            label: 'Mayor deuda individual',
            value: 'S/${consulta.resultado.mayorDeuda.toStringAsFixed(0)}',
          ),
          _InfoRow(
            label: 'Días mayor mora',
            value: '${consulta.resultado.diasMayorMora} días',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.interpretacion,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          if (consulta.esReutilizada) ...[
            const SizedBox(height: 8),
            Text(
              'Resultado reutilizado de consulta del ${consulta.createdAt.day}/${consulta.createdAt.month}/${consulta.createdAt.year}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('CONTINUAR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueado(BuroState state) {
    return Center(
      child: Padding(
        padding: context.respPad(all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.block,
              size: 72,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'CLIENTE BLOQUEADO',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.motivoBloqueo ??
                  'El cliente se encuentra en listas de restricción.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ENTENDIDO'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SemaforoRiesgoGrande extends StatelessWidget {
  final CalificacionSbs calificacion;
  const _SemaforoRiesgoGrande({required this.calificacion});

  @override
  Widget build(BuildContext context) {
    final color = _colorFromCalificacion(calificacion);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.shield, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            calificacion.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFromCalificacion(CalificacionSbs c) {
    switch (c) {
      case CalificacionSbs.normal:
        return AppColors.success;
      case CalificacionSbs.cpp:
        return AppColors.warning;
      case CalificacionSbs.deficiente:
        return AppColors.secondary;
      case CalificacionSbs.dudoso:
        return Colors.orange;
      case CalificacionSbs.perdida:
        return AppColors.error;
    }
  }
}
