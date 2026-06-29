import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ruta_repository.dart';
import '../../data/directions_service.dart';
import '../ruta_viewmodel.dart';
import '../../../cartera/data/cartera_local_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/local_cache.dart';

final directionsServiceProvider = Provider<DirectionsService>((ref) {
  return DirectionsService();
});

final rutaRepositoryProvider = Provider<RutaRepository>((ref) {
  return RutaRepository(
    CarteraLocalDatasource(LocalCache.instance),
    ApiClient.instance,
  );
});

final rutaNotifierProvider =
    StateNotifierProvider<RutaNotifier, RutaState>((ref) {
  return RutaNotifier(
    ref.watch(rutaRepositoryProvider),
    ref.watch(directionsServiceProvider),
  );
});
