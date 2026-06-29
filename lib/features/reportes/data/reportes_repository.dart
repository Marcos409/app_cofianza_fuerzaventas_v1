// ════════════════════════════════════════════════════════════
// 🔧 SUPABASE_COMENTADO: Reportes devolviendo datos mock - Junio 2026
// ════════════════════════════════════════════════════════════
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/productividad_asesor.dart';
import '../domain/avance_asesor.dart';

class ReportesRepository {
  // ════════════════════════════════════════════════════════════
  // 🔧 SUPABASE_COMENTADO: Sin SupabaseClient - datos mock
  // ════════════════════════════════════════════════════════════
  // final SupabaseClient _supabase;
  // ════════════════════════════════════════════════════════════

  // ════════════════════════════════════════════════════════════
  // 🔧 SUPABASE_COMENTADO: Constructor sin parámetros
  // ════════════════════════════════════════════════════════════
  // ReportesRepository(this._supabase);
  ReportesRepository();
  // ════════════════════════════════════════════════════════════

  // ════════════════════════════════════════════════════════════
  // 🔧 SUPABASE_COMENTADO: Consultas Supabase desactivadas - usando datos mock
  // ════════════════════════════════════════════════════════════
  // Future<List<AvanceAsesor>> getAvanceDiario(String agenciaId) async {
  //   try {
  //     final response = await _supabase.from('cartera_diaria')...
  //   } catch (_) {
  //     return _mockAvanceDiario();
  //   }
  // }
  Future<List<AvanceAsesor>> getAvanceDiario(String agenciaId) async {
    return _mockAvanceDiario();
  }

  // ════════════════════════════════════════════════════════════
  // 🔧 SUPABASE_COMENTADO: Consultas Supabase desactivadas - usando datos mock
  // ════════════════════════════════════════════════════════════
  // Future<ReporteMensual> getProductividad(String agenciaId, int mes, int anio) async {
  //   try {
  //     final response = await _supabase.from('solicitudes_credito')...
  //   } catch (_) {
  //     return _mockProductividad();
  //   }
  // }
  Future<ReporteMensual> getProductividad(
    String agenciaId,
    int mes,
    int anio,
  ) async {
    return _mockProductividad();
  }

  List<AvanceAsesor> _mockAvanceDiario() {
    return [
      AvanceAsesor(
        asesorId: 'mock-001',
        nombreAsesor: 'Carlos García',
        visitados: 5,
        totalAsignados: 8,
        progreso: 0.625,
        ultimaSincronizacion: DateTime.now().toIso8601String(),
        lat: -12.046374,
        lng: -77.042793,
      ),
      AvanceAsesor(
        asesorId: 'mock-002',
        nombreAsesor: 'María Fernández',
        visitados: 3,
        totalAsignados: 10,
        progreso: 0.3,
        ultimaSincronizacion: DateTime.now().toIso8601String(),
        lat: -12.0521,
        lng: -77.0456,
      ),
      AvanceAsesor(
        asesorId: 'mock-003',
        nombreAsesor: 'Admin Sistema',
        visitados: 8,
        totalAsignados: 8,
        progreso: 1.0,
        ultimaSincronizacion: DateTime.now().toIso8601String(),
        lat: -12.0654,
        lng: -77.0289,
      ),
    ];
  }

  ReporteMensual _mockProductividad() {
    final asesores = [
      ProductividadAsesor(
        asesorId: 'mock-001',
        nombreAsesor: 'Carlos García',
        enviadas: 12,
        aprobadas: 8,
        desembolsadas: 5,
        montoTotalAprobado: 45000,
        tasaAprobacion: 66.67,
      ),
      ProductividadAsesor(
        asesorId: 'mock-002',
        nombreAsesor: 'María Fernández',
        enviadas: 9,
        aprobadas: 6,
        desembolsadas: 4,
        montoTotalAprobado: 32000,
        tasaAprobacion: 66.67,
      ),
      ProductividadAsesor(
        asesorId: 'mock-003',
        nombreAsesor: 'Admin Sistema',
        enviadas: 18,
        aprobadas: 14,
        desembolsadas: 10,
        montoTotalAprobado: 95000,
        tasaAprobacion: 77.78,
      ),
    ];

    return ReporteMensual(
      asesores: asesores,
      totalEnviadas: asesores.fold(0, (s, a) => s + a.enviadas),
      totalAprobadas: asesores.fold(0, (s, a) => s + a.aprobadas),
      totalDesembolsadas: asesores.fold(0, (s, a) => s + a.desembolsadas),
      montoTotal: asesores.fold(0.0, (s, a) => s + a.montoTotalAprobado),
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
