import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/estado_repository.dart';
import 'estado_viewmodel.dart';

final estadoRepositoryProvider = Provider<EstadoRepository>((ref) {
  return EstadoRepository();
});

final estadoNotifierProvider =
    StateNotifierProvider.autoDispose<EstadoNotifier, EstadoState>((ref) {
  throw UnimplementedError(
    'Override in screen with asesorId param',
  );
});

final estadoNotifierFamilyProvider = StateNotifierProvider.autoDispose
    .family<EstadoNotifier, EstadoState, String>((ref, asesorId) {
  final repository = ref.watch(estadoRepositoryProvider);
  return EstadoNotifier(repository, asesorId);
});
