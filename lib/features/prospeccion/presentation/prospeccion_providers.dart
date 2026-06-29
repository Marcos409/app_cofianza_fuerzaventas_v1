import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prospeccion_repository.dart';
import '../domain/prospeccion_models.dart';
import 'prospeccion_viewmodel.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/local_cache.dart';

final prospeccionRepositoryProvider = Provider<ProspeccionRepository>((ref) {
  return ProspeccionRepository(
    NetworkMonitor(),
    ApiClient.instance,
    LocalCache.instance,
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
