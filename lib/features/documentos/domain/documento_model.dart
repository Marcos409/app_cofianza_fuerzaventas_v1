enum TipoDocumento {
  dniAnverso,
  dniReverso,
  ruc,
  reciboServicios,
  fotoNegocio,
  fotoVisita,
  contratoArrendamiento;

  String get storageName {
    switch (this) {
      case TipoDocumento.dniAnverso:
        return 'dni_anverso';
      case TipoDocumento.dniReverso:
        return 'dni_reverso';
      case TipoDocumento.ruc:
        return 'ruc';
      case TipoDocumento.reciboServicios:
        return 'recibo_servicios';
      case TipoDocumento.fotoNegocio:
        return 'foto_negocio';
      case TipoDocumento.fotoVisita:
        return 'foto_visita';
      case TipoDocumento.contratoArrendamiento:
        return 'contrato_arrendamiento';
    }
  }

  String get label {
    switch (this) {
      case TipoDocumento.dniAnverso:
        return 'DNI anverso';
      case TipoDocumento.dniReverso:
        return 'DNI reverso';
      case TipoDocumento.ruc:
        return 'RUC';
      case TipoDocumento.reciboServicios:
        return 'Recibo de servicios';
      case TipoDocumento.fotoNegocio:
        return 'Foto del negocio';
      case TipoDocumento.fotoVisita:
        return 'Foto asesor + cliente';
      case TipoDocumento.contratoArrendamiento:
        return 'Contrato de arriendo';
    }
  }

  bool get esObligatorio {
    switch (this) {
      case TipoDocumento.dniAnverso:
      case TipoDocumento.dniReverso:
      case TipoDocumento.fotoNegocio:
      case TipoDocumento.fotoVisita:
        return true;
      case TipoDocumento.ruc:
      case TipoDocumento.reciboServicios:
      case TipoDocumento.contratoArrendamiento:
        return false;
    }
  }

  static TipoDocumento fromStorageName(String name) {
    return TipoDocumento.values.firstWhere(
      (e) => e.storageName == name,
      orElse: () => TipoDocumento.dniAnverso,
    );
  }
}

enum EstadoDocumento {
  pendiente,
  capturando,
  subiendo,
  listo,
  error;

  String get label {
    switch (this) {
      case EstadoDocumento.pendiente:
        return 'PENDIENTE';
      case EstadoDocumento.capturando:
        return 'CAPTURANDO';
      case EstadoDocumento.subiendo:
        return 'SUBIENDO';
      case EstadoDocumento.listo:
        return 'LISTO';
      case EstadoDocumento.error:
        return 'ERROR';
    }
  }
}

class DocumentoModel {
  final String id;
  final String solicitudId;
  final TipoDocumento tipo;
  final EstadoDocumento estado;
  final String? storageUrl;
  final int? tamanioKb;
  final double? nitidezScore;
  final String? localPath;
  final DateTime? createdAt;

  const DocumentoModel({
    required this.id,
    required this.solicitudId,
    required this.tipo,
    this.estado = EstadoDocumento.pendiente,
    this.storageUrl,
    this.tamanioKb,
    this.nitidezScore,
    this.localPath,
    this.createdAt,
  });

  DocumentoModel copyWith({
    String? id,
    String? solicitudId,
    TipoDocumento? tipo,
    EstadoDocumento? estado,
    String? storageUrl,
    int? tamanioKb,
    double? nitidezScore,
    String? localPath,
    DateTime? createdAt,
  }) {
    return DocumentoModel(
      id: id ?? this.id,
      solicitudId: solicitudId ?? this.solicitudId,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      storageUrl: storageUrl ?? this.storageUrl,
      tamanioKb: tamanioKb ?? this.tamanioKb,
      nitidezScore: nitidezScore ?? this.nitidezScore,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'solicitud_id': solicitudId,
        'tipo_documento': tipo.storageName,
        'estado': estado.name,
        'storage_url': storageUrl,
        'tamanio_kb': tamanioKb,
        'nitidez_score': nitidezScore,
        'local_path': localPath,
        'created_at': createdAt?.toIso8601String(),
      };

  factory DocumentoModel.fromMap(Map<String, dynamic> m) => DocumentoModel(
        id: m['id'] as String,
        solicitudId: m['solicitud_id'] as String,
        tipo: TipoDocumento.fromStorageName(m['tipo_documento'] as String),
        estado: EstadoDocumento.values.firstWhere(
          (e) => e.name == m['estado'],
          orElse: () => EstadoDocumento.pendiente,
        ),
        storageUrl: m['storage_url'] as String?,
        tamanioKb: m['tamanio_kb'] is num
            ? (m['tamanio_kb'] as num).toInt()
            : int.tryParse(m['tamanio_kb']?.toString() ?? ''),
        nitidezScore: m['nitidez_score'] is num
            ? (m['nitidez_score'] as num).toDouble()
            : double.tryParse(m['nitidez_score']?.toString() ?? ''),
        localPath: m['local_path'] as String?,
        createdAt: m['created_at'] is DateTime
            ? m['created_at'] as DateTime
            : m['created_at'] != null
                ? DateTime.tryParse(m['created_at'] as String)
                : null,
      );
}
