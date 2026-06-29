import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/stepper_solicitud.dart';
import '../../../shared/widgets/signature_pad.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'solicitud_providers.dart';
import 'solicitud_viewmodel.dart';
import '../domain/solicitud_model.dart';

class SolicitudScreen extends ConsumerStatefulWidget {
  final String? clienteId;
  final String? nombreCliente;
  final String? documentoCliente;
  final String? telefonoCliente;
  final double? montoPrefill;
  final int? plazoPrefill;
  final double? tasaPrefill;

  const SolicitudScreen({
    super.key,
    this.clienteId,
    this.nombreCliente,
    this.documentoCliente,
    this.telefonoCliente,
    this.montoPrefill,
    this.plazoPrefill,
    this.tasaPrefill,
  });

  @override
  ConsumerState<SolicitudScreen> createState() => _SolicitudScreenState();
}

class _SolicitudScreenState extends ConsumerState<SolicitudScreen> {
  final _pageController = PageController();

  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _documentoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;

  late final TextEditingController _nombreNegocioCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _ingresosCtrl;
  late final TextEditingController _gastosCtrl;
  late final TextEditingController _patrimonioCtrl;
  late final TextEditingController _destinoCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(solicitudProvider);

    var solicitante = state.solicitante;
    var credito = state.credito;

    if (widget.nombreCliente != null || widget.documentoCliente != null || widget.telefonoCliente != null) {
      final combinedName = widget.nombreCliente ?? '';
      final parts = combinedName.split(' ');
      final nombres = parts.isNotEmpty ? parts.first : '';
      final apellidos = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      solicitante = solicitante.copyWith(
        nombres: nombres.isNotEmpty ? nombres : solicitante.nombres,
        apellidos: apellidos.isNotEmpty ? apellidos : solicitante.apellidos,
        documento: widget.documentoCliente ?? solicitante.documento,
        telefono: widget.telefonoCliente ?? solicitante.telefono,
      );
    }

    if (widget.montoPrefill != null || widget.plazoPrefill != null) {
      credito = credito.copyWith(
        montoSolicitado: widget.montoPrefill ?? credito.montoSolicitado,
        plazoMeses: widget.plazoPrefill ?? credito.plazoMeses,
      );
    }

    // Update state synchronously in a post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(solicitudProvider.notifier);
      notifier.updateSolicitante(solicitante);
      notifier.updateCredito(credito);
    });

    _nombresCtrl = TextEditingController(text: solicitante.nombres);
    _apellidosCtrl = TextEditingController(text: solicitante.apellidos);
    _documentoCtrl = TextEditingController(text: solicitante.documento);
    _telefonoCtrl = TextEditingController(text: solicitante.telefono);
    _emailCtrl = TextEditingController(text: solicitante.email);

    _nombreNegocioCtrl = TextEditingController(text: state.negocio.nombreNegocio);
    _direccionCtrl = TextEditingController(text: state.negocio.direccionNegocio);
    _ingresosCtrl = TextEditingController(
        text: state.negocio.ingresosMensuales > 0 ? state.negocio.ingresosMensuales.toStringAsFixed(0) : '');
    _gastosCtrl = TextEditingController(
        text: state.negocio.gastosMensuales > 0 ? state.negocio.gastosMensuales.toStringAsFixed(0) : '');
    _patrimonioCtrl = TextEditingController(
        text: state.negocio.patrimonio > 0 ? state.negocio.patrimonio.toStringAsFixed(0) : '');
    _destinoCtrl = TextEditingController(text: state.negocio.destinoCredito);

    final notifier = ref.read(solicitudProvider.notifier);
    _nombresCtrl.addListener(() => notifier.updateSolicitante(ref.read(solicitudProvider).solicitante.copyWith(nombres: _nombresCtrl.text)));
    _apellidosCtrl.addListener(() => notifier.updateSolicitante(ref.read(solicitudProvider).solicitante.copyWith(apellidos: _apellidosCtrl.text)));
    _documentoCtrl.addListener(() => notifier.updateSolicitante(ref.read(solicitudProvider).solicitante.copyWith(documento: _documentoCtrl.text)));
    _telefonoCtrl.addListener(() => notifier.updateSolicitante(ref.read(solicitudProvider).solicitante.copyWith(telefono: _telefonoCtrl.text)));
    _emailCtrl.addListener(() => notifier.updateSolicitante(ref.read(solicitudProvider).solicitante.copyWith(email: _emailCtrl.text)));

    _nombreNegocioCtrl.addListener(() => notifier.updateNegocio(ref.read(solicitudProvider).negocio.copyWith(nombreNegocio: _nombreNegocioCtrl.text)));
    _direccionCtrl.addListener(() => notifier.updateNegocio(ref.read(solicitudProvider).negocio.copyWith(direccionNegocio: _direccionCtrl.text)));
    _ingresosCtrl.addListener(() => notifier.updateNegocio(ref.read(solicitudProvider).negocio.copyWith(ingresosMensuales: double.tryParse(_ingresosCtrl.text) ?? 0)));
    _gastosCtrl.addListener(() => notifier.updateNegocio(ref.read(solicitudProvider).negocio.copyWith(gastosMensuales: double.tryParse(_gastosCtrl.text) ?? 0)));
    _patrimonioCtrl.addListener(() => notifier.updateNegocio(ref.read(solicitudProvider).negocio.copyWith(patrimonio: double.tryParse(_patrimonioCtrl.text) ?? 0)));
    _destinoCtrl.addListener(() => notifier.updateNegocio(ref.read(solicitudProvider).negocio.copyWith(destinoCredito: _destinoCtrl.text)));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _documentoCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _nombreNegocioCtrl.dispose();
    _direccionCtrl.dispose();
    _ingresosCtrl.dispose();
    _gastosCtrl.dispose();
    _patrimonioCtrl.dispose();
    _destinoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(solicitudProvider);
    final notifier = ref.read(solicitudProvider.notifier);

    // Keep controllers synced if state is changed externally (like loading draft)
    ref.listen<SolicitudFormState>(solicitudProvider, (previous, next) {
      if (next.solicitante.nombres != _nombresCtrl.text) {
        _nombresCtrl.text = next.solicitante.nombres;
      }
      if (next.solicitante.apellidos != _apellidosCtrl.text) {
        _apellidosCtrl.text = next.solicitante.apellidos;
      }
      if (next.solicitante.documento != _documentoCtrl.text) {
        _documentoCtrl.text = next.solicitante.documento;
      }
      if (next.solicitante.telefono != _telefonoCtrl.text) {
        _telefonoCtrl.text = next.solicitante.telefono;
      }
      if (next.solicitante.email != _emailCtrl.text) {
        _emailCtrl.text = next.solicitante.email;
      }
      if (next.negocio.nombreNegocio != _nombreNegocioCtrl.text) {
        _nombreNegocioCtrl.text = next.negocio.nombreNegocio;
      }
      if (next.negocio.direccionNegocio != _direccionCtrl.text) {
        _direccionCtrl.text = next.negocio.direccionNegocio;
      }
      final ingresosText = next.negocio.ingresosMensuales > 0 ? next.negocio.ingresosMensuales.toStringAsFixed(0) : '';
      if (ingresosText != _ingresosCtrl.text) {
        _ingresosCtrl.text = ingresosText;
      }
      final gastosText = next.negocio.gastosMensuales > 0 ? next.negocio.gastosMensuales.toStringAsFixed(0) : '';
      if (gastosText != _gastosCtrl.text) {
        _gastosCtrl.text = gastosText;
      }
      if (next.negocio.destinoCredito != _destinoCtrl.text) {
        _destinoCtrl.text = next.negocio.destinoCredito;
      }
      final patrimonioText = next.negocio.patrimonio > 0 ? next.negocio.patrimonio.toStringAsFixed(0) : '';
      if (patrimonioText != _patrimonioCtrl.text) {
        _patrimonioCtrl.text = patrimonioText;
      }

      if (_pageController.hasClients && _pageController.page?.round() != next.pasoActual) {
        _pageController.animateToPage(
          next.pasoActual,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showSalirDialog(notifier);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(AppStrings.solicitudTitle),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showSalirDialog(notifier),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                final asesorId = ref.read(authProvider).asesor?.id ?? '';
                notifier.guardarBorrador(asesorId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Borrador guardado localmente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('GUARDAR BORRADOR', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: _buildBody(state, notifier),
      ),
    );
  }

  Widget _buildBody(SolicitudFormState state, SolicitudNotifier notifier) {
    if (state.expedienteGenerado != null) {
      return _ExitoView(
        expediente: state.expedienteGenerado!,
        onNueva: () {
          notifier.resetForm();
          setState(() {});
        },
        onCerrar: () => Navigator.of(context).pop(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: StepperSolicitud(currentStep: state.pasoActual),
        ),
        if (state.camposError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: AppColors.error.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.camposError!,
                      style: TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ),
                GestureDetector(
                  onTap: notifier.clearCamposError,
                  child: Icon(Icons.close, size: 16, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => notifier.setPaso(i),
            children: [
              _Paso1(
                state: state,
                notifier: notifier,
                nombresCtrl: _nombresCtrl,
                apellidosCtrl: _apellidosCtrl,
                documentoCtrl: _documentoCtrl,
                telefonoCtrl: _telefonoCtrl,
                emailCtrl: _emailCtrl,
              ),
              _Paso2(
                state: state,
                notifier: notifier,
                nombreNegocioCtrl: _nombreNegocioCtrl,
                direccionCtrl: _direccionCtrl,
                ingresosCtrl: _ingresosCtrl,
                gastosCtrl: _gastosCtrl,
                patrimonioCtrl: _patrimonioCtrl,
                destinoCtrl: _destinoCtrl,
              ),
              _Paso3(state: state, notifier: notifier),
              _Paso4(
                state: state,
                notifier: notifier,
                onEnviar: () {
                  final asesorId = ref.read(authProvider).asesor?.id ?? '';
                  notifier.enviarSolicitud(asesorId);
                },
              ),
            ],
          ),
        ),
        _PasoNavegacion(state: state, notifier: notifier),
      ],
    );
  }

  void _showSalirDialog(SolicitudNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir del formulario'),
        content: const Text(
            '¿Desea guardar los datos como borrador antes de salir?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Descartar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final asesorId = ref.read(authProvider).asesor?.id ?? '';
              notifier.guardarBorrador(asesorId);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.saveDraft),
          ),
        ],
      ),
    );
  }
}

class _PasoNavegacion extends StatelessWidget {
  final SolicitudFormState state;
  final SolicitudNotifier notifier;

  const _PasoNavegacion({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.pasoActual > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.retrocederPaso,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text(AppStrings.back),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (state.pasoActual > 0 && state.pasoActual < 3) const SizedBox(width: 12),
          if (state.pasoActual < 3)
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  if (!notifier.avanzarPaso()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Complete todos los campos requeridos y corrija errores'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text(AppStrings.next),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- PASO 1 ---

class _Paso1 extends StatelessWidget {
  final SolicitudFormState state;
  final SolicitudNotifier notifier;
  final TextEditingController nombresCtrl;
  final TextEditingController apellidosCtrl;
  final TextEditingController documentoCtrl;
  final TextEditingController telefonoCtrl;
  final TextEditingController emailCtrl;

  const _Paso1({
    required this.state,
    required this.notifier,
    required this.nombresCtrl,
    required this.apellidosCtrl,
    required this.documentoCtrl,
    required this.telefonoCtrl,
    required this.emailCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final s = state.solicitante;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.stepPersonal,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _campo(
            label: 'Nombres',
            controller: nombresCtrl,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Apellidos',
            controller: apellidosCtrl,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Documento',
            controller: documentoCtrl,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            maxLength: 8,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: s.fechaNacimiento ?? DateTime(1995, 1, 1),
                firstDate: DateTime(DateTime.now().year - 75, 1, 1),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                locale: const Locale('es'),
              );
              if (picked != null) {
                notifier.updateSolicitante(
                    s.copyWith(fechaNacimiento: picked));
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de nacimiento',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                s.fechaNacimiento != null
                    ? Formatters.date(s.fechaNacimiento!)
                    : '',
                style: TextStyle(
                  color: s.fechaNacimiento != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Estado civil',
            value: s.estadoCivil.isEmpty ? null : s.estadoCivil,
            items: const ['Soltero', 'Casado', 'Conviviente', 'Divorciado', 'Viudo'],
            onChanged: (v) {
              if (v != null) {
                notifier.updateSolicitante(s.copyWith(estadoCivil: v));
              }
            },
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Grado de instrucción',
            value: s.gradoInstruccion.isEmpty ? null : s.gradoInstruccion,
            items: const ['Primaria', 'Secundaria', 'Técnico', 'Universitario'],
            onChanged: (v) {
              if (v != null) {
                notifier.updateSolicitante(s.copyWith(gradoInstruccion: v));
              }
            },
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Teléfono',
            controller: telefonoCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 9,
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Correo electrónico (opcional)',
            controller: emailCtrl,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// --- PASO 2 ---

class _Paso2 extends StatelessWidget {
  final SolicitudFormState state;
  final SolicitudNotifier notifier;
  final TextEditingController nombreNegocioCtrl;
  final TextEditingController direccionCtrl;
  final TextEditingController ingresosCtrl;
  final TextEditingController gastosCtrl;
  final TextEditingController patrimonioCtrl;
  final TextEditingController destinoCtrl;

  const _Paso2({
    required this.state,
    required this.notifier,
    required this.nombreNegocioCtrl,
    required this.direccionCtrl,
    required this.ingresosCtrl,
    required this.gastosCtrl,
    required this.patrimonioCtrl,
    required this.destinoCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final n = state.negocio;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.stepAddress,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _dropdown(
            label: 'Tipo de negocio',
            value: n.tipoNegocio.isEmpty ? null : n.tipoNegocio,
            items: const ['Comercio', 'Servicios', 'Producción', 'Agropecuario'],
            onChanged: (v) {
              if (v != null) {
                notifier.updateNegocio(n.copyWith(tipoNegocio: v));
              }
            },
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Nombre del negocio',
            controller: nombreNegocioCtrl,
            icon: Icons.store_outlined,
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Dirección del negocio',
            controller: direccionCtrl,
            icon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stepper(
                  label: 'Antigüedad Años',
                  value: n.antiguedadAnios,
                  onChanged: (v) =>
                      notifier.updateNegocio(n.copyWith(antiguedadAnios: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _stepper(
                  label: 'Antigüedad Meses',
                  value: n.antiguedadMeses,
                  max: 11,
                  onChanged: (v) =>
                      notifier.updateNegocio(n.copyWith(antiguedadMeses: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Ingresos estimados mensuales',
            controller: ingresosCtrl,
            icon: Icons.monetization_on_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: 'S/ ',
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Gastos mensuales',
            controller: gastosCtrl,
            icon: Icons.money_off_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: 'S/ ',
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Patrimonio estimado (opcional)',
            controller: patrimonioCtrl,
            icon: Icons.account_balance_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: 'S/ ',
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Actividad económica (CIIU)',
            value: n.actividadEconomica.isEmpty
                ? null
                : n.actividadEconomica,
            items: const [
              'Agricultura, ganadería, silvicultura',
              'Pesca',
              'Explotación de minas',
              'Industrias manufactureras',
              'Construcción',
              'Comercio al por mayor y menor',
              'Transporte y almacenamiento',
              'Alojamiento y servicios de comida',
              'Información y comunicaciones',
              'Actividades financieras',
              'Actividades inmobiliarias',
              'Actividades profesionales',
              'Servicios administrativos',
              'Enseñanza',
              'Servicios de salud',
              'Arte y entretenimiento',
              'Otros servicios',
            ],
            onChanged: (v) {
              if (v != null) {
                notifier.updateNegocio(n.copyWith(actividadEconomica: v));
              }
            },
          ),
          const SizedBox(height: 12),
          _campo(
            label: 'Destino del crédito (máx 500 caracteres)',
            controller: destinoCtrl,
            icon: Icons.flag_outlined,
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// --- PASO 3 ---

class _Paso3 extends StatelessWidget {
  final SolicitudFormState state;
  final SolicitudNotifier notifier;

  const _Paso3({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final c = state.credito;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Condiciones del crédito',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monto solicitado: ${Formatters.currency(c.montoSolicitado)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('S/ 500 — S/ 150,000',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              Slider(
                value: c.montoSolicitado.clamp(500, 150000),
                min: 500,
                max: 150000,
                divisions: 299,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    notifier.updateCredito(c.copyWith(montoSolicitado: v)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Plazo en meses',
            value: c.plazoMeses.toString(),
            items: const ['3', '6', '12', '18', '24', '36', '48', '60'],
            onChanged: (v) {
              if (v != null) {
                notifier.updateCredito(
                    c.copyWith(plazoMeses: int.tryParse(v) ?? 12));
              }
            },
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Tipo de cuota',
            value: c.tipoCuota.name,
            items: const ['mensual', 'quincenal', 'semanal'],
            itemLabels: const ['Mensual', 'Quincenal', 'Semanal'],
            onChanged: (v) {
              if (v != null) {
                notifier.updateCredito(c.copyWith(
                    tipoCuota: TipoCuota.values.firstWhere(
                        (e) => e.name == v,
                        orElse: () => TipoCuota.mensual)));
              }
            },
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Garantía',
            value: c.garantia.name,
            items: const ['sinGarantia', 'aval', 'hipotecaria', 'prendaria'],
            itemLabels: const [
              'Sin garantía',
              'Aval',
              'Hipotecaria',
              'Prendaria'
            ],
            onChanged: (v) {
              if (v != null) {
                notifier.updateCredito(c.copyWith(
                    garantia: TipoGarantia.values.firstWhere(
                        (e) => e.name == v,
                        orElse: () => TipoGarantia.sinGarantia)));
              }
            },
          ),
          const SizedBox(height: 20),
          _TarjetaSimulacion(
            monto: c.montoSolicitado,
            plazo: c.plazoMeses,
            cuota: state.cuotaEstimada,
            totalPagar: state.totalPagarEstimado,
            tea: teaReferencialDefault,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TarjetaSimulacion extends StatelessWidget {
  final double monto;
  final int plazo;
  final double cuota;
  final double totalPagar;
  final double tea;

  const _TarjetaSimulacion({
    required this.monto,
    required this.plazo,
    required this.cuota,
    required this.totalPagar,
    required this.tea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_outlined,
                  size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Simulador en Tiempo Real',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const Divider(height: 20),
          _simRow('Cuota estimada',
              cuota > 0 ? Formatters.currency(cuota) : '—'),
          const SizedBox(height: 8),
          _simRow('Total a pagar',
              totalPagar > 0 ? Formatters.currency(totalPagar) : '—'),
          const SizedBox(height: 8),
          _simRow('TEA referencial', '${(tea * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _simRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

// --- PASO 4 ---

class _Paso4 extends StatelessWidget {
  final SolicitudFormState state;
  final SolicitudNotifier notifier;
  final VoidCallback onEnviar;

  const _Paso4({
    required this.state,
    required this.notifier,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirmación y firma',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumen de la Solicitud',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                _resumenItem('Solicitante', state.solicitante.nombres.isNotEmpty
                    ? '${state.solicitante.nombres} ${state.solicitante.apellidos}'
                    : '—'),
                _resumenItem('Documento', state.solicitante.documento.isNotEmpty
                    ? state.solicitante.documento
                    : '—'),
                _resumenItem('Negocio', state.negocio.nombreNegocio.isNotEmpty
                    ? state.negocio.nombreNegocio
                    : '—'),
                _resumenItem('Tipo de Negocio', state.negocio.tipoNegocio.isNotEmpty
                    ? state.negocio.tipoNegocio
                    : '—'),
                _resumenItem('Monto solicitado',
                    Formatters.currency(state.credito.montoSolicitado)),
                _resumenItem('Plazo', '${state.credito.plazoMeses} meses'),
                _resumenItem('Garantía', state.credito.garantia.name),
                _resumenItem('Cuota estimada',
                    Formatters.currency(state.cuotaEstimada)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: state.datosVeraces,
                onChanged: (v) => notifier.setDatosVeraces(v ?? false),
                activeColor: AppColors.primary,
              ),
              const Expanded(
                child: Text(
                  'El cliente declara que los datos son veraces',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Firma digital del cliente',
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SignaturePad(
            onSignatureChanged: notifier.setFirma,
          ),
          if (state.isSubmitting)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: (state.datosVeraces && state.firmaBase64.isNotEmpty && !state.isSubmitting)
                  ? onEnviar
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('GUARDAR SOLICITUD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _resumenItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

// --- ÉXITO ---

class _ExitoView extends StatelessWidget {
  final String expediente;
  final VoidCallback onNueva;
  final VoidCallback onCerrar;

  const _ExitoView({
    required this.expediente,
    required this.onNueva,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 72, color: AppColors.success),
            const SizedBox(height: 16),
            const Text('Solicitud enviada',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text('Expediente: $expediente',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNueva,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva solicitud'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onCerrar,
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPERS ---

Widget _campo({
  required String label,
  required TextEditingController controller,
  IconData? icon,
  TextInputType? keyboardType,
  int? maxLength,
  int? maxLines = 1,
  String? prefix,
}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      prefixText: prefix,
      counterText: '',
    ),
    keyboardType: keyboardType,
    maxLength: maxLength,
    maxLines: maxLines,
  );
}

Widget _dropdown({
  required String label,
  required String? value,
  required List<String> items,
  List<String>? itemLabels,
  required ValueChanged<String?> onChanged,
}) {
  return InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        items: items.map((item) {
          final idx = items.indexOf(item);
          return DropdownMenuItem(
            value: item,
            child: Text(itemLabels != null ? itemLabels[idx] : item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

Widget _stepper({
  required String label,
  required int value,
  required ValueChanged<int> onChanged,
  int max = 100,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 4),
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          Text('$value',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    ],
  );
}
