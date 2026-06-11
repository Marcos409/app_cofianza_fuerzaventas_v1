import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/prospeccion_models.dart';
import 'prospeccion_providers.dart';
import 'prospeccion_viewmodel.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class ProspeccionScreen extends ConsumerStatefulWidget {
  const ProspeccionScreen({super.key});

  @override
  ConsumerState<ProspeccionScreen> createState() => _ProspeccionScreenState();
}

class _ProspeccionScreenState extends ConsumerState<ProspeccionScreen> {
  final _documentoCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _ingresosCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(prospeccionProvider.notifier);
    _documentoCtrl.addListener(() => notifier.setDocumento(_documentoCtrl.text));
    _nombresCtrl.addListener(() => notifier.setNombres(_nombresCtrl.text));
    _apellidosCtrl.addListener(() => notifier.setApellidos(_apellidosCtrl.text));
    _ingresosCtrl.addListener(
        () => notifier.setIngresosEstimados(double.tryParse(_ingresosCtrl.text) ?? 0));
    _destinoCtrl.addListener(() => notifier.setDestinoCredito(_destinoCtrl.text));
  }

  @override
  void dispose() {
    _documentoCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _ingresosCtrl.dispose();
    _destinoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prospeccionProvider);
    final notifier = ref.read(prospeccionProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.prospeccionTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormularioProspecto(
              state: state,
              notifier: notifier,
              asesorId: ref.read(authProvider).asesor?.id ?? '',
              documentoCtrl: _documentoCtrl,
              nombresCtrl: _nombresCtrl,
              apellidosCtrl: _apellidosCtrl,
              ingresosCtrl: _ingresosCtrl,
              destinoCtrl: _destinoCtrl,
            ),
            if (state.resultado != null) ...[
              const SizedBox(height: 20),
              _ResultadoCard(resultado: state.resultado!),
            ],
            const SizedBox(height: 20),
            _DesertorSection(notifier: notifier),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FormularioProspecto extends StatelessWidget {
  final ProspeccionState state;
  final ProspeccionNotifier notifier;
  final String asesorId;
  final TextEditingController documentoCtrl;
  final TextEditingController nombresCtrl;
  final TextEditingController apellidosCtrl;
  final TextEditingController ingresosCtrl;
  final TextEditingController destinoCtrl;

  const _FormularioProspecto({
    required this.state,
    required this.notifier,
    required this.asesorId,
    required this.documentoCtrl,
    required this.nombresCtrl,
    required this.apellidosCtrl,
    required this.ingresosCtrl,
    required this.destinoCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos del Prospecto',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: documentoCtrl,
          decoration: InputDecoration(
            labelText: AppStrings.documentoField,
            hintText: AppStrings.documentoHint,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          keyboardType: TextInputType.number,
          maxLength: 8,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nombresCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.nombresField,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: apellidosCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.apellidosField,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DatePickerField(
          label: AppStrings.fechaNacimientoField,
          value: state.fechaNacimiento,
          onChanged: notifier.setFechaNacimiento,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: state.tipoNegocio.isNotEmpty ? state.tipoNegocio : null,
          decoration: InputDecoration(
            labelText: AppStrings.tipoNegocioField,
            prefixIcon: const Icon(Icons.store_outlined),
          ),
          items: AppStrings.tiposNegocio
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) {
            if (v != null) notifier.setTipoNegocio(v);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: NumberStepperField(
                label: AppStrings.antiguedadAnios,
                value: state.antiguedadAnios,
                onChanged: notifier.setAntiguedadAnios,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NumberStepperField(
                label: AppStrings.antiguedadMeses,
                value: state.antiguedadMeses,
                max: 11,
                onChanged: notifier.setAntiguedadMeses,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ingresosCtrl,
          decoration: InputDecoration(
            labelText: AppStrings.ingresosField,
            prefixIcon: const Icon(Icons.monetization_on_outlined),
            prefixText: 'S/ ',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.montoSolicitadoField}: ${Formatters.currency(state.montoSolicitado)}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text('S/ 500 — S/ 50,000',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            Slider(
              value: state.montoSolicitado.clamp(500, 50000),
              min: 500,
              max: 50000,
              divisions: 99,
              activeColor: AppColors.primary,
              onChanged: notifier.setMontoSolicitado,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: destinoCtrl,
          decoration: InputDecoration(
            labelText: AppStrings.destinoField,
            hintText: AppStrings.destinoHint,
            prefixIcon: const Icon(Icons.flag_outlined),
          ),
          maxLines: 2,
          maxLength: 200,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: state.canPreEvaluar
                ? () => notifier.preEvaluar(asesorId)
                : null,
            icon: state.formSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search_outlined),
            label: Text(state.formSubmitting
                ? AppStrings.evaluating
                : AppStrings.btnPreEvaluar),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  final ResultadoPreEvaluacion resultado;

  const _ResultadoCard({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color text, IconData icon, String msg) =
        switch (resultado.calificacion) {
      ResultadoCalificacion.apto => (
        AppColors.success.withValues(alpha: 0.06),
        AppColors.success.withValues(alpha: 0.3),
        AppColors.success,
        Icons.check_circle_outline,
        AppStrings.aptoMsg,
      ),
      ResultadoCalificacion.revisar => (
        AppColors.warning.withValues(alpha: 0.06),
        AppColors.warning.withValues(alpha: 0.3),
        AppColors.warning,
        Icons.warning_amber_outlined,
        AppStrings.revisarMsg,
      ),
      ResultadoCalificacion.noProcede => (
        AppColors.error.withValues(alpha: 0.06),
        AppColors.error.withValues(alpha: 0.3),
        AppColors.error,
        Icons.cancel_outlined,
        AppStrings.noProcedeMsg,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, color: text, size: 48),
          const SizedBox(height: 12),
          Text(
            resultado.calificacionLabel,
            style: TextStyle(
              color: text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(color: text, fontSize: 14),
          ),
          if (resultado.motivo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              resultado.motivo,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          if (resultado.puntajeEstimado > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Puntaje estimado: ${resultado.puntajeEstimado}',
              style: TextStyle(
                  color: text, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
            if (resultado.calificacion == ResultadoCalificacion.apto) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/solicitud', arguments: {
                    'monto': resultado.puntajeEstimado.toDouble(),
                  });
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text(AppStrings.btnIniciarSolicitudFormal),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (resultado.calificacion == ResultadoCalificacion.noProcede) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/campanas');
              },
              child: Text(AppStrings.btnInformarCliente,
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(1990, 1, 1),
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
          locale: const Locale('es'),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value != null ? Formatters.date(value!) : '',
          style: TextStyle(
            color: value != null ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _DesertorSection extends StatelessWidget {
  final ProspeccionNotifier notifier;

  const _DesertorSection({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(prospeccionProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),
            Text(
              AppStrings.registarDesercion,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MotivoDesercion>(
              decoration: InputDecoration(
                labelText: AppStrings.motivoDesercionField,
                prefixIcon: const Icon(Icons.exit_to_app_outlined),
              ),
              items: MotivoDesercion.values
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setMotivoDesercion(v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: AppStrings.institucionMigro,
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
              onChanged: (v) => notifier.setInstitucionMigro(v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProbabilidadRetorno>(
              decoration: InputDecoration(
                labelText: AppStrings.probabilidadRetorno,
                prefixIcon: const Icon(Icons.trending_up_outlined),
              ),
              items: ProbabilidadRetorno.values
                  .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name.toUpperCase())))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setProbabilidadRetorno(v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: AppStrings.observaciones,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
              onChanged: (v) => notifier.setObservacionesDesercion(v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.motivoDesercion != null
                    ? () => notifier.registrarDesercion()
                    : null,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text(AppStrings.registarDesercion),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NumberStepperField extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const NumberStepperField({
    super.key,
    required this.label,
    required this.value,
    this.max = 100,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
}
