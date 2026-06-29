import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_monitor.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/local_cache.dart';
import '../data/buro_repository.dart';
import 'buro_viewmodel.dart';

final buroRepositoryProvider = Provider<BuroRepository>((ref) {
  return BuroRepository(
    NetworkMonitor(),
    ApiClient.instance,
    LocalCache.instance,
  );
});

final buroNotifierProvider =
    StateNotifierProvider.autoDispose.family<BuroNotifier, BuroState,
        BuroParams>((ref, params) {
  final repository = ref.watch(buroRepositoryProvider);
  return BuroNotifier(
    repository,
    asesorId: params.asesorId,
    clienteId: params.clienteId,
    dniCliente: params.dniCliente,
    solicitudId: params.solicitudId,
  );
});

class BuroParams {
  final String asesorId;
  final String clienteId;
  final String dniCliente;
  final String? solicitudId;

  const BuroParams({
    required this.asesorId,
    required this.clienteId,
    required this.dniCliente,
    this.solicitudId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuroParams &&
          clienteId == other.clienteId &&
          solicitudId == other.solicitudId;

  @override
  int get hashCode => Object.hash(clienteId, solicitudId);
}
