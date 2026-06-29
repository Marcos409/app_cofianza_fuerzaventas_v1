class ClienteMora {
  final String id;
  final String clienteId;
  final String creditoId;
  final String nombreCliente;
  final String documentoCliente;
  final String? telefono;
  final String? direccion;
  final int diasMora;
  final double montoVencido;
  final double saldoActual;
  final String? ultimoContacto;
  final int? cuotasPagadas;
  final int? totalCuotas;

  const ClienteMora({
    required this.id,
    required this.clienteId,
    required this.creditoId,
    required this.nombreCliente,
    required this.documentoCliente,
    this.telefono,
    this.direccion,
    required this.diasMora,
    required this.montoVencido,
    required this.saldoActual,
    this.ultimoContacto,
    this.cuotasPagadas,
    this.totalCuotas,
  });

  ClienteMora copyWith({
    String? id,
    String? clienteId,
    String? creditoId,
    String? nombreCliente,
    String? documentoCliente,
    String? telefono,
    String? direccion,
    int? diasMora,
    double? montoVencido,
    double? saldoActual,
    String? ultimoContacto,
    int? cuotasPagadas,
    int? totalCuotas,
  }) {
    return ClienteMora(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      creditoId: creditoId ?? this.creditoId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      documentoCliente: documentoCliente ?? this.documentoCliente,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      diasMora: diasMora ?? this.diasMora,
      montoVencido: montoVencido ?? this.montoVencido,
      saldoActual: saldoActual ?? this.saldoActual,
      ultimoContacto: ultimoContacto ?? this.ultimoContacto,
      cuotasPagadas: cuotasPagadas ?? this.cuotasPagadas,
      totalCuotas: totalCuotas ?? this.totalCuotas,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'cliente_id': clienteId,
    'credito_id': creditoId,
    'nombre_cliente': nombreCliente,
    'documento_cliente': documentoCliente,
    'telefono': telefono,
    'direccion': direccion,
    'dias_mora': diasMora,
    'monto_vencido': montoVencido,
    'saldo_actual': saldoActual,
    'ultimo_contacto': ultimoContacto,
    'cuotas_pagadas': cuotasPagadas,
    'total_cuotas': totalCuotas,
  };

  factory ClienteMora.fromMap(Map<String, dynamic> m) => ClienteMora(
    id: m['id']?.toString() ?? '',
    clienteId: m['cliente_id']?.toString() ?? m['clienteId']?.toString() ?? '',
    creditoId: m['credito_id']?.toString() ?? m['creditoId']?.toString() ?? '',
    nombreCliente: m['nombre_cliente']?.toString() ?? m['nombreCliente']?.toString() ?? '',
    documentoCliente: m['documento_cliente']?.toString() ?? m['documentoCliente']?.toString() ?? '',
    telefono: m['telefono']?.toString(),
    direccion: m['direccion']?.toString(),
    diasMora: int.tryParse(m['dias_mora']?.toString() ?? '') ?? (m['diasMora'] as num?)?.toInt() ?? 0,
    montoVencido: double.tryParse(m['monto_vencido']?.toString() ?? '') ?? (m['montoVencido'] as num?)?.toDouble() ?? 0,
    saldoActual: double.tryParse(m['saldo_actual']?.toString() ?? '') ?? (m['saldoActual'] as num?)?.toDouble() ?? 0,
    ultimoContacto: m['ultimo_contacto']?.toString() ?? m['ultimoContacto']?.toString(),
    cuotasPagadas: int.tryParse(m['cuotas_pagadas']?.toString() ?? '') ?? (m['cuotasPagadas'] as num?)?.toInt(),
    totalCuotas: int.tryParse(m['total_cuotas']?.toString() ?? '') ?? (m['totalCuotas'] as num?)?.toInt(),
  );

  NivelUrgencia get urgencia {
    if (diasMora > 60) return NivelUrgencia.urgente;
    if (diasMora >= 31) return NivelUrgencia.prioritario;
    return NivelUrgencia.preventivo;
  }
}

enum NivelUrgencia {
  preventivo(1),
  prioritario(2),
  urgente(3);

  final int peso;
  const NivelUrgencia(this.peso);
}
