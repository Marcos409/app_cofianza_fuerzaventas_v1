import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
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
  SolicitudModel? _solicitudActual;
  Timer? _pollTimer;

  bool get _debeRefrescar {
    final e = _solicitudActual?.estado ?? widget.solicitud.estado;
    return e == EstadoSolicitud.enProceso ||
        e == EstadoSolicitud.enviado ||
        e == EstadoSolicitud.recibidoComite ||
        e == EstadoSolicitud.enEvaluacion;
  }

  @override
  void initState() {
    super.initState();
    _solicitudActual = widget.solicitud;
    Future.microtask(() {
      ref
          .read(estadoNotifierFamilyProvider(widget.solicitud.asesorId).notifier)
          .cargarNotas(widget.solicitud.id);
    });
    _iniciarPolling();
  }

  void _iniciarPolling() {
    if (!_debeRefrescar) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) { _pollTimer?.cancel(); return; }
      try {
        final apiData = await ApiClient.instance.get<Map<String, dynamic>>('/solicitudes/${widget.solicitud.id}');
        if (!mounted) return;
        final nuevoEstadoStr = apiData['estado']?.toString() ?? '';
        if (nuevoEstadoStr.isEmpty) return;
        final nuevoEstado = EstadoSolicitud.fromString(nuevoEstadoStr);
        if (nuevoEstado == _solicitudActual!.estado) return;
        final updated = _solicitudActual!.copyWith(
          estado: nuevoEstado,
          numeroExpediente: apiData['numero_expediente']?.toString() ?? _solicitudActual!.numeroExpediente,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DetalleSolicitudScreen(solicitud: updated),
          ),
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/documentos/${s.id}'),
                icon: const Icon(Icons.description_outlined, size: 20),
                label: const Text('Documentos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (s.estado == EstadoSolicitud.enviado ||
                s.estado == EstadoSolicitud.enProceso) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/transmision/${s.id}'),
                  icon: const Icon(Icons.send, size: 20),
                  label: const Text('Enviar a comité'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _generarPdfEstado(s),
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                label: const Text('Compartir estado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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

  Future<void> _enviarComite(SolicitudModel s) async {
    final api = ApiClient.instance;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final payload = {
        'id': s.id,
        'numero_documento': s.solicitante.documento,
        'nombres': s.solicitante.nombres,
        'apellidos': s.solicitante.apellidos,
        'telefono': s.solicitante.telefono,
        'email': s.solicitante.email,
        'estado_civil': s.solicitante.estadoCivil,
        'tipo_negocio': s.negocio.tipoNegocio,
        'nombre_negocio': s.negocio.nombreNegocio,
        'direccion_negocio': s.negocio.direccionNegocio,
        'ingresos_estimados': s.negocio.ingresosMensuales,
        'gastos_mensuales': s.negocio.gastosMensuales,
        'patrimonio': s.negocio.patrimonio,
        'destino_credito': s.negocio.destinoCredito,
        'actividad_economica': s.negocio.actividadEconomica,
        'monto_solicitado': s.credito.montoSolicitado,
        'plazo_meses': s.credito.plazoMeses,
        'moneda': s.credito.moneda,
      };
      try {
        await api.dio.post('/solicitudes', data: payload);
      } on DioException catch (_) {}
      await api.dio.post('/solicitudes/${s.id}/enviar-comite');
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final updated = s.copyWith(estado: EstadoSolicitud.recibidoComite);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DetalleSolicitudScreen(solicitud: updated),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada al comité')),
      );
    } on DioException catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.response?.data?['detail']?.toString() ?? e.message ?? 'Error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generarPdfEstado(SolicitudModel s) async {
    final pdf = pw.Document();

    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/logo.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {}

    final grupo = GrupoEstado.fromEstadoSolicitud(s.estado);
    final nombre = s.nombreCliente.isNotEmpty
        ? s.nombreCliente
        : '${s.solicitante.nombres} ${s.solicitante.apellidos}';
    final documento = s.solicitante.documento.length > 6
        ? '***${s.solicitante.documento.substring(s.solicitante.documento.length - 4)}'
        : s.solicitante.documento;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          if (logoBytes != null)
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                height: 60,
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text('Estado de Solicitud',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 24),
          pw.Header(
            level: 1,
            child: pw.Text('Datos del cliente'),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Nombre:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(nombre),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Documento:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(documento),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Header(
            level: 1,
            child: pw.Text('Condiciones del crédito'),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Monto solicitado:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('S/ ${formatearNumero(s.credito.montoSolicitado)}'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Plazo:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${s.credito.plazoMeses} meses'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cuota estimada:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('S/ ${formatearNumero(s.cuotaEstimada)}'),
            ],
          ),
          if (s.teaReferencial > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TEA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${s.teaReferencial.toStringAsFixed(2)}%'),
              ],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Header(
            level: 1,
            child: pw.Text('Estado actual'),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Estado:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt((Color(grupo.color).withOpacity(0.15)).value),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(s.estado.label),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Fecha:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(Formatters.date(DateTime.now())),
            ],
          ),
          if (s.numeroExpediente.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Expediente:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(s.numeroExpediente),
              ],
            ),
          ],
          pw.SizedBox(height: 32),
          pw.Center(
            child: pw.Text(
              'Documento generado el ${Formatters.date(DateTime.now())}',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'estado_solicitud_${s.numeroExpediente.isNotEmpty ? s.numeroExpediente : s.id}.pdf',
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
