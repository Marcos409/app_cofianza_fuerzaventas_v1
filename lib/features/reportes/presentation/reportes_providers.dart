import 'package:flutter_riverpod/flutter_riverpod.dart';
// ════════════════════════════════════════════════════════════
// 🔧 SUPABASE_COMENTADO: Desarrollando solo con PostgreSQL local - Junio 2026
// ════════════════════════════════════════════════════════════
// import '../../../core/supabase/supabase_client.dart';
// ════════════════════════════════════════════════════════════
import '../data/reportes_repository.dart';
import 'reportes_notifier.dart';

final reportesRepositoryProvider = Provider<ReportesRepository>((ref) {
  // ════════════════════════════════════════════════════════════
  // 🔧 SUPABASE_COMENTADO: Constructor sin Supabase
  // ════════════════════════════════════════════════════════════
  // return ReportesRepository(
  //   SupabaseService.instance.client,
  // );
  return ReportesRepository();
  // ════════════════════════════════════════════════════════════
});

final supervisionProvider = StateNotifierProvider.autoDispose
    .family<SupervisionNotifier, SupervisionState, String>((ref, agenciaId) {
  final repository = ref.watch(reportesRepositoryProvider);
  return SupervisionNotifier(repository, agenciaId);
});

final productividadProvider = StateNotifierProvider.autoDispose
    .family<ProductividadNotifier, ProductividadState, String>((ref, agenciaId) {
  final repository = ref.watch(reportesRepositoryProvider);
  return ProductividadNotifier(repository, agenciaId);
});
