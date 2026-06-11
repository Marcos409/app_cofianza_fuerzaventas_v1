enum TipoGestion {
  renovacion,
  ampliacion,
  nuevaSolicitud,
  seguimiento,
  recuperacionMora,
  desertor;

  String get label {
    switch (this) {
      case TipoGestion.renovacion:
        return 'Renovación';
      case TipoGestion.ampliacion:
        return 'Ampliación';
      case TipoGestion.nuevaSolicitud:
        return 'Nueva solicitud';
      case TipoGestion.seguimiento:
        return 'Seguimiento';
      case TipoGestion.recuperacionMora:
        return 'Recuperación mora';
      case TipoGestion.desertor:
        return 'Desertor';
    }
  }

  static TipoGestion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'RENOVACION':
        return TipoGestion.renovacion;
      case 'AMPLIACION':
        return TipoGestion.ampliacion;
      case 'NUEVA_SOLICITUD':
        return TipoGestion.nuevaSolicitud;
      case 'SEGUIMIENTO':
        return TipoGestion.seguimiento;
      case 'RECUPERACION_MORA':
        return TipoGestion.recuperacionMora;
      case 'DESERTOR':
        return TipoGestion.desertor;
      default:
        return TipoGestion.seguimiento;
    }
  }

  String get dbValue {
    switch (this) {
      case TipoGestion.renovacion:
        return 'RENOVACION';
      case TipoGestion.ampliacion:
        return 'AMPLIACION';
      case TipoGestion.nuevaSolicitud:
        return 'NUEVA_SOLICITUD';
      case TipoGestion.seguimiento:
        return 'SEGUIMIENTO';
      case TipoGestion.recuperacionMora:
        return 'RECUPERACION_MORA';
      case TipoGestion.desertor:
        return 'DESERTOR';
    }
  }
}

enum NivelRiesgo { bajo, medio, alto }

enum Prioridad { alta, media, normal }

enum EstadoVisita {
  pendiente,
  visitado,
  noEncontrado,
  reagendado,
  negocioCerrado;

  String get label {
    switch (this) {
      case EstadoVisita.pendiente:
        return 'Pendiente';
      case EstadoVisita.visitado:
        return 'Visitado';
      case EstadoVisita.noEncontrado:
        return 'No encontrado';
      case EstadoVisita.reagendado:
        return 'Reagendar';
      case EstadoVisita.negocioCerrado:
        return 'Negocio cerrado';
    }
  }

  static EstadoVisita fromString(String value) {
    switch (value.toLowerCase()) {
      case 'visitado':
        return EstadoVisita.visitado;
      case 'no_encontrado':
        return EstadoVisita.noEncontrado;
      case 'reagendado':
        return EstadoVisita.reagendado;
      case 'negocio_cerrado':
        return EstadoVisita.negocioCerrado;
      default:
        return EstadoVisita.pendiente;
    }
  }

  String get dbValue {
    switch (this) {
      case EstadoVisita.pendiente:
        return 'pendiente';
      case EstadoVisita.visitado:
        return 'visitado';
      case EstadoVisita.noEncontrado:
        return 'no_encontrado';
      case EstadoVisita.reagendado:
        return 'reagendado';
      case EstadoVisita.negocioCerrado:
        return 'negocio_cerrado';
    }
  }
}

class CarteraModel {
  final String id;
  final String asesorId;
  final String clienteId;
  final String? agenciaId;
  final DateTime fechaAsignacion;
  final TipoGestion tipoGestion;
  final Prioridad prioridad;
  final int scorePrioridad;
  final EstadoVisita estadoVisita;
  final String? resultadoVisita;
  final String? observacionVisita;
  final DateTime? timestampVisita;
  final double? latVisita;
  final double? lngVisita;
  final int ordenManual;
  final bool pendienteSync;

  // Datos del cliente (vienen del JOIN con tabla clientes)
  final String nombreCliente;
  final String documentoCliente;
  final String direccionCliente;
  final String? telefonoCliente;
  final double? montoCredito;

  const CarteraModel({
    required this.id,
    required this.asesorId,
    required this.clienteId,
    this.agenciaId,
    required this.fechaAsignacion,
    required this.tipoGestion,
    this.prioridad = Prioridad.normal,
    this.scorePrioridad = 0,
    this.estadoVisita = EstadoVisita.pendiente,
    this.resultadoVisita,
    this.observacionVisita,
    this.timestampVisita,
    this.latVisita,
    this.lngVisita,
    this.ordenManual = 0,
    this.pendienteSync = false,
    required this.nombreCliente,
    required this.documentoCliente,
    required this.direccionCliente,
    this.telefonoCliente,
    this.montoCredito,
  });

  String get documentoCensurado {
    if (documentoCliente.length < 5) return documentoCliente;
    final lastDigits = documentoCliente.substring(documentoCliente.length - 4);
    return '***$lastDigits';
  }

  NivelRiesgo get nivelRiesgo {
    if (scorePrioridad >= 70) return NivelRiesgo.alto;
    if (scorePrioridad >= 40) return NivelRiesgo.medio;
    return NivelRiesgo.bajo;
  }

  CarteraModel copyWith({
    String? id,
    String? asesorId,
    String? clienteId,
    String? agenciaId,
    DateTime? fechaAsignacion,
    TipoGestion? tipoGestion,
    Prioridad? prioridad,
    int? scorePrioridad,
    EstadoVisita? estadoVisita,
    String? resultadoVisita,
    String? observacionVisita,
    DateTime? timestampVisita,
    double? latVisita,
    double? lngVisita,
    int? ordenManual,
    bool? pendienteSync,
    String? nombreCliente,
    String? documentoCliente,
    String? direccionCliente,
    String? telefonoCliente,
    double? montoCredito,
  }) {
    return CarteraModel(
      id: id ?? this.id,
      asesorId: asesorId ?? this.asesorId,
      clienteId: clienteId ?? this.clienteId,
      agenciaId: agenciaId ?? this.agenciaId,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      tipoGestion: tipoGestion ?? this.tipoGestion,
      prioridad: prioridad ?? this.prioridad,
      scorePrioridad: scorePrioridad ?? this.scorePrioridad,
      estadoVisita: estadoVisita ?? this.estadoVisita,
      resultadoVisita: resultadoVisita ?? this.resultadoVisita,
      observacionVisita: observacionVisita ?? this.observacionVisita,
      timestampVisita: timestampVisita ?? this.timestampVisita,
      latVisita: latVisita ?? this.latVisita,
      lngVisita: lngVisita ?? this.lngVisita,
      ordenManual: ordenManual ?? this.ordenManual,
      pendienteSync: pendienteSync ?? this.pendienteSync,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      documentoCliente: documentoCliente ?? this.documentoCliente,
      direccionCliente: direccionCliente ?? this.direccionCliente,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      montoCredito: montoCredito ?? this.montoCredito,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'asesor_id': asesorId,
    'cliente_id': clienteId,
    'agencia_id': agenciaId,
    'fecha_asignacion': fechaAsignacion.toIso8601String(),
    'tipo_gestion': tipoGestion.dbValue,
    'prioridad': prioridad.name,
    'score_prioridad': scorePrioridad,
    'estado_visita': estadoVisita.dbValue,
    'resultado_visita': resultadoVisita,
    'observacion_visita': observacionVisita,
    'timestamp_visita': timestampVisita?.toIso8601String(),
    'lat_visita': latVisita,
    'lng_visita': lngVisita,
    'orden_manual': ordenManual,
    'pendiente_sync': pendienteSync ? 1 : 0,
    'nombre_cliente': nombreCliente,
    'documento_cliente': documentoCliente,
    'direccion_cliente': direccionCliente,
    'telefono_cliente': telefonoCliente,
    'monto_credito': montoCredito,
  };

  factory CarteraModel.fromMap(Map<String, dynamic> map) => CarteraModel(
    id: map['id']?.toString() ?? '',
    asesorId: map['asesor_id']?.toString() ?? '',
    clienteId: map['cliente_id']?.toString() ?? '',
    agenciaId: map['agencia_id']?.toString(),
    fechaAsignacion: DateTime.tryParse(map['fecha_asignacion']?.toString() ?? '') ?? DateTime.now(),
    tipoGestion: TipoGestion.fromString(map['tipo_gestion']?.toString() ?? ''),
    prioridad: Prioridad.values.firstWhere(
      (e) => e.name == map['prioridad'],
      orElse: () => Prioridad.normal,
    ),
    scorePrioridad: (map['score_prioridad'] as num?)?.toInt() ?? 0,
    estadoVisita: EstadoVisita.fromString(map['estado_visita']?.toString() ?? 'pendiente'),
    resultadoVisita: map['resultado_visita']?.toString(),
    observacionVisita: map['observacion_visita']?.toString(),
    timestampVisita: map['timestamp_visita'] != null
        ? DateTime.tryParse(map['timestamp_visita'].toString())
        : null,
    latVisita: (map['lat_visita'] as num?)?.toDouble(),
    lngVisita: (map['lng_visita'] as num?)?.toDouble(),
    ordenManual: (map['orden_manual'] as num?)?.toInt() ?? 0,
    pendienteSync: (map['pendiente_sync'] as num?)?.toInt() == 1,
    nombreCliente: map['nombre_cliente']?.toString() ?? '',
    documentoCliente: map['documento_cliente']?.toString() ?? '',
    direccionCliente: map['direccion_cliente']?.toString() ?? '',
    telefonoCliente: map['telefono_cliente']?.toString(),
    montoCredito: (map['monto_credito'] as num?)?.toDouble(),
  );

  static int calcularScore({
    required TipoGestion tipoGestion,
    int? diasMora,
    double? montoCredito,
  }) {
    int score = 0;

    switch (tipoGestion) {
      case TipoGestion.recuperacionMora:
        score = 40 + (diasMora ?? 0).clamp(0, 30);
      case TipoGestion.renovacion:
        if ((montoCredito ?? 0) > 5000) {
          score = 35;
        } else {
          score = 20;
        }
      case TipoGestion.ampliacion:
        score = 25;
      case TipoGestion.seguimiento:
        score = 10;
      case TipoGestion.nuevaSolicitud:
        score = 5;
      case TipoGestion.desertor:
        score = 15;
    }

    return score.clamp(0, 100);
  }
}

enum FiltroCartera { todos, renovaciones, nuevas, mora, visitados }
