import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_monitor.dart';
import '../../../core/cache/local_cache.dart';
import '../../../features/documentos/domain/documento_model.dart';
import '../../../features/solicitud/domain/solicitud_model.dart';
import '../data/transmision_repository.dart';
import 'transmision_viewmodel.dart';

final transmisionRepositoryProvider = Provider<TransmisionRepository>((ref) {
  return TransmisionRepository(
    NetworkMonitor(),
    LocalCache.instance,
  );
});

final transmisionNotifierProvider =
    StateNotifierProvider.family<TransmisionNotifier,
        TransmisionState, TransmisionParams>((ref, params) {
  final repository = ref.watch(transmisionRepositoryProvider);
  return TransmisionNotifier(
    repository,
    solicitudId: params.solicitudId,
    solicitud: params.solicitud,
    documentos: params.documentos,
    tieneConsultaBuro: params.tieneConsultaBuro,
  );
});

class TransmisionParams {
  final String solicitudId;
  final SolicitudModel solicitud;
  final List<DocumentoModel> documentos;
  final bool tieneConsultaBuro;

  const TransmisionParams({
    required this.solicitudId,
    required this.solicitud,
    required this.documentos,
    required this.tieneConsultaBuro,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransmisionParams && solicitudId == other.solicitudId;

  @override
  int get hashCode => solicitudId.hashCode;
}
