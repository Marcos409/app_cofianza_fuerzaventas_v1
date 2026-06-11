enum CalificacionSbs {
  normal,
  cpp,
  deficiente,
  dudoso,
  perdida;

  String get label {
    switch (this) {
      case CalificacionSbs.normal:
        return 'Normal';
      case CalificacionSbs.cpp:
        return 'CPP';
      case CalificacionSbs.deficiente:
        return 'Deficiente';
      case CalificacionSbs.dudoso:
        return 'Dudoso';
      case CalificacionSbs.perdida:
        return 'Pérdida';
    }
  }

  static CalificacionSbs fromString(String s) {
    switch (s.toLowerCase()) {
      case 'normal':
        return CalificacionSbs.normal;
      case 'cpp':
        return CalificacionSbs.cpp;
      case 'deficiente':
        return CalificacionSbs.deficiente;
      case 'dudoso':
        return CalificacionSbs.dudoso;
      case 'perdida':
      case 'pérdida':
        return CalificacionSbs.perdida;
      default:
        return CalificacionSbs.normal;
    }
  }
}

class ResultadoBuro {
  final CalificacionSbs calificacionSbs;
  final int numEntidadesDeuda;
  final double deudaTotal;
  final double mayorDeuda;
  final int diasMayorMora;

  const ResultadoBuro({
    required this.calificacionSbs,
    required this.numEntidadesDeuda,
    required this.deudaTotal,
    required this.mayorDeuda,
    required this.diasMayorMora,
  });

  factory ResultadoBuro.fromJson(Map<String, dynamic> json) => ResultadoBuro(
        calificacionSbs:
            CalificacionSbs.fromString(json['calificacion_sbs'] as String),
        numEntidadesDeuda: json['num_entidades_deuda'] as int,
        deudaTotal: (json['deuda_total'] as num).toDouble(),
        mayorDeuda: (json['mayor_deuda'] as num).toDouble(),
        diasMayorMora: json['dias_mayor_mora'] as int,
      );

  Map<String, dynamic> toJson() => {
        'calificacion_sbs': calificacionSbs.name,
        'num_entidades_deuda': numEntidadesDeuda,
        'deuda_total': deudaTotal,
        'mayor_deuda': mayorDeuda,
        'dias_mayor_mora': diasMayorMora,
      };
}

class ConsultaBuroModel {
  final String id;
  final String asesorId;
  final String clienteId;
  final String dniConsultado;
  final ResultadoBuro resultado;
  final bool enListaNegra;
  final String? motivoBloqueo;
  final String firmaConsentimientoBase64;
  final String? solicitudId;
  final bool esReutilizada;
  final DateTime createdAt;

  const ConsultaBuroModel({
    required this.id,
    required this.asesorId,
    required this.clienteId,
    required this.dniConsultado,
    required this.resultado,
    required this.firmaConsentimientoBase64,
    this.enListaNegra = false,
    this.motivoBloqueo,
    this.solicitudId,
    this.esReutilizada = false,
    required this.createdAt,
  });

  ConsultaBuroModel copyWith({
    String? id,
    String? asesorId,
    String? clienteId,
    String? dniConsultado,
    ResultadoBuro? resultado,
    bool? enListaNegra,
    String? motivoBloqueo,
    String? firmaConsentimientoBase64,
    String? solicitudId,
    bool? esReutilizada,
    DateTime? createdAt,
  }) {
    return ConsultaBuroModel(
      id: id ?? this.id,
      asesorId: asesorId ?? this.asesorId,
      clienteId: clienteId ?? this.clienteId,
      dniConsultado: dniConsultado ?? this.dniConsultado,
      resultado: resultado ?? this.resultado,
      enListaNegra: enListaNegra ?? this.enListaNegra,
      motivoBloqueo: motivoBloqueo ?? this.motivoBloqueo,
      firmaConsentimientoBase64:
          firmaConsentimientoBase64 ?? this.firmaConsentimientoBase64,
      solicitudId: solicitudId ?? this.solicitudId,
      esReutilizada: esReutilizada ?? this.esReutilizada,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'asesor_id': asesorId,
        'cliente_id': clienteId,
        'dni_consultado': dniConsultado,
        'calificacion_sbs': resultado.calificacionSbs.name,
        'entidades_con_deuda': resultado.numEntidadesDeuda,
        'deuda_total_pen': resultado.deudaTotal,
        'mayor_deuda': resultado.mayorDeuda,
        'dias_mayor_mora': resultado.diasMayorMora,
        'resultado_json': resultado.toJson(),
        'en_lista_negra': enListaNegra ? 1 : 0,
        'motivo_bloqueo': motivoBloqueo,
        'firma_consentimiento_base64': firmaConsentimientoBase64,
        'solicitud_id': solicitudId,
        'es_reutilizada': esReutilizada ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory ConsultaBuroModel.fromMap(Map<String, dynamic> m) =>
      ConsultaBuroModel(
        id: m['id'] as String,
        asesorId: m['asesor_id'] as String,
        clienteId: m['cliente_id'] as String,
        dniConsultado: m['dni_consultado'] as String,
        resultado: ResultadoBuro.fromJson(
          Map<String, dynamic>.from(m['resultado_json'] as Map),
        ),
        enListaNegra: (m['en_lista_negra'] as int?) == 1,
        motivoBloqueo: m['motivo_bloqueo'] as String?,
        firmaConsentimientoBase64:
            m['firma_consentimiento_base64'] as String,
        solicitudId: m['solicitud_id'] as String?,
        esReutilizada: (m['es_reutilizada'] as int?) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
