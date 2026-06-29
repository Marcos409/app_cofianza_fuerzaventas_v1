enum PasoTransmision {
  pendiente(0, 'Pendiente'),
  validando(1, 'Validando datos'),
  subiendoDocumentos(2, 'Subiendo documentos'),
  registrandoCentral(3, 'Registrando en sistema central'),
  asignandoExpediente(4, 'Asignando expediente'),
  completado(5, 'Solicitud enviada');

  final int order;
  final String label;
  const PasoTransmision(this.order, this.label);

  bool get isTerminal => this == completado;
}

enum EstadoItemTransmision {
  pendiente,
  enProceso,
  completado,
  error;

  bool get isPendiente => this == EstadoItemTransmision.pendiente;
  bool get isEnProceso => this == EstadoItemTransmision.enProceso;
  bool get isCompletado => this == EstadoItemTransmision.completado;
  bool get isError => this == EstadoItemTransmision.error;
}

class TransmisionEstado {
  final String solicitudId;
  final int pasoCompletado;
  final List<String> documentosSubidos;
  final String? expedienteGenerado;
  final String? errorMessage;
  final DateTime updatedAt;

  const TransmisionEstado({
    required this.solicitudId,
    this.pasoCompletado = 0,
    this.documentosSubidos = const [],
    this.expedienteGenerado,
    this.errorMessage,
    required this.updatedAt,
  });

  TransmisionEstado copyWith({
    String? solicitudId,
    int? pasoCompletado,
    List<String>? documentosSubidos,
    String? expedienteGenerado,
    String? errorMessage,
    DateTime? updatedAt,
    bool clearError = false,
  }) {
    return TransmisionEstado(
      solicitudId: solicitudId ?? this.solicitudId,
      pasoCompletado: pasoCompletado ?? this.pasoCompletado,
      documentosSubidos: documentosSubidos ?? this.documentosSubidos,
      expedienteGenerado: expedienteGenerado ?? this.expedienteGenerado,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'solicitud_id': solicitudId,
        'paso_completado': pasoCompletado,
        'documentos_subidos': documentosSubidos.join(','),
        'expediente_generado': expedienteGenerado,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TransmisionEstado.fromMap(Map<String, dynamic> m) => TransmisionEstado(
        solicitudId: m['solicitud_id'] as String,
        pasoCompletado: m['paso_completado'] is num
            ? (m['paso_completado'] as num).toInt()
            : int.tryParse(m['paso_completado']?.toString() ?? '') ?? 0,
        documentosSubidos: (m['documentos_subidos'] as String?)
                ?.split(',')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
        expedienteGenerado: m['expediente_generado'] as String?,
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
