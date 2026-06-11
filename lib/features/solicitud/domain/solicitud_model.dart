import 'dart:convert';

enum EstadoSolicitud {
  borrador,
  enviado,
  recibidoComite,
  enEvaluacion,
  aprobado,
  condicionado,
  rechazado,
  desembolsado;

  String get label {
    switch (this) {
      case EstadoSolicitud.borrador:
        return 'Borrador';
      case EstadoSolicitud.enviado:
        return 'Enviado';
      case EstadoSolicitud.recibidoComite:
        return 'Recibido comité';
      case EstadoSolicitud.enEvaluacion:
        return 'En evaluación';
      case EstadoSolicitud.aprobado:
        return 'Aprobado';
      case EstadoSolicitud.condicionado:
        return 'Condicionado';
      case EstadoSolicitud.rechazado:
        return 'Rechazado';
      case EstadoSolicitud.desembolsado:
        return 'Desembolsado';
    }
  }

  static EstadoSolicitud fromString(String value) {
    return EstadoSolicitud.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoSolicitud.borrador,
    );
  }
}

enum TipoCuota { mensual, quincenal, semanal }

enum TipoGarantia { sinGarantia, aval, hipotecaria, prendaria }

class DatosSolicitante {
  final String nombres;
  final String apellidos;
  final String documento;
  final DateTime? fechaNacimiento;
  final String estadoCivil;
  final String gradoInstruccion;
  final String telefono;
  final String email;

  const DatosSolicitante({
    this.nombres = '',
    this.apellidos = '',
    this.documento = '',
    this.fechaNacimiento,
    this.estadoCivil = '',
    this.gradoInstruccion = '',
    this.telefono = '',
    this.email = '',
  });

  DatosSolicitante copyWith({
    String? nombres,
    String? apellidos,
    String? documento,
    DateTime? fechaNacimiento,
    String? estadoCivil,
    String? gradoInstruccion,
    String? telefono,
    String? email,
  }) {
    return DatosSolicitante(
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      documento: documento ?? this.documento,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      gradoInstruccion: gradoInstruccion ?? this.gradoInstruccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() => {
    'nombres': nombres,
    'apellidos': apellidos,
    'documento': documento,
    'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
    'estado_civil': estadoCivil,
    'grado_instruccion': gradoInstruccion,
    'telefono': telefono,
    'email': email,
  };

  factory DatosSolicitante.fromMap(Map<String, dynamic> m) => DatosSolicitante(
    nombres: m['nombres']?.toString() ?? '',
    apellidos: m['apellidos']?.toString() ?? '',
    documento: m['documento']?.toString() ?? '',
    fechaNacimiento: m['fecha_nacimiento'] != null
        ? DateTime.tryParse(m['fecha_nacimiento'].toString())
        : null,
    estadoCivil: m['estado_civil']?.toString() ?? '',
    gradoInstruccion: m['grado_instruccion']?.toString() ?? '',
    telefono: m['telefono']?.toString() ?? '',
    email: m['email']?.toString() ?? '',
  );
}

class DatosNegocio {
  final String tipoNegocio;
  final String nombreNegocio;
  final String direccionNegocio;
  final int antiguedadAnios;
  final int antiguedadMeses;
  final double ingresosMensuales;
  final double gastosMensuales;
  final double patrimonio;
  final String destinoCredito;
  final String actividadEconomica;

  const DatosNegocio({
    this.tipoNegocio = '',
    this.nombreNegocio = '',
    this.direccionNegocio = '',
    this.antiguedadAnios = 0,
    this.antiguedadMeses = 0,
    this.ingresosMensuales = 0,
    this.gastosMensuales = 0,
    this.patrimonio = 0,
    this.destinoCredito = '',
    this.actividadEconomica = '',
  });

  DatosNegocio copyWith({
    String? tipoNegocio,
    String? nombreNegocio,
    String? direccionNegocio,
    int? antiguedadAnios,
    int? antiguedadMeses,
    double? ingresosMensuales,
    double? gastosMensuales,
    double? patrimonio,
    String? destinoCredito,
    String? actividadEconomica,
  }) {
    return DatosNegocio(
      tipoNegocio: tipoNegocio ?? this.tipoNegocio,
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      direccionNegocio: direccionNegocio ?? this.direccionNegocio,
      antiguedadAnios: antiguedadAnios ?? this.antiguedadAnios,
      antiguedadMeses: antiguedadMeses ?? this.antiguedadMeses,
      ingresosMensuales: ingresosMensuales ?? this.ingresosMensuales,
      gastosMensuales: gastosMensuales ?? this.gastosMensuales,
      patrimonio: patrimonio ?? this.patrimonio,
      destinoCredito: destinoCredito ?? this.destinoCredito,
      actividadEconomica: actividadEconomica ?? this.actividadEconomica,
    );
  }

  Map<String, dynamic> toMap() => {
    'tipo_negocio': tipoNegocio,
    'nombre_negocio': nombreNegocio,
    'direccion_negocio': direccionNegocio,
    'antiguedad_anios': antiguedadAnios,
    'antiguedad_meses': antiguedadMeses,
    'ingresos_mensuales': ingresosMensuales,
    'gastos_mensuales': gastosMensuales,
    'patrimonio': patrimonio,
    'destino_credito': destinoCredito,
    'actividad_economica': actividadEconomica,
  };

  factory DatosNegocio.fromMap(Map<String, dynamic> m) => DatosNegocio(
    tipoNegocio: m['tipo_negocio']?.toString() ?? '',
    nombreNegocio: m['nombre_negocio']?.toString() ?? '',
    direccionNegocio: m['direccion_negocio']?.toString() ?? '',
    antiguedadAnios: (m['antiguedad_anios'] as num?)?.toInt() ?? 0,
    antiguedadMeses: (m['antiguedad_meses'] as num?)?.toInt() ?? 0,
    ingresosMensuales: (m['ingresos_mensuales'] as num?)?.toDouble() ?? 0,
    gastosMensuales: (m['gastos_mensuales'] as num?)?.toDouble() ?? 0,
    patrimonio: (m['patrimonio'] as num?)?.toDouble() ?? 0,
    destinoCredito: m['destino_credito']?.toString() ?? '',
    actividadEconomica: m['actividad_economica']?.toString() ?? '',
  );
}

class DatosCredito {
  final double montoSolicitado;
  final int plazoMeses;
  final String moneda;
  final TipoCuota tipoCuota;
  final TipoGarantia garantia;

  const DatosCredito({
    this.montoSolicitado = 500,
    this.plazoMeses = 12,
    this.moneda = 'PEN',
    this.tipoCuota = TipoCuota.mensual,
    this.garantia = TipoGarantia.sinGarantia,
  });

  DatosCredito copyWith({
    double? montoSolicitado,
    int? plazoMeses,
    String? moneda,
    TipoCuota? tipoCuota,
    TipoGarantia? garantia,
  }) {
    return DatosCredito(
      montoSolicitado: montoSolicitado ?? this.montoSolicitado,
      plazoMeses: plazoMeses ?? this.plazoMeses,
      moneda: moneda ?? this.moneda,
      tipoCuota: tipoCuota ?? this.tipoCuota,
      garantia: garantia ?? this.garantia,
    );
  }

  Map<String, dynamic> toMap() => {
    'monto_solicitado': montoSolicitado,
    'plazo_meses': plazoMeses,
    'moneda': moneda,
    'tipo_cuota': tipoCuota.name,
    'garantia': garantia.name,
  };

  factory DatosCredito.fromMap(Map<String, dynamic> m) => DatosCredito(
    montoSolicitado: (m['monto_solicitado'] as num?)?.toDouble() ?? 500,
    plazoMeses: (m['plazo_meses'] as num?)?.toInt() ?? 12,
    moneda: m['moneda']?.toString() ?? 'PEN',
    tipoCuota: TipoCuota.values.firstWhere(
      (e) => e.name == m['tipo_cuota'],
      orElse: () => TipoCuota.mensual,
    ),
    garantia: TipoGarantia.values.firstWhere(
      (e) => e.name == m['garantia'],
      orElse: () => TipoGarantia.sinGarantia,
    ),
  );
}

class SolicitudModel {
  final String id;
  final String numeroExpediente;
  final String asesorId;
  final String clienteId;
  final String nombreCliente;
  final EstadoSolicitud estado;
  final int pasoActual;
  final DatosSolicitante solicitante;
  final DatosNegocio negocio;
  final DatosCredito credito;
  final double cuotaEstimada;
  final double teaReferencial;
  final String firmaBase64;
  final bool datosVeraces;
  final bool pendienteSync;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const SolicitudModel({
    required this.id,
    this.numeroExpediente = '',
    required this.asesorId,
    this.clienteId = '',
    this.nombreCliente = '',
    this.estado = EstadoSolicitud.borrador,
    this.pasoActual = 0,
    this.solicitante = const DatosSolicitante(),
    this.negocio = const DatosNegocio(),
    this.credito = const DatosCredito(),
    this.cuotaEstimada = 0,
    this.teaReferencial = 0,
    this.firmaBase64 = '',
    this.datosVeraces = false,
    this.pendienteSync = false,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  SolicitudModel copyWith({
    String? id,
    String? numeroExpediente,
    String? asesorId,
    String? clienteId,
    String? nombreCliente,
    EstadoSolicitud? estado,
    int? pasoActual,
    DatosSolicitante? solicitante,
    DatosNegocio? negocio,
    DatosCredito? credito,
    double? cuotaEstimada,
    double? teaReferencial,
    String? firmaBase64,
    bool? datosVeraces,
    bool? pendienteSync,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return SolicitudModel(
      id: id ?? this.id,
      numeroExpediente: numeroExpediente ?? this.numeroExpediente,
      asesorId: asesorId ?? this.asesorId,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      estado: estado ?? this.estado,
      pasoActual: pasoActual ?? this.pasoActual,
      solicitante: solicitante ?? this.solicitante,
      negocio: negocio ?? this.negocio,
      credito: credito ?? this.credito,
      cuotaEstimada: cuotaEstimada ?? this.cuotaEstimada,
      teaReferencial: teaReferencial ?? this.teaReferencial,
      firmaBase64: firmaBase64 ?? this.firmaBase64,
      datosVeraces: datosVeraces ?? this.datosVeraces,
      pendienteSync: pendienteSync ?? this.pendienteSync,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  Map<String, dynamic> toBorradorMap() => {
    'id': id,
    'cliente_id': clienteId,
    'cliente_nombre': nombreCliente,
    'paso_actual': pasoActual,
    'datos_json': jsonEncode(toJson()),
    'monto_solicitado': credito.montoSolicitado,
    'asesor_id': asesorId,
    'updated_at': DateTime.now().toIso8601String(),
  };

  factory SolicitudModel.fromBorradorMap(Map<String, dynamic> m) {
    final datos = m['datos_json']?.toString();
    if (datos != null && datos.isNotEmpty) {
      return SolicitudModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(datos)));
    }
    return SolicitudModel(
      id: m['id']?.toString() ?? '',
      clienteId: m['cliente_id']?.toString() ?? '',
      nombreCliente: m['cliente_nombre']?.toString() ?? '',
      asesorId: m['asesor_id']?.toString() ?? '',
      pasoActual: (m['paso_actual'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero_expediente': numeroExpediente,
    'asesor_id': asesorId,
    'cliente_id': clienteId,
    'nombre_cliente': nombreCliente,
    'estado': estado.name,
    'paso_actual': pasoActual,
    ...solicitante.toMap(),
    ...negocio.toMap(),
    ...credito.toMap(),
    'cuota_estimada': cuotaEstimada,
    'tea_referencial': teaReferencial,
    'firma_cliente_base64': firmaBase64,
    'datos_veraces': datosVeraces,
    'pendiente_sync': pendienteSync ? 1 : 0,
    'fecha_creacion': fechaCreacion?.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
  };

  factory SolicitudModel.fromJson(Map<String, dynamic> m) => SolicitudModel(
    id: m['id']?.toString() ?? '',
    numeroExpediente: m['numero_expediente']?.toString() ?? '',
    asesorId: m['asesor_id']?.toString() ?? '',
    clienteId: m['cliente_id']?.toString() ?? '',
    nombreCliente: m['nombre_cliente']?.toString() ?? '',
    estado: EstadoSolicitud.fromString(m['estado']?.toString() ?? ''),
    pasoActual: (m['paso_actual'] as num?)?.toInt() ?? 0,
    solicitante: DatosSolicitante.fromMap(m),
    negocio: DatosNegocio.fromMap(m),
    credito: DatosCredito.fromMap(m),
    cuotaEstimada: (m['cuota_estimada'] as num?)?.toDouble() ?? 0,
    teaReferencial: (m['tea_referencial'] as num?)?.toDouble() ?? 0,
    firmaBase64: m['firma_cliente_base64']?.toString() ?? '',
    datosVeraces: m['datos_veraces'] ?? false,
    pendienteSync: (m['pendiente_sync'] as num?)?.toInt() == 1,
    fechaCreacion: m['fecha_creacion'] != null
        ? DateTime.tryParse(m['fecha_creacion'].toString())
        : null,
    fechaActualizacion: m['fecha_actualizacion'] != null
        ? DateTime.tryParse(m['fecha_actualizacion'].toString())
        : null,
  );
}
