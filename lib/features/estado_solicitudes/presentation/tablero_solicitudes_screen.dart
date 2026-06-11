import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../../solicitud/domain/solicitud_model.dart';
import '../domain/grupo_estado.dart';
import 'estado_providers.dart';
import 'detalle_solicitud_screen.dart';

class TableroSolicitudesScreen extends ConsumerStatefulWidget {
  final String asesorId;

  const TableroSolicitudesScreen({super.key, required this.asesorId});

  @override
  ConsumerState<TableroSolicitudesScreen> createState() =>
      _TableroSolicitudesScreenState();
}

class _TableroSolicitudesScreenState
    extends ConsumerState<TableroSolicitudesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: GrupoEstado.values.length, vsync: this);
    Future.microtask(() {
      ref
          .read(estadoNotifierFamilyProvider(widget.asesorId).notifier)
          .cargarSolicitudes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estadoNotifierFamilyProvider(widget.asesorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Solicitudes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (i) => _tabController.animateTo(i),
          tabs: GrupoEstado.values.map((g) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(g.label),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Color(g.color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.contador(g)}',
                      style: TextStyle(
                        color: Color(g.color),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: GrupoEstado.values.map((g) {
                return _ListaSolicitudes(
                  solicitudes: state.agrupadas[g] ?? [],
                  grupo: g,
                );
              }).toList(),
            ),
    );
  }
}

class _ListaSolicitudes extends StatelessWidget {
  final List<SolicitudModel> solicitudes;
  final GrupoEstado grupo;

  const _ListaSolicitudes({
    required this.solicitudes,
    required this.grupo,
  });

  @override
  Widget build(BuildContext context) {
    if (solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              'No hay solicitudes ${grupo.label.toLowerCase()}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: solicitudes.length,
      itemBuilder: (_, i) => _SolicitudCard(solicitud: solicitudes[i]),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final SolicitudModel solicitud;
  const _SolicitudCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final grupo = GrupoEstado.fromEstadoSolicitud(solicitud.estado);
    final diasDesdeEnvio = solicitud.fechaCreacion != null
        ? DateTime.now().difference(solicitud.fechaCreacion!).inDays
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetalleSolicitudScreen(solicitud: solicitud),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      solicitud.nombreCliente.isNotEmpty
                          ? solicitud.nombreCliente
                          : '${solicitud.solicitante.nombres} ${solicitud.solicitante.apellidos}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _buildEstadoBadge(grupo),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'S/ ${formatearNumero(solicitud.credito.montoSolicitado)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '$diasDesdeEnvio días',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (solicitud.numeroExpediente.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Exp: ${solicitud.numeroExpediente}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(GrupoEstado grupo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color(grupo.color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        solicitud.estado.label,
        style: TextStyle(
          color: Color(grupo.color),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
