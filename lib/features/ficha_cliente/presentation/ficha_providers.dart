import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../data/ficha_repository.dart';
import 'ficha_viewmodel.dart';

final fichaRepositoryProvider = Provider<FichaRepository>((ref) {
  return FichaRepository(
    SupabaseService.instance,
    LocalDb.instance,
    NetworkMonitor(),
  );
});

final fichaProvider =
    StateNotifierProvider.autoDispose<FichaNotifier, FichaState>((ref) {
  return FichaNotifier(ref.watch(fichaRepositoryProvider));
});

final alertasCarteraProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, clienteId) async {
  final response = await SupabaseService.instance.client
      .from('alertas_cartera')
      .select()
      .eq('cliente_id', clienteId)
      .eq('leida', false)
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((j) => Map<String, dynamic>.from(j as Map))
      .toList();
});
