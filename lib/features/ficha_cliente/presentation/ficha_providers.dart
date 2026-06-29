import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/local_cache.dart';
import '../data/ficha_repository.dart';
import 'ficha_viewmodel.dart';

final fichaRepositoryProvider = Provider<FichaRepository>((ref) {
  return FichaRepository(
    NetworkMonitor(),
    ApiClient.instance,
    LocalCache.instance,
  );
});

final fichaProvider =
    StateNotifierProvider.autoDispose<FichaNotifier, FichaState>((ref) {
  return FichaNotifier(ref.watch(fichaRepositoryProvider));
});
