import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/documentos/data/documento_local_datasource.dart';
import '../../../features/solicitud/data/solicitud_local_datasource.dart';
import '../../../core/storage/local_db.dart';
import '../domain/transmision_model.dart';
import 'transmision_providers.dart';
import 'transmision_viewmodel.dart';

class TransmisionScreen extends ConsumerStatefulWidget {
  final String solicitudId;

  const TransmisionScreen({super.key, required this.solicitudId});

  @override
  ConsumerState<TransmisionScreen> createState() => _TransmisionScreenState();
}

class _TransmisionScreenState extends ConsumerState<TransmisionScreen> {
  TransmisionParams? _params;

  @override
  void initState() {
    super.initState();
    _loadParamsAndStart();
  }

  Future<void> _loadParamsAndStart() async {
    final solicitudLocal =
        SolicitudLocalDatasource(LocalDb.instance);
    final docLocal = DocumentoLocalDatasource();

    final solicitud = await solicitudLocal.getEnviada(widget.solicitudId);
    if (solicitud == null || !mounted) return;

    final docs = await docLocal.listar(widget.solicitudId);

    final params = TransmisionParams(
      solicitudId: widget.solicitudId,
      solicitud: solicitud,
      documentos: docs,
      tieneConsultaBuro: true,
    );

    if (!mounted) return;
    setState(() => _params = params);

    final notifier =
        ref.read(transmisionNotifierProvider(params).notifier);
    await notifier.verificarReanudacion();
    final errores = await notifier.validarPreRequisitos();
    if (errores.isEmpty && mounted) {
      notifier.iniciarEnvio();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_params == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transmisión')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(transmisionNotifierProvider(_params!));
    final notifier =
        ref.read(transmisionNotifierProvider(_params!).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transmisión'),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(TransmisionState state, TransmisionNotifier notifier) {
    if (state.erroresPreValidacion.isNotEmpty) {
      return _buildErroresPreValidacion(state);
    }

    if (state.pasoActual == PasoTransmision.completado) {
      return _buildCompletado(state);
    }

    return _buildProgreso(state, notifier);
  }

  Widget _buildErroresPreValidacion(TransmisionState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning, size: 28),
              SizedBox(width: 8),
              Text(
                'Revisa los siguientes errores antes de enviar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: state.erroresPreValidacion.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.erroresPreValidacion[i]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('VOLVER Y CORREGIR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgreso(TransmisionState state, TransmisionNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (state.estadoRealtime != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estado: ${state.estadoRealtime}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (state.errorTransmision != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error, color: AppColors.error),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Error en la transmisión',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => notifier.reanudarEnvio(),
                        child: const Text('REINTENTAR'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.errorTransmision!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Enviando solicitud al comité...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: state.pasos.length,
              itemBuilder: (_, i) {
                final paso = state.pasos[i];
                final estadoPaso = state.estadoPaso(paso);
                return _PasoItem(
                  paso: paso,
                  estado: estadoPaso,
                  documentosOk: state.documentosOk,
                  documentosTotal: state.documentosTotal,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletado(TransmisionState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: AppColors.success),
            const SizedBox(height: 16),
            const Text(
              'Solicitud enviada',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            if (state.expedienteGenerado != null) ...[
              Text(
                'Expediente: ${state.expedienteGenerado}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (state.estadoRealtime != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Estado: ${state.estadoRealtime}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Tiempo estimado de respuesta: 24-48 horas hábiles',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('FINALIZAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasoItem extends StatelessWidget {
  final PasoTransmision paso;
  final EstadoItemTransmision estado;
  final int documentosOk;
  final int documentosTotal;

  const _PasoItem({
    required this.paso,
    required this.estado,
    required this.documentosOk,
    required this.documentosTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _buildIndicator(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              paso == PasoTransmision.subiendoDocumentos &&
                      estado == EstadoItemTransmision.enProceso
                  ? '${paso.label} ($documentosOk de $documentosTotal)'
                  : paso.label,
              style: TextStyle(
                fontSize: 14,
                color: estado == EstadoItemTransmision.pendiente
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontWeight: estado == EstadoItemTransmision.enProceso
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (paso == PasoTransmision.subiendoDocumentos &&
              estado == EstadoItemTransmision.enProceso)
            Text(
              '$documentosOk/$documentosTotal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    switch (estado) {
      case EstadoItemTransmision.pendiente:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textSecondary, width: 2),
          ),
          child: const Icon(Icons.circle, size: 8, color: AppColors.textSecondary),
        );
      case EstadoItemTransmision.enProceso:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      case EstadoItemTransmision.completado:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
          ),
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        );
      case EstadoItemTransmision.error:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error,
          ),
          child: const Icon(Icons.close, size: 16, color: Colors.white),
        );
    }
  }
}
