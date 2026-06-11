import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../domain/productividad_asesor.dart';
import 'reportes_providers.dart';
import 'reportes_notifier.dart';

class ProductividadScreen extends ConsumerStatefulWidget {
  final String agenciaId;

  const ProductividadScreen({super.key, required this.agenciaId});

  @override
  ConsumerState<ProductividadScreen> createState() =>
      _ProductividadScreenState();
}

class _ProductividadScreenState extends ConsumerState<ProductividadScreen> {
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(productividadProvider(widget.agenciaId).notifier)
          .cargarReporte();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productividadProvider(widget.agenciaId));

    return Column(
      children: [
        _buildSelectorMes(state),
        Expanded(child: _buildBody(state)),
      ],
    );
  }

  Widget _buildSelectorMes(ProductividadState state) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Setiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref
                .read(productividadProvider(widget.agenciaId).notifier)
                .mesAnterior(),
          ),
          Text(
            '${meses[state.mes - 1]} ${state.anio}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref
                .read(productividadProvider(widget.agenciaId).notifier)
                .mesSiguiente(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.error),
            tooltip: 'Exportar PDF',
            onPressed: state.status == ReportesStatus.data
                ? _exportarPdf
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ProductividadState state) {
    switch (state.status) {
      case ReportesStatus.initial:
      case ReportesStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ReportesStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(state.errorMessage ?? 'Error',
                  style: const TextStyle(color: AppColors.textSecondary)),
              ElevatedButton(
                onPressed: () => ref
                    .read(productividadProvider(widget.agenciaId).notifier)
                    .cargarReporte(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case ReportesStatus.data:
        return _buildReporte(state);
    }
  }

  Widget _buildReporte(ProductividadState state) {
    final reporte = state.reporte;
    if (reporte == null || reporte.asesores.isEmpty) {
      return const Center(child: Text('Sin datos para este período'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumen(reporte),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _repaintKey,
            child: _buildGrafico(reporte),
          ),
          const SizedBox(height: 16),
          _buildTabla(reporte),
        ],
      ),
    );
  }

  Widget _buildResumen(ReporteMensual r) {
    return Row(
      children: [
        _resumenItem('Enviadas', r.totalEnviadas, AppColors.primary),
        _resumenItem('Aprobadas', r.totalAprobadas, AppColors.success),
        _resumenItem('Desembolsadas', r.totalDesembolsadas, AppColors.info),
      ],
    );
  }

  Widget _resumenItem(String label, int valor, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text('$valor',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrafico(ReporteMensual r) {
    if (r.asesores.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Productividad por asesor',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxY(r),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= r.asesores.length) {
                            return const SizedBox.shrink();
                          }
                          final nombre = r.asesores[i].nombreAsesor;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              nombre.length > 6
                                  ? nombre.substring(0, 6)
                                  : nombre,
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _intervalo(r),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(r.asesores.length, (i) {
                    final a = r.asesores[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: a.enviadas.toDouble(),
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: a.aprobadas.toDouble(),
                          color: AppColors.success,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: a.desembolsadas.toDouble(),
                          color: AppColors.info,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLeyenda(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyenda() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _leyendaItem(AppColors.primary, 'Enviadas'),
        const SizedBox(width: 16),
        _leyendaItem(AppColors.success, 'Aprobadas'),
        const SizedBox(width: 16),
        _leyendaItem(AppColors.info, 'Desembolsadas'),
      ],
    );
  }

  Widget _leyendaItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildTabla(ReporteMensual r) {
    return Card(
      elevation: 0,
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalle por asesor',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Asesor')),
                  DataColumn(label: Text('Enviadas'), numeric: true),
                  DataColumn(label: Text('Aprobadas'), numeric: true),
                  DataColumn(label: Text('Desemb.'), numeric: true),
                  DataColumn(label: Text('Monto'), numeric: true),
                  DataColumn(label: Text('Tasa'), numeric: true),
                ],
                rows: r.asesores
                    .map((a) => DataRow(cells: [
                          DataCell(Text(a.nombreAsesor,
                              style: const TextStyle(fontSize: 13))),
                          DataCell(Text('${a.enviadas}')),
                          DataCell(Text('${a.aprobadas}')),
                          DataCell(Text('${a.desembolsadas}')),
                          DataCell(Text(
                              Formatters.currency(a.montoTotalAprobado))),
                          DataCell(Text(
                              '${a.tasaAprobacion.toStringAsFixed(1)}%')),
                        ]))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _maxY(ReporteMensual r) {
    double max = 0;
    for (final a in r.asesores) {
      if (a.enviadas > max) max = a.enviadas.toDouble();
      if (a.aprobadas > max) max = a.aprobadas.toDouble();
      if (a.desembolsadas > max) max = a.desembolsadas.toDouble();
    }
    return max + 2;
  }

  double _intervalo(ReporteMensual r) {
    final max = _maxY(r);
    if (max <= 5) return 1;
    if (max <= 20) return 5;
    return 10;
  }

  Future<void> _exportarPdf() async {
    final state = ref.read(productividadProvider(widget.agenciaId));
    final reporte = state.reporte;
    if (reporte == null) return;

    final pdf = pw.Document();
    final imageBytes = await _capturarGrafico();
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Setiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final periodo = '${meses[state.mes - 1]} ${state.anio}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text('Reporte de Productividad',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Período: $periodo',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'Asesor',
              'Enviadas',
              'Aprobadas',
              'Desemb.',
              'Monto',
              'Tasa',
            ],
            data: reporte.asesores
                .map((a) => [
                      a.nombreAsesor,
                      '${a.enviadas}',
                      '${a.aprobadas}',
                      '${a.desembolsadas}',
                      'S/ ${Formatters.currency(a.montoTotalAprobado)}',
                      '${a.tasaAprobacion.toStringAsFixed(1)}%',
                    ])
                .toList(),
          ),
          if (imageBytes != null) ...[
            pw.SizedBox(height: 24),
            pw.Text('Gráfico de Productividad',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Image(pw.MemoryImage(imageBytes)),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'productividad_$periodo.pdf',
    );
  }

  Future<Uint8List?> _capturarGrafico() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
