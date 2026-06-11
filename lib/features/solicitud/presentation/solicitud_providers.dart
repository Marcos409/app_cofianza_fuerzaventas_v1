import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/solicitud_local_datasource.dart';
import '../data/solicitud_repository.dart';
import '../domain/solicitud_model.dart';
import 'solicitud_viewmodel.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/supabase/supabase_client.dart';

final solicitudLocalDatasourceProvider = Provider<SolicitudLocalDatasource>((ref) {
  return SolicitudLocalDatasource(LocalDb.instance);
});

final solicitudRepositoryProvider = Provider<SolicitudRepository>((ref) {
  return SolicitudRepository(
    ref.watch(solicitudLocalDatasourceProvider),
    SupabaseService.instance,
    NetworkMonitor(),
  );
});

final solicitudProvider =
    StateNotifierProvider.autoDispose<SolicitudNotifier, SolicitudFormState>(
        (ref) {
  return SolicitudNotifier(ref.watch(solicitudRepositoryProvider));
});

final borradoresProvider =
    FutureProvider.autoDispose<List<SolicitudModel>>((ref) {
  return ref.watch(solicitudRepositoryProvider).getBorradores();
});
