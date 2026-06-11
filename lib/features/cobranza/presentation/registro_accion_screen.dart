import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/formatters.dart';
import '../domain/cliente_mora.dart';
import 'cobranza_providers.dart';
import 'cobranza_notifier.dart';

class RegistroAccionScreen extends ConsumerStatefulWidget {
  final ClienteMora cliente;
  final String asesorId;
  final VoidCallback onRegistrada;

  const RegistroAccionScreen({
    super.key,
    required this.cliente,
    required this.asesorId,
    required this.onRegistrada,
  });

  @override
  ConsumerState<RegistroAccionScreen> createState() =>
      _RegistroAccionScreenState();
}

class _RegistroAccionScreenState extends ConsumerState<RegistroAccionScreen> {
  final _tipoGestiones = ['visita', 'llamada', 'mensaje'];
  final _resultados = [
    'compromiso_pago',
    'pago_parcial',
    'sin_contacto',
    'se_niega',
  ];

  String? _tipoGestion;
  String? _resultado;
  final _montoPagadoCtrl = TextEditingController();
  final _montoCompromisoCtrl = TextEditingController();
  DateTime? _fechaCompromiso;
  final _observacionesCtrl = TextEditingController();

  Position? _position;
  bool _obteniendoGps = true;

  @override
  void initState() {
    super.initState();
    _obtenerPosicion();
  }

  Future<void> _obtenerPosicion() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) setState(() => _position = pos);
    } catch (_) {}
    if (mounted) setState(() => _obteniendoGps = false);
  }

  @override
  void dispose() {
    _montoPagadoCtrl.dispose();
    _montoCompromisoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cobranzaProvider(widget.asesorId));

    if (state.status == CobranzaStatus.registroExitoso) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRegistrada();
        Navigator.of(context).pop();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.cliente.nombreCliente),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClienteInfo(),
            const SizedBox(height: 20),
            _buildTipoGestion(),
            const SizedBox(height: 16),
            _buildResultado(),
            const SizedBox(height: 16),
            if (_resultado == 'pago_parcial') _buildMontoPagado(),
            if (_resultado == 'compromiso_pago') ...[
              _buildCompromisoFecha(),
              const SizedBox(height: 16),
              _buildCompromisoMonto(),
            ],
            const SizedBox(height: 16),
            _buildObservaciones(),
            const SizedBox(height: 16),
            _buildGpsIndicator(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _puedeEnviar(state)
                    ? () => _enviar(state)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: state.status == CobranzaStatus.registrando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Registrar gestión',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteInfo() {
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
            Text(widget.cliente.nombreCliente,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${widget.cliente.documentoCliente} · ${widget.cliente.diasMora} días de mora',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Monto vencido: S/ ${Formatters.currency(widget.cliente.montoVencido)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoGestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de gestión',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _tipoGestiones.map((t) {
            final selected = _tipoGestion == t;
            final icon = t == 'visita'
                ? Icons.person_pin
                : t == 'llamada'
                    ? Icons.phone
                    : Icons.message;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16,
                      color: selected ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(_labelTipo(t)),
                ],
              ),
              selected: selected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary),
              onSelected: (_) => setState(() => _tipoGestion = t),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resultado',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._resultados.map((r) {
          final selected = _resultado == r;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () => setState(() => _resultado = r),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(_labelResultado(r),
                        style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMontoPagado() {
    return TextField(
      controller: _montoPagadoCtrl,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Monto pagado (S/)',
        prefixIcon: Icon(Icons.monetization_on_outlined),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCompromisoFecha() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de compromiso',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _fechaCompromiso != null
              ? Formatters.date(_fechaCompromiso!)
              : 'Seleccionar fecha',
          style: TextStyle(
            color: _fechaCompromiso != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCompromisoMonto() {
    return TextField(
      controller: _montoCompromisoCtrl,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Monto comprometido (S/)',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildObservaciones() {
    return TextField(
      controller: _observacionesCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Observaciones',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildGpsIndicator() {
    return Row(
      children: [
        Icon(
          _obteniendoGps
              ? Icons.gps_fixed
              : _position != null
                  ? Icons.gps_off
                  : Icons.gps_not_fixed,
          size: 16,
          color: _position != null ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          _obteniendoGps
              ? 'Obteniendo ubicación...'
              : _position != null
                  ? 'Ubicación capturada'
                  : 'No se pudo obtener ubicación',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  bool _puedeEnviar(CobranzaState state) {
    if (state.status == CobranzaStatus.registrando) return false;
    if (_tipoGestion == null || _resultado == null) return false;
    if (_resultado == 'pago_parcial' && _montoPagadoCtrl.text.trim().isEmpty) return false;
    if (_resultado == 'compromiso_pago' && _fechaCompromiso == null) return false;
    return true;
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fechaCompromiso = picked);
  }

  void _enviar(CobranzaState state) {
    ref.read(cobranzaProvider(widget.asesorId).notifier).registrarAccion(
      clienteId: widget.cliente.clienteId,
      creditoId: widget.cliente.creditoId,
      tipoGestion: _tipoGestion!,
      resultado: _resultado!,
      montoPagado: double.tryParse(_montoPagadoCtrl.text.trim()),
      fechaCompromiso: _fechaCompromiso,
      montoCompromiso: double.tryParse(_montoCompromisoCtrl.text.trim()),
      observaciones: _observacionesCtrl.text.trim().isNotEmpty
          ? _observacionesCtrl.text.trim()
          : null,
      lat: _position?.latitude,
      lng: _position?.longitude,
    );
  }

  String _labelTipo(String t) {
    switch (t) {
      case 'visita': return 'Visita';
      case 'llamada': return 'Llamada';
      case 'mensaje': return 'Mensaje';
      default: return t;
    }
  }

  String _labelResultado(String r) {
    switch (r) {
      case 'compromiso_pago': return 'Compromiso de pago';
      case 'pago_parcial': return 'Pago parcial';
      case 'sin_contacto': return 'Sin contacto';
      case 'se_niega': return 'Se niega a pagar';
      default: return r;
    }
  }
}
