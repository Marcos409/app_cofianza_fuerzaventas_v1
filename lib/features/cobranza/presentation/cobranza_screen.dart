import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/cliente_mora.dart';
import 'cobranza_providers.dart';
import 'cobranza_notifier.dart';
import 'registro_accion_screen.dart';

class CobranzaScreen extends ConsumerStatefulWidget {
  final String asesorId;

  const CobranzaScreen({super.key, required this.asesorId});

  @override
  ConsumerState<CobranzaScreen> createState() => _CobranzaScreenState();
}

class _CobranzaScreenState extends ConsumerState<CobranzaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(cobranzaProvider(widget.asesorId).notifier)
          .cargarMorosos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cobranzaProvider(widget.asesorId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Recuperación de Cartera'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(cobranzaProvider(widget.asesorId).notifier)
                .cargarMorosos(),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(CobranzaState state) {
    switch (state.status) {
      case CobranzaStatus.initial:
      case CobranzaStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CobranzaStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(state.errorMessage ?? 'Error de conexión',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(cobranzaProvider(widget.asesorId).notifier)
                    .cargarMorosos(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case CobranzaStatus.registrando:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Registrando gestión...'),
            ],
          ),
        );
      case CobranzaStatus.registroExitoso:
      case CobranzaStatus.data:
        return _buildData(state);
    }
  }

  Widget _buildData(CobranzaState state) {
    if (state.morosos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            const Text('No hay clientes en mora',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeaderTotal(state.totalVencido),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            itemCount: state.morosos.length,
            itemBuilder: (_, i) => _ClienteMoraCard(
              cliente: state.morosos[i],
              onRegistrar: () => _abrirRegistro(state.morosos[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTotal(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monto total vencido',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                'S/ ${_formatear(total)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirRegistro(ClienteMora cliente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegistroAccionScreen(
          cliente: cliente,
          asesorId: widget.asesorId,
          onRegistrada: () {
            ref
                .read(cobranzaProvider(widget.asesorId).notifier)
                .cargarMorosos();
          },
        ),
      ),
    );
  }

  String _formatear(double v) {
    return v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _ClienteMoraCard extends StatelessWidget {
  final ClienteMora cliente;
  final VoidCallback onRegistrar;

  const _ClienteMoraCard({
    required this.cliente,
    required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    final colorMora = _colorPorDias(cliente.diasMora);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorMora.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorMora,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cliente.nombreCliente,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorMora.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cliente.diasMora} días',
                    style: TextStyle(
                      color: colorMora,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(cliente.documentoCliente,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(cliente.telefono ?? '--',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.money_off, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  'S/ ${_formatear(cliente.montoVencido)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.error,
                  ),
                ),
                const Spacer(),
                Text(
                  'Saldo: S/ ${_formatear(cliente.saldoActual)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (cliente.ultimoContacto != null) ...[
              const SizedBox(height: 4),
              Text(
                'Último contacto: ${cliente.ultimoContacto}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRegistrar,
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Registrar gestión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorPorDias(int dias) {
    if (dias > 60) return AppColors.error;
    if (dias >= 31) return const Color(0xFFF97316);
    return AppColors.warning;
  }

  String _formatear(double v) {
    return v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}
