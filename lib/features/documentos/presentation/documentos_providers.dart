import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_monitor.dart';
// ════════════════════════════════════════════════════════════
// 🔧 SUPABASE_COMENTADO: Desarrollando solo con PostgreSQL local - Junio 2026
// ════════════════════════════════════════════════════════════
// import '../../../core/supabase/supabase_client.dart';
// ════════════════════════════════════════════════════════════
import '../data/documento_repository.dart';
import 'documentos_viewmodel.dart';

final documentoRepositoryProvider = Provider<DocumentoRepository>((ref) {
  // ════════════════════════════════════════════════════════════
  // 🔧 SUPABASE_COMENTADO: Constructor sin Supabase
  // ════════════════════════════════════════════════════════════
  // return DocumentoRepository(
  //   SupabaseService.instance.client,
  //   NetworkMonitor(),
  // );
  return DocumentoRepository(NetworkMonitor());
  // ════════════════════════════════════════════════════════════
});

final documentosNotifierProvider =
    StateNotifierProvider.family<DocumentosNotifier, DocumentosState, String>(
  (ref, solicitudId) {
    final repository = ref.watch(documentoRepositoryProvider);
    return DocumentosNotifier(repository, solicitudId);
  },
);
