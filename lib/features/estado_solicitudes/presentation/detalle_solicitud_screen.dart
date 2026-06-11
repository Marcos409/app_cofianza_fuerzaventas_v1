import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/linea_tiempo.dart';
import '../../solicitud/domain/solicitud_model.dart';
import '../domain/grupo_estado.dart';
import 'estado_providers.dart';

class DetalleSolicitudScreen extends ConsumerStatefulWidget {
  final SolicitudModel solicitud;

  const DetalleSolicitudScreen({super.key, required this.solicitud});

  @override
  ConsumerState<DetalleSolicitudScreen> createState() =>
      _DetalleSolicitudScreenState();
}

class _DetalleSolicitudScreenState
    extends ConsumerState<DetalleSolicitudScreen> {
  final _notaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(estadoNotifierFamilyProvider(widget.solicitud.asesorId).notifier)
          .cargarNotas(widget.solicitud.id);
    });
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.solicitud;
    final grupo = GrupoEstado.fromEstadoSolicitud(s.estado);

    return Scaffold(
      appBar: AppBar(title: Text(s.nombreCliente)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabecera(s, grupo),
            const SizedBox(height: 16),
            _buildCondicionesCredito(s),
            const SizedBox(height: 16),
            const Text('Línea de tiempo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            LineaTiempo(estadoActual: s.estado),
            const SizedBox(height: 16),
            const Text('Notas internas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildNotasSection(s),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecera(SolicitudModel s, GrupoEstado grupo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(grupo.color).withValues(alpha: 0.2),
              child: Text(
                (s.nombreCliente.isNotEmpty
                        ? s.nombreCliente
                        : '${s.solicitante.nombres} ${s.solicitante.apellidos}')
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase(),
                style: TextStyle(
                  color: Color(grupo.color),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.nombreCliente.isNotEmpty
                        ? s.nombreCliente
                        : '${s.solicitante.nombres} ${s.solicitante.apellidos}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(grupo.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.estado.label,
                      style: TextStyle(
                        color: Color(grupo.color),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (s.numeroExpediente.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Exp: ${s.numeroExpediente}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCondicionesCredito(SolicitudModel s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Condiciones del crédito',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _fila('Monto solicitado',
                'S/ ${formatearNumero(s.credito.montoSolicitado)}'),
            _fila('Plazo', '${s.credito.plazoMeses} meses'),
            _fila('Cuota estimada',
                'S/ ${formatearNumero(s.cuotaEstimada)}'),
            if (s.teaReferencial > 0)
              _fila('TEA', '${s.teaReferencial.toStringAsFixed(2)}%'),
          ],
        ),
      ),
    );
  }

  Widget _fila(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNotasSection(SolicitudModel s) {
    final state = ref.watch(estadoNotifierFamilyProvider(s.asesorId));
    final notifier = ref.read(estadoNotifierFamilyProvider(s.asesorId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _notaController,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Agregar nota interna...',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                if (_notaController.text.trim().isNotEmpty) {
                  notifier.agregarNota(s.id, _notaController.text.trim());
                  _notaController.clear();
                }
              },
              icon: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.notas.isEmpty)
          const Text('Sin notas internas',
              style: TextStyle(color: AppColors.textSecondary))
        else
          ...state.notas.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.contenido),
                          const SizedBox(height: 2),
                          Text(
                            '${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
