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

  static CalificacionSbs fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CPP':
        return CalificacionSbs.cpp;
      case 'DEFICIENTE':
        return CalificacionSbs.deficiente;
      case 'DUDOSO':
        return CalificacionSbs.dudoso;
      case 'PERDIDA':
        return CalificacionSbs.perdida;
      default:
        return CalificacionSbs.normal;
    }
  }
}

class FichaClienteModel {
  final String id;
  final String nombre;
  final String documento;
  final String direccion;
  final String? telefono;
  final String? email;
  final String? tipoNegocio;
  final int? antiguedadNegocio;
  final double? lat;
  final double? lng;
  final CalificacionSbs calificacionSbs;

  const FichaClienteModel({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.direccion,
    this.telefono,
    this.email,
    this.tipoNegocio,
    this.antiguedadNegocio,
    this.lat,
    this.lng,
    this.calificacionSbs = CalificacionSbs.normal,
  });

  factory FichaClienteModel.fromJson(Map<String, dynamic> json) =>
      FichaClienteModel(
        id: json['id']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        documento: json['documento']?.toString() ?? '',
        direccion: json['direccion']?.toString() ?? '',
        telefono: json['telefono']?.toString(),
        email: json['email']?.toString(),
        tipoNegocio: json['tipo_negocio']?.toString(),
        antiguedadNegocio: (json['antiguedad_negocio'] as num?)?.toInt(),
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        calificacionSbs:
            CalificacionSbs.fromString(json['calificacion_sbs']?.toString() ?? ''),
      );
}

class PosicionCliente {
  final double deudaTotal;
  final int cuentasVigentes;
  final int cuentasMora;
  final int diasMayorMora;
  final DateTime? ultimoPago;

  const PosicionCliente({
    this.deudaTotal = 0,
    this.cuentasVigentes = 0,
    this.cuentasMora = 0,
    this.diasMayorMora = 0,
    this.ultimoPago,
  });

  factory PosicionCliente.fromJson(Map<String, dynamic> json) => PosicionCliente(
        deudaTotal: (json['deuda_total'] as num?)?.toDouble() ?? 0,
        cuentasVigentes: (json['cuentas_vigentes'] as num?)?.toInt() ?? 0,
        cuentasMora: (json['cuentas_mora'] as num?)?.toInt() ?? 0,
        diasMayorMora: (json['dias_mayor_mora'] as num?)?.toInt() ?? 0,
        ultimoPago: json['ultimo_pago'] != null
            ? DateTime.tryParse(json['ultimo_pago'].toString())
            : null,
      );
}

class CreditoHistorico {
  final String id;
  final double monto;
  final int plazoMeses;
  final double tea;
  final String estado;
  final double porcentajePuntual;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;

  const CreditoHistorico({
    required this.id,
    required this.monto,
    required this.plazoMeses,
    required this.tea,
    required this.estado,
    this.porcentajePuntual = 100,
    this.fechaApertura,
    this.fechaCierre,
  });

  factory CreditoHistorico.fromJson(Map<String, dynamic> json) =>
      CreditoHistorico(
        id: json['id']?.toString() ?? '',
        monto: (json['monto'] as num?)?.toDouble() ?? 0,
        plazoMeses: (json['plazo_meses'] as num?)?.toInt() ?? 0,
        tea: (json['tea'] as num?)?.toDouble() ?? 0,
        estado: json['estado']?.toString() ?? '',
        porcentajePuntual:
            (json['porcentaje_puntual'] as num?)?.toDouble() ?? 100,
        fechaApertura: json['fecha_apertura'] != null
            ? DateTime.tryParse(json['fecha_apertura'].toString())
            : null,
        fechaCierre: json['fecha_cierre'] != null
            ? DateTime.tryParse(json['fecha_cierre'].toString())
            : null,
      );
}

class OfertaPreaprobada {
  final String id;
  final String clienteId;
  final double montoMaximo;
  final int plazoSugeridoMeses;
  final double teaReferencial;
  final int scoreConfianza;
  final bool vigente;
  final DateTime fechaVencimiento;

  const OfertaPreaprobada({
    required this.id,
    required this.clienteId,
    required this.montoMaximo,
    required this.plazoSugeridoMeses,
    required this.teaReferencial,
    required this.scoreConfianza,
    this.vigente = true,
    required this.fechaVencimiento,
  });

  factory OfertaPreaprobada.fromJson(Map<String, dynamic> json) =>
      OfertaPreaprobada(
        id: json['id']?.toString() ?? '',
        clienteId: json['cliente_id']?.toString() ?? '',
        montoMaximo: (json['monto_maximo'] as num?)?.toDouble() ?? 0,
        plazoSugeridoMeses:
            (json['plazo_sugerido_meses'] as num?)?.toInt() ?? 0,
        teaReferencial: (json['tea_referencial'] as num?)?.toDouble() ?? 0,
        scoreConfianza: (json['score_confianza'] as num?)?.toInt() ?? 0,
        vigente: json['vigente'] ?? true,
        fechaVencimiento: DateTime.tryParse(
                json['fecha_vencimiento']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class PagoMensual {
  final int mes;
  final int anio;
  final double montoPagado;
  final StatusPago status;

  const PagoMensual({
    required this.mes,
    required this.anio,
    required this.montoPagado,
    required this.status,
  });
}

enum StatusPago { puntual, mora, sinCuota }
