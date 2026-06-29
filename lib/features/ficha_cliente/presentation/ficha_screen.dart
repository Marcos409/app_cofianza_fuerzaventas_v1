import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/semaforo_riesgo.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'ficha_providers.dart';
import 'ficha_viewmodel.dart';
import '../domain/ficha_models.dart';
import '../../cartera/domain/cartera_model.dart';
import '../../../shared/utils/calculadora_credito.dart';

class FichaScreen extends ConsumerStatefulWidget {
  final String clienteId;

  const FichaScreen({super.key, required this.clienteId});

  @override
  ConsumerState<FichaScreen> createState() => _FichaScreenState();
}

class _FichaScreenState extends ConsumerState<FichaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fichaProvider.notifier).loadFicha(widget.clienteId);
    });
  }

  Future<void> _mostrarOpcionesVisita(
      String clienteId, String nombre, String documento) async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {}

    if (!mounted) return;

    final opciones = EstadoVisita.values;
    final currentEstadoStr = await ref.read(fichaProvider.notifier).getEstadoVisita(clienteId);
    final currentEstado = EstadoVisita.fromString(currentEstadoStr);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String? observacion;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.censoredDni(documento),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (position != null)
                        Icon(Icons.gps_fixed,
                            size: 18, color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Resultado de la visita:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: opciones.map((estado) {
                      final isSelected = estado == currentEstado;
                      return ChoiceChip(
                        label: Text(
                          estado.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _confirmarVisita(
                              ctx,
                              clienteId,
                              estado,
                              observacion,
                              position,
                            );
                          }
                        },
                        selectedColor: _estadoColor(estado)
                            .withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? _estadoColor(estado)
                              : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Observación (máx. 200 caracteres)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      counterText: '',
                    ),
                    maxLines: 2,
                    maxLength: 200,
                    onChanged: (v) => observacion = v,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarVisita(
    BuildContext ctx,
    String clienteId,
    EstadoVisita estado,
    String? observacion,
    Position? position,
  ) {
    Navigator.of(ctx).pop();
    ref.read(fichaProvider.notifier).registrarVisita(
      clienteId: clienteId,
      estado: estado.dbValue,
      observacion: observacion,
      lat: position?.latitude,
      lng: position?.longitude,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${estado.label} registrado'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _estadoColor(EstadoVisita estado) {
    switch (estado) {
      case EstadoVisita.visitado:
        return AppColors.success;
      case EstadoVisita.noEncontrado:
        return AppColors.warning;
      case EstadoVisita.reagendado:
        return AppColors.info;
      case EstadoVisita.negocioCerrado:
        return AppColors.textSecondary;
      case EstadoVisita.pendiente:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fichaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.fichaTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(FichaState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(fichaProvider.notifier).loadFicha(widget.clienteId),
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    final cliente = state.cliente;
    if (cliente == null) {
      return Center(
        child: Text(AppStrings.noData,
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Encabezado(cliente: cliente),
          if (state.posicion != null)
            _PosicionSection(
              posicion: state.posicion!,
              calificacionSbs: cliente.calificacionSbs,
            ),
          if (state.historial.isNotEmpty)
            _HistorialSection(historial: state.historial),
          if (state.comportamiento.isNotEmpty)
            _ComportamientoSection(
              pagos: state.comportamiento,
              pctPuntual: state.pctPuntual,
              montoTotalPagado: state.montoTotalPagado,
              promedioDiasMora: state.promedioDiasMora,
            ),
          if (state.oferta != null)
            _OfertaSection(oferta: state.oferta!, onUsar: () {
              context.push('/solicitud', extra: {
                'clienteId': widget.clienteId,
                'monto': state.oferta!.montoMaximo,
                'plazo': state.oferta!.plazoSugeridoMeses,
                'tasa': state.oferta!.teaReferencial,
              });
            })
          else
            _SinOfertaSection(),
          _BotoneraAcciones(
            clienteId: cliente.id,
            nombreCliente: cliente.nombre,
            documento: cliente.documento,
            telefono: cliente.telefono,
            onRegistrarVisita: () => _mostrarOpcionesVisita(cliente.id, cliente.nombre, cliente.documento),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Encabezado extends ConsumerWidget {
  final FichaClienteModel cliente;

  const _Encabezado({required this.cliente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iniciales = cliente.nombre.isNotEmpty
        ? cliente.nombre.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

    // ════════════════════════════════════════════════════════════
    // 🔧 SUPABASE_COMENTADO: alertasCarteraProvider desactivado
    // ════════════════════════════════════════════════════════════
    // final alertasAsync = ref.watch(alertasCarteraProvider(cliente.id));
    final alertasAsync = AsyncValue<List<Map<String, dynamic>>>.data([]);
    // ════════════════════════════════════════════════════════════
    final w = context.screenWidth;
    final scale = (w / 375).clamp(0.8, 1.3);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * scale),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: w < 360 ? 28 : 36,
                backgroundColor: Colors.white24,
                child: Text(
                  iniciales.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w < 360 ? 22 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (alertasAsync.valueOrNull != null &&
                  alertasAsync.valueOrNull!.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${alertasAsync.valueOrNull!.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8 * scale),
            child: Text(
              cliente.nombre,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.sp(20).clamp(16.0, 24.0),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 8 * scale),
          SemaforoRiesgoGrande(calificacion: cliente.calificacionSbs),
          SizedBox(height: 16 * scale),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _infoChip(Icons.badge_outlined, Formatters.censoredDni(cliente.documento)),
              if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
                _infoChip(Icons.phone_outlined, Formatters.phone(cliente.telefono!)),
              if (cliente.direccion.isNotEmpty)
                _infoChip(Icons.location_on_outlined, cliente.direccion),
              if (cliente.tipoNegocio != null)
                _infoChip(Icons.store_outlined, cliente.tipoNegocio!),
              if (cliente.antiguedadNegocio != null)
                _infoChip(Icons.timeline_outlined, '${cliente.antiguedadNegocio} años'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PosicionSection extends StatelessWidget {
  final PosicionCliente posicion;
  final CalificacionSbs calificacionSbs;

  const _PosicionSection({
    required this.posicion,
    required this.calificacionSbs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.posicionTitle, Icons.account_balance_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _posicionRow(
                  AppStrings.deudaTotal,
                  Formatters.currency(posicion.deudaTotal),
                  Icons.trending_up,
                  AppColors.error,
                ),
                const Divider(height: 24),
                _posicionRow(
                  AppStrings.cuentasVigentes,
                  '${posicion.cuentasVigentes}',
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
                const SizedBox(height: 12),
                _posicionRow(
                  AppStrings.cuentasMora,
                  '${posicion.cuentasMora}',
                  Icons.warning_amber_outlined,
                  posicion.cuentasMora > 0 ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(height: 12),
                _posicionRow(
                  AppStrings.diasMayorMora,
                  '${posicion.diasMayorMora} días',
                  Icons.calendar_today_outlined,
                  posicion.diasMayorMora > 0 ? AppColors.error : AppColors.textSecondary,
                ),
                if (posicion.ultimoPago != null) ...[
                  const SizedBox(height: 12),
                  _posicionRow(
                    AppStrings.ultimoPago,
                    Formatters.date(posicion.ultimoPago!),
                    Icons.payments_outlined,
                    AppColors.textSecondary,
                  ),
                ],
                const SizedBox(height: 12),
                _posicionRow(
                  'Calificación SBS',
                  calificacionSbs.label,
                  Icons.description_outlined,
                  AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.traffic_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Semáforo SBS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    SemaforoRiesgo(calificacionSbs: calificacionSbs),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posicionRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
      ],
    );
  }
}

class _HistorialSection extends StatelessWidget {
  final List<CreditoHistorico> historial;

  const _HistorialSection({required this.historial});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.historialTitle, Icons.history_outlined),
          const SizedBox(height: 12),
          ...historial.map((credito) => _CreditoCard(credito: credito)),
        ],
      ),
    );
  }
}

class _CreditoCard extends StatelessWidget {
  final CreditoHistorico credito;

  const _CreditoCard({required this.credito});

  @override
  Widget build(BuildContext context) {
    final estadoColor = switch (credito.estado.toUpperCase()) {
      'PAGADO' => AppColors.success,
      'VIGENTE' => AppColors.info,
      'MORA' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.currency(credito.monto),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${credito.plazoMeses} meses · ${Formatters.percentage(credito.tea)} TEA',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                if (credito.fechaApertura != null)
                  Text(
                    Formatters.date(credito.fechaApertura!),
                    style: TextStyle(color: AppColors.textHint, fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  credito.estado,
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${Formatters.percentage(credito.porcentajePuntual)} puntual',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComportamientoSection extends StatelessWidget {
  final List<PagoMensual> pagos;
  final double pctPuntual;
  final double montoTotalPagado;
  final double promedioDiasMora;

  const _ComportamientoSection({
    required this.pagos,
    required this.pctPuntual,
    required this.montoTotalPagado,
    this.promedioDiasMora = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.comportamientoTitle, Icons.bar_chart_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: context.hp(25).clamp(140, 260),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxY(),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= pagos.length) {
                                return const SizedBox.shrink();
                              }
                              final p = pagos[idx];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _mesAbrev(p.mes),
                                  style: const TextStyle(fontSize: 9),
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: pagos.asMap().entries.map((e) {
                        final barColor = switch (e.value.status) {
                          StatusPago.puntual => AppColors.success,
                          StatusPago.mora => AppColors.error,
                          StatusPago.sinCuota => AppColors.border,
                        };
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.montoPagado > 0
                                  ? e.value.montoPagado
                                  : 0.5,
                              color: barColor,
                              width: 10,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _indicador(AppColors.success, 'Puntual'),
                    const SizedBox(width: 16),
                    _indicador(AppColors.error, 'Mora'),
                    const SizedBox(width: 16),
                    _indicador(AppColors.border, 'Sin cuota'),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    _stat(AppStrings.pctPuntual, Formatters.percentage(pctPuntual)),
                    const SizedBox(width: 16),
                    _stat(AppStrings.montoTotalPagado, Formatters.currency(montoTotalPagado)),
                    const SizedBox(width: 16),
                    _stat(AppStrings.promedioMora, '${promedioDiasMora.toStringAsFixed(0)} días'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _maxY() {
    final max = pagos.fold<double>(0, (m, p) => p.montoPagado > m ? p.montoPagado : m);
    return max > 0 ? max * 1.2 : 100;
  }

  String _mesAbrev(int mes) {
    const m = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
               'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return mes >= 1 && mes <= 12 ? m[mes] : '$mes';
  }

  Widget _indicador(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              )),
        ],
      ),
    );
  }
}

class _OfertaSection extends StatelessWidget {
  final OfertaPreaprobada oferta;
  final VoidCallback onUsar;

  const _OfertaSection({required this.oferta, required this.onUsar});

  @override
  Widget build(BuildContext context) {
    final calcResult = CalculadoraCredito.calcularCuota(
      monto: oferta.montoMaximo,
      tasaAnual: oferta.teaReferencial,
      plazoMeses: oferta.plazoSugeridoMeses,
    );
    final cuotaEstimada = calcResult['cuota'] as double;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.ofertaTitle, Icons.local_offer_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Preaprobado',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  Formatters.currency(oferta.montoMaximo),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ofertaDetalle('Plazo', '${oferta.plazoSugeridoMeses} meses'),
                    const SizedBox(width: 24),
                    _ofertaDetalle('TEA', Formatters.percentage(oferta.teaReferencial)),
                    const SizedBox(width: 24),
                    _ofertaDetalle('Cuota Est.', Formatters.currency(cuotaEstimada)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(AppStrings.nivelConfianza,
                        style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                    const Spacer(),
                    Text('${oferta.scoreConfianza}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: oferta.scoreConfianza / 100,
                    backgroundColor: AppColors.border,
                    color: AppColors.success,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.vigenciaOferta}: ${Formatters.date(oferta.fechaVencimiento)}',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onUsar,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text(AppStrings.btnUsarOferta),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ofertaDetalle(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

class _SinOfertaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.ofertaTitle, Icons.local_offer_outlined),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 32, color: AppColors.textHint),
                const SizedBox(height: 8),
                Text(
                  AppStrings.sinOferta,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotoneraAcciones extends ConsumerWidget {
  final String clienteId;
  final String nombreCliente;
  final String documento;
  final String? telefono;
  final VoidCallback onRegistrarVisita;

  const _BotoneraAcciones({
    required this.clienteId,
    required this.nombreCliente,
    required this.documento,
    this.telefono,
    required this.onRegistrarVisita,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (telefono != null && telefono!.isNotEmpty) {
                      launchUrl(
                        Uri.parse(
                            'tel:${telefono!.replaceAll(RegExp(r'\s'), '')}'),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text(AppStrings.btnLlamar),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.push('/solicitud', extra: {
                      'clienteId': clienteId,
                      'nombre': nombreCliente,
                      'documento': documento,
                      'telefono': telefono,
                    });
                  },
                  icon: const Icon(Icons.post_add_outlined, size: 18),
                  label: const Text(AppStrings.btnIniciarSolicitud),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final pos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      await ref
                          .read(fichaProvider.notifier)
                          .actualizarUbicacion(
                              clienteId, pos.latitude, pos.longitude);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ubicación actualizada'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo obtener la ubicación'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.my_location_outlined, size: 18),
                  label: const Text('Actualizar ubicación'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final asesorId = ref.read(authProvider).asesor?.id ?? '';
                    context.push('/buro/$clienteId', extra: {
                      'asesorId': asesorId,
                      'dniCliente': documento,
                      'nombreCliente': nombreCliente,
                      'solicitudId': null,
                    });
                  },
                  icon: const Icon(Icons.credit_score_outlined, size: 18),
                  label: const Text('Consultar buró'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRegistrarVisita,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text(AppStrings.btnRegistrarVisita),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionHeader(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ],
  );
}
