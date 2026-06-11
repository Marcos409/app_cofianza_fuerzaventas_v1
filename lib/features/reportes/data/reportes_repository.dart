import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/productividad_asesor.dart';
import '../domain/avance_asesor.dart';

class ReportesRepository {
  final SupabaseClient _supabase;

  ReportesRepository(this._supabase);

  Future<List<AvanceAsesor>> getAvanceDiario(String agenciaId) async {
    final response = await _supabase
        .from('cartera_diaria')
        .select('''
          asesor_id,
          fecha_asignacion,
          estado_visita,
          lat_visita,
          lng_visita,
          timestamp_visita
        ''')
        .eq('agencia_id', agenciaId);

    final rows = response as List;
    final map = <String, _AsesorAvance>{};

    for (final row in rows) {
      final asesorId = row['asesor_id']?.toString() ?? '';
      if (asesorId.isEmpty) continue;
      final e = map.putIfAbsent(asesorId, () => _AsesorAvance());
      e.total++;
      if (row['estado_visita']?.toString() == 'visitado') {
        e.visitados++;
      }
      final lat = (row['lat_visita'] as num?)?.toDouble();
      final lng = (row['lng_visita'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        e.lat = lat;
        e.lng = lng;
      }
      final ts = row['timestamp_visita']?.toString();
      if (ts != null && (e.ultimaSync == null || ts.compareTo(e.ultimaSync!) > 0)) {
        e.ultimaSync = ts;
      }
    }

    return map.entries.map((e) {
      final v = e.value;
      return AvanceAsesor(
        asesorId: e.key,
        nombreAsesor: e.key,
        visitados: v.visitados,
        totalAsignados: v.total,
        progreso: v.total > 0 ? v.visitados / v.total : 0,
        ultimaSincronizacion: v.ultimaSync,
        lat: v.lat,
        lng: v.lng,
      );
    }).toList();
  }

  Future<ReporteMensual> getProductividad(
    String agenciaId,
    int mes,
    int anio,
  ) async {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);

    final response = await _supabase
        .from('solicitudes_credito')
        .select('asesor_id, estado, monto_solicitado')
        .eq('agencia_id', agenciaId)
        .gte('created_at', inicio.toIso8601String())
        .lt('created_at', fin.toIso8601String());

    final rows = response as List;
    final asesores = <String, _AsesorProd>{};

    for (final row in rows) {
      final asesorId = row['asesor_id']?.toString() ?? '';
      if (asesorId.isEmpty) continue;
      final e = asesores.putIfAbsent(asesorId, () => _AsesorProd());
      final estado = row['estado']?.toString() ?? '';
      e.enviadas++;
      if (estado == 'aprobado') e.aprobadas++;
      if (estado == 'desembolsado') {
        e.desembolsadas++;
        e.montoTotal += (row['monto_solicitado'] as num?)?.toDouble() ?? 0;
      }
    }

    final lista = asesores.entries.map((e) {
      final v = e.value;
      return ProductividadAsesor(
        asesorId: e.key,
        nombreAsesor: e.key,
        enviadas: v.enviadas,
        aprobadas: v.aprobadas,
        desembolsadas: v.desembolsadas,
        montoTotalAprobado: v.montoTotal,
        tasaAprobacion: v.enviadas > 0
            ? (v.aprobadas + v.desembolsadas) / v.enviadas * 100
            : 0,
      );
    }).toList();

    return ReporteMensual(
      asesores: lista,
      totalEnviadas: lista.fold(0, (s, a) => s + a.enviadas),
      totalAprobadas: lista.fold(0, (s, a) => s + a.aprobadas),
      totalDesembolsadas: lista.fold(0, (s, a) => s + a.desembolsadas),
      montoTotal: lista.fold(0.0, (s, a) => s + a.montoTotalAprobado),
    );
  }
}

class _AsesorAvance {
  int total = 0;
  int visitados = 0;
  double? lat;
  double? lng;
  String? ultimaSync;
}

class _AsesorProd {
  int enviadas = 0;
  int aprobadas = 0;
  int desembolsadas = 0;
  double montoTotal = 0;
}
