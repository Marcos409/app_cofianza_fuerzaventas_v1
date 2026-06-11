import '../../features/buro/domain/consulta_buro_model.dart';

String interpretarResultadoBuro(ResultadoBuro datos) {
  final buffer = StringBuffer();

  final deudaFormateada = datos.deudaTotal.toStringAsFixed(0);

  final tieneEntidades = datos.numEntidadesDeuda > 0;
  final tieneMora = datos.diasMayorMora > 0;

  if (tieneEntidades) {
    buffer.write(
      'El cliente tiene historial en ${datos.numEntidadesDeuda} entidades '
      'con deuda total de S/$deudaFormateada.',
    );
  } else {
    buffer.write('El cliente no registra deuda activa en el sistema.');
  }

  if (tieneMora) {
    buffer.write(
      ' Registra mora histórica de ${datos.diasMayorMora} días, '
      'con una mayor deuda individual de S/${datos.mayorDeuda.toStringAsFixed(0)}.',
    );
  } else {
    buffer.write(' Sin mora histórica.');
  }

  switch (datos.calificacionSbs) {
    case CalificacionSbs.normal:
      buffer.write(' Recomendación: proceder con la evaluación.');
    case CalificacionSbs.cpp:
      buffer.write(' Recomendación: evaluar con precaución, CPP vigente.');
    case CalificacionSbs.deficiente:
      buffer.write(' Recomendación: solicitar garantías adicionales.');
    case CalificacionSbs.dudoso:
    case CalificacionSbs.perdida:
      buffer.write(' Recomendación: no procede la solicitud.');
  }

  return buffer.toString();
}
