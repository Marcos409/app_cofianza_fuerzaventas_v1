enum ResultadoCalificacion { apto, revisar, noProcede }

class ResultadoPreEvaluacion {
  final ResultadoCalificacion calificacion;
  final String motivo;
  final int puntajeEstimado;
  final bool pendienteSync;

  const ResultadoPreEvaluacion({
    required this.calificacion,
    this.motivo = '',
    this.puntajeEstimado = 0,
    this.pendienteSync = false,
  });

  factory ResultadoPreEvaluacion.fromJson(Map<String, dynamic> json) =>
      ResultadoPreEvaluacion(
        calificacion: _parseCalificacion(json['calificacion']?.toString() ?? ''),
        motivo: json['motivo']?.toString() ?? '',
        puntajeEstimado: (json['puntaje_estimado'] as num?)?.toInt() ?? 0,
        pendienteSync: (json['pendiente_sync'] as num?)?.toInt() == 1,
      );

  static ResultadoCalificacion _parseCalificacion(String value) {
    switch (value.toUpperCase()) {
      case 'APTO':
        return ResultadoCalificacion.apto;
      case 'REVISAR':
        return ResultadoCalificacion.revisar;
      case 'NO_PROCEDE':
      case 'NO PROCEDE':
        return ResultadoCalificacion.noProcede;
      default:
        return ResultadoCalificacion.revisar;
    }
  }

  String get calificacionLabel {
    switch (calificacion) {
      case ResultadoCalificacion.apto:
        return 'APTO';
      case ResultadoCalificacion.revisar:
        return 'REVISAR';
      case ResultadoCalificacion.noProcede:
        return 'NO PROCEDE';
    }
  }
}

class ProspectoModel {
  final String? id;
  final String? asesorId;
  final String documento;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final String tipoNegocio;
  final int antiguedadAnios;
  final int antiguedadMeses;
  final double ingresosEstimados;
  final double montoSolicitado;
  final String destinoCredito;
  final ResultadoPreEvaluacion? resultado;
  final bool pendienteSync;

  const ProspectoModel({
    this.id,
    this.asesorId,
    required this.documento,
    required this.nombres,
    required this.apellidos,
    this.fechaNacimiento,
    required this.tipoNegocio,
    this.antiguedadAnios = 0,
    this.antiguedadMeses = 0,
    required this.ingresosEstimados,
    required this.montoSolicitado,
    required this.destinoCredito,
    this.resultado,
    this.pendienteSync = false,
  });

  String get nombreCompleto => '$nombres $apellidos';

  ProspectoModel copyWith({
    String? id,
    String? asesorId,
    String? documento,
    String? nombres,
    String? apellidos,
    DateTime? fechaNacimiento,
    String? tipoNegocio,
    int? antiguedadAnios,
    int? antiguedadMeses,
    double? ingresosEstimados,
    double? montoSolicitado,
    String? destinoCredito,
    ResultadoPreEvaluacion? resultado,
    bool? pendienteSync,
  }) {
    return ProspectoModel(
      id: id ?? this.id,
      asesorId: asesorId ?? this.asesorId,
      documento: documento ?? this.documento,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      tipoNegocio: tipoNegocio ?? this.tipoNegocio,
      antiguedadAnios: antiguedadAnios ?? this.antiguedadAnios,
      antiguedadMeses: antiguedadMeses ?? this.antiguedadMeses,
      ingresosEstimados: ingresosEstimados ?? this.ingresosEstimados,
      montoSolicitado: montoSolicitado ?? this.montoSolicitado,
      destinoCredito: destinoCredito ?? this.destinoCredito,
      resultado: resultado ?? this.resultado,
      pendienteSync: pendienteSync ?? this.pendienteSync,
    );
  }

  Map<String, dynamic> toMap() => {
    'documento': documento,
    'nombres': nombres,
    'apellidos': apellidos,
    'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
    'tipo_negocio': tipoNegocio,
    'antiguedad_anios': antiguedadAnios,
    'antiguedad_meses': antiguedadMeses,
    'ingresos_estimados': ingresosEstimados,
    'monto_solicitado': montoSolicitado,
    'destino_credito': destinoCredito,
  };
}

enum TipoCampana { renovacion, ampliacion, productoParalelo }

class CampanaActivaModel {
  final String id;
  final String clienteId;
  final String nombreCliente;
  final TipoCampana tipo;
  final double montoOfertado;
  final DateTime fechaVencimiento;
  final bool activa;

  const CampanaActivaModel({
    required this.id,
    required this.clienteId,
    required this.nombreCliente,
    required this.tipo,
    required this.montoOfertado,
    required this.fechaVencimiento,
    this.activa = true,
  });

  factory CampanaActivaModel.fromJson(Map<String, dynamic> json) =>
      CampanaActivaModel(
        id: json['id']?.toString() ?? '',
        clienteId: json['cliente_id']?.toString() ?? '',
        nombreCliente: json['nombre_cliente']?.toString() ?? '',
        tipo: _parseTipo(json['tipo']?.toString() ?? ''),
        montoOfertado: (json['monto_ofertado'] as num?)?.toDouble() ?? 0,
        fechaVencimiento:
            DateTime.tryParse(json['fecha_vencimiento']?.toString() ?? '') ??
                DateTime.now(),
        activa: json['activa'] ?? true,
      );

  static TipoCampana _parseTipo(String value) {
    switch (value.toUpperCase()) {
      case 'RENOVACION':
        return TipoCampana.renovacion;
      case 'AMPLIACION':
        return TipoCampana.ampliacion;
      case 'PRODUCTO_PARALELO':
        return TipoCampana.productoParalelo;
      default:
        return TipoCampana.renovacion;
    }
  }

  int get diasRestantes => fechaVencimiento.difference(DateTime.now()).inDays.clamp(0, 999);

  String get tipoLabel {
    switch (tipo) {
      case TipoCampana.renovacion:
        return 'Renovación';
      case TipoCampana.ampliacion:
        return 'Ampliación';
      case TipoCampana.productoParalelo:
        return 'Prod. Paralelo';
    }
  }
}

enum MotivoDesercion {
  mejorOferta,
  insatisfaccion,
  problemasEconomicos,
  cambioDomicilio,
  fallecimiento,
  otro;

  String get label {
    switch (this) {
      case MotivoDesercion.mejorOferta:
        return 'Mejor oferta de otra entidad';
      case MotivoDesercion.insatisfaccion:
        return 'Insatisfacción con el servicio';
      case MotivoDesercion.problemasEconomicos:
        return 'Problemas económicos del cliente';
      case MotivoDesercion.cambioDomicilio:
        return 'Cambio de domicilio/ciudad';
      case MotivoDesercion.fallecimiento:
        return 'Fallecimiento';
      case MotivoDesercion.otro:
        return 'Otro';
    }
  }
}

enum ProbabilidadRetorno { alta, media, baja }
