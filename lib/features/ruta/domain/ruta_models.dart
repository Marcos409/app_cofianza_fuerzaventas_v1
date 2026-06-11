class ZonaTrabajo {
  final String id;
  final String nombre;
  final ColorARGB color;
  final List<String> asesoresIds;
  final List<LatLngPoint> poligono;

  const ZonaTrabajo({
    required this.id,
    required this.nombre,
    required this.color,
    this.asesoresIds = const [],
    this.poligono = const [],
  });

  factory ZonaTrabajo.fromJson(Map<String, dynamic> json) {
    final poligonoRaw = json['poligono'] as List<dynamic>? ?? [];
    final poligono = poligonoRaw.map((p) {
      final coords = p as Map<String, dynamic>;
      return LatLngPoint(
        lat: (coords['lat'] as num).toDouble(),
        lng: (coords['lng'] as num).toDouble(),
      );
    }).toList();

    return ZonaTrabajo(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      color: ColorARGB.fromJson(json['color'] as Map<String, dynamic>? ?? {}),
      asesoresIds: (json['asesores_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      poligono: poligono,
    );
  }
}

class ColorARGB {
  final int a;
  final int r;
  final int g;
  final int b;

  const ColorARGB({this.a = 255, required this.r, required this.g, this.b = 0});

  factory ColorARGB.fromJson(Map<String, dynamic> json) => ColorARGB(
        a: (json['a'] as num?)?.toInt() ?? 255,
        r: (json['r'] as num?)?.toInt() ?? 0,
        g: (json['g'] as num?)?.toInt() ?? 0,
        b: (json['b'] as num?)?.toInt() ?? 0,
      );
}

class LatLngPoint {
  final double lat;
  final double lng;

  const LatLngPoint({required this.lat, required this.lng});

  double distanceTo(LatLngPoint other) {
    final dx = lat - other.lat;
    final dy = lng - other.lng;
    return dx * dx + dy * dy;
  }
}
