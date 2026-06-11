class AccionCobranza {
  final String id;
  final String asesorId;
  final String clienteId;
  final String creditoId;
  final String tipoGestion;
  final String resultado;
  final double? montoPagado;
  final DateTime? fechaCompromiso;
  final double? montoCompromiso;
  final String? observaciones;
  final double? lat;
  final double? lng;
  final DateTime timestampGestion;
  final bool pendienteSync;

  const AccionCobranza({
    required this.id,
    required this.asesorId,
    required this.clienteId,
    required this.creditoId,
    required this.tipoGestion,
    required this.resultado,
    this.montoPagado,
    this.fechaCompromiso,
    this.montoCompromiso,
    this.observaciones,
    this.lat,
    this.lng,
    required this.timestampGestion,
    this.pendienteSync = true,
  });

  AccionCobranza copyWith({
    String? id,
    String? asesorId,
    String? clienteId,
    String? creditoId,
    String? tipoGestion,
    String? resultado,
    double? montoPagado,
    DateTime? fechaCompromiso,
    double? montoCompromiso,
    String? observaciones,
    double? lat,
    double? lng,
    DateTime? timestampGestion,
    bool? pendienteSync,
  }) {
    return AccionCobranza(
      id: id ?? this.id,
      asesorId: asesorId ?? this.asesorId,
      clienteId: clienteId ?? this.clienteId,
      creditoId: creditoId ?? this.creditoId,
      tipoGestion: tipoGestion ?? this.tipoGestion,
      resultado: resultado ?? this.resultado,
      montoPagado: montoPagado ?? this.montoPagado,
      fechaCompromiso: fechaCompromiso ?? this.fechaCompromiso,
      montoCompromiso: montoCompromiso ?? this.montoCompromiso,
      observaciones: observaciones ?? this.observaciones,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      timestampGestion: timestampGestion ?? this.timestampGestion,
      pendienteSync: pendienteSync ?? this.pendienteSync,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'asesor_id': asesorId,
    'cliente_id': clienteId,
    'credito_id': creditoId,
    'tipo_gestion': tipoGestion,
    'resultado': resultado,
    'monto_pagado': montoPagado,
    'fecha_compromiso': fechaCompromiso?.toIso8601String(),
    'monto_compromiso': montoCompromiso,
    'observaciones': observaciones,
    'lat': lat,
    'lng': lng,
    'timestamp_gestion': timestampGestion.toIso8601String(),
    'pendiente_sync': pendienteSync ? 1 : 0,
  };

  factory AccionCobranza.fromMap(Map<String, dynamic> m) {
    DateTime? parseTimestamp(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return AccionCobranza(
      id: m['id']?.toString() ?? '',
      asesorId: m['asesor_id']?.toString() ?? m['asesorId']?.toString() ?? '',
      clienteId: m['cliente_id']?.toString() ?? m['clienteId']?.toString() ?? '',
      creditoId: m['credito_id']?.toString() ?? m['creditoId']?.toString() ?? '',
      tipoGestion: m['tipo_gestion']?.toString() ?? m['tipoGestion']?.toString() ?? '',
      resultado: m['resultado']?.toString() ?? '',
      montoPagado: (m['monto_pagado'] as num?)?.toDouble() ?? (m['montoPagado'] as num?)?.toDouble(),
      fechaCompromiso: parseTimestamp(m['fecha_compromiso'] ?? m['fechaCompromiso']),
      montoCompromiso: (m['monto_compromiso'] as num?)?.toDouble() ?? (m['montoCompromiso'] as num?)?.toDouble(),
      observaciones: m['observaciones']?.toString(),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      timestampGestion: parseTimestamp(m['timestamp_gestion'] ?? m['timestampGestion']) ?? DateTime.now(),
      pendienteSync: (m['pendiente_sync'] == 1 || m['pendienteSync'] == true),
    );
  }
}
