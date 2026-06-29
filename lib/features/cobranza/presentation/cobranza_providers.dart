import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_monitor.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/local_cache.dart';
import '../data/cobranza_repository.dart';
import 'cobranza_notifier.dart';

final cobranzaRepositoryProvider = Provider<CobranzaRepository>((ref) {
  final repo = CobranzaRepository(
    NetworkMonitor(),
    ApiClient.instance,
    LocalCache.instance,
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

final cobranzaProvider = StateNotifierProvider.autoDispose
    .family<CobranzaNotifier, CobranzaState, String>((ref, asesorId) {
  final repository = ref.watch(cobranzaRepositoryProvider);
  return CobranzaNotifier(repository, asesorId);
});
