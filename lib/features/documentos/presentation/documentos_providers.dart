import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_monitor.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/documento_repository.dart';
import 'documentos_viewmodel.dart';

final documentoRepositoryProvider = Provider<DocumentoRepository>((ref) {
  return DocumentoRepository(
    SupabaseService.instance.client,
    NetworkMonitor(),
  );
});

final documentosNotifierProvider =
    StateNotifierProvider.family<DocumentosNotifier, DocumentosState, String>(
  (ref, solicitudId) {
    final repository = ref.watch(documentoRepositoryProvider);
    return DocumentosNotifier(repository, solicitudId);
  },
);
