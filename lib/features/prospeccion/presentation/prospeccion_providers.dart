import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prospeccion_repository.dart';
import '../domain/prospeccion_models.dart';
import 'prospeccion_viewmodel.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/supabase/supabase_client.dart';

final prospeccionRepositoryProvider = Provider<ProspeccionRepository>((ref) {
  return ProspeccionRepository(
    SupabaseService.instance,
    LocalDb.instance,
    NetworkMonitor(),
  );
});

final prospeccionProvider =
    StateNotifierProvider.autoDispose<ProspeccionNotifier, ProspeccionState>(
        (ref) {
  return ProspeccionNotifier(ref.watch(prospeccionRepositoryProvider));
});

final campanasProvider =
    FutureProvider.autoDispose<List<CampanaActivaModel>>((ref) {
  return ref.watch(prospeccionRepositoryProvider).getCampanasActivas();
});
