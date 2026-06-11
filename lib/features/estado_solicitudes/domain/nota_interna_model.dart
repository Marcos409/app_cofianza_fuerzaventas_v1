class NotaInterna {
  final String id;
  final String solicitudId;
  final String asesorId;
  final String contenido;
  final DateTime createdAt;

  const NotaInterna({
    required this.id,
    required this.solicitudId,
    required this.asesorId,
    required this.contenido,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'solicitud_id': solicitudId,
        'asesor_id': asesorId,
        'contenido': contenido,
        'created_at': createdAt.toIso8601String(),
      };

  factory NotaInterna.fromMap(Map<String, dynamic> m) => NotaInterna(
        id: m['id'] as String,
        solicitudId: m['solicitud_id'] as String,
        asesorId: m['asesor_id'] as String,
        contenido: m['contenido'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
