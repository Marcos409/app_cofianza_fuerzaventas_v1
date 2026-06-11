enum Role {
  operador,
  superOperador,
  supervisor,
  administrador;

  String get label {
    switch (this) {
      case Role.operador:
        return 'Operador';
      case Role.superOperador:
        return 'Super Operador';
      case Role.supervisor:
        return 'Supervisor';
      case Role.administrador:
        return 'Administrador';
    }
  }

  static Role fromString(String value) {
    switch (value) {
      case 'super_operador':
        return Role.superOperador;
      case 'supervisor':
        return Role.supervisor;
      case 'administrador':
        return Role.administrador;
      default:
        return Role.operador;
    }
  }

  String get jsonValue {
    switch (this) {
      case Role.operador:
        return 'operador';
      case Role.superOperador:
        return 'super_operador';
      case Role.supervisor:
        return 'supervisor';
      case Role.administrador:
        return 'administrador';
    }
  }
}

class AsesorModel {
  final String id;
  final String userId;
  final String codigoEmpleado;
  final String nombres;
  final String apellidos;
  final String? agenciaId;
  final Role rol;
  final String? tokenFcm;
  final bool activo;
  final String? token;

  const AsesorModel({
    required this.id,
    required this.userId,
    required this.codigoEmpleado,
    required this.nombres,
    required this.apellidos,
    this.agenciaId,
    this.rol = Role.operador,
    this.tokenFcm,
    this.activo = true,
    this.token,
  });

  String get nombreCompleto => '$nombres $apellidos';

  AsesorModel copyWith({
    String? id,
    String? userId,
    String? codigoEmpleado,
    String? nombres,
    String? apellidos,
    String? agenciaId,
    Role? rol,
    String? tokenFcm,
    bool? activo,
    String? token,
  }) {
    return AsesorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      codigoEmpleado: codigoEmpleado ?? this.codigoEmpleado,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      agenciaId: agenciaId ?? this.agenciaId,
      rol: rol ?? this.rol,
      tokenFcm: tokenFcm ?? this.tokenFcm,
      activo: activo ?? this.activo,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'codigo_empleado': codigoEmpleado,
    'nombres': nombres,
    'apellidos': apellidos,
    'agencia_id': agenciaId,
    'perfil': rol.jsonValue,
    'token_fcm': tokenFcm,
    'activo': activo,
  };

  factory AsesorModel.fromJson(Map<String, dynamic> json) => AsesorModel(
    id: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    codigoEmpleado: json['codigo_empleado']?.toString() ?? '',
    nombres: json['nombres']?.toString() ?? '',
    apellidos: json['apellidos']?.toString() ?? '',
    agenciaId: json['agencia_id']?.toString(),
    rol: Role.fromString(json['perfil']?.toString() ?? 'operador'),
    tokenFcm: json['token_fcm']?.toString(),
    activo: json['activo'] ?? true,
    token: json['token']?.toString(),
  );
}
