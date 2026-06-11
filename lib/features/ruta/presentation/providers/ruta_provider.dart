import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ruta_repository.dart';
import '../../data/directions_service.dart';
import '../ruta_viewmodel.dart';
import '../../../cartera/data/cartera_local_datasource.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/storage/local_db.dart';

final directionsServiceProvider = Provider<DirectionsService>((ref) {
  return DirectionsService();
});

final rutaRepositoryProvider = Provider<RutaRepository>((ref) {
  return RutaRepository(
    CarteraLocalDatasource(LocalDb.instance),
    SupabaseService.instance,
  );
});

final rutaNotifierProvider =
    StateNotifierProvider<RutaNotifier, RutaState>((ref) {
  return RutaNotifier(
    ref.watch(rutaRepositoryProvider),
    ref.watch(directionsServiceProvider),
    SupabaseService.instance,
  );
});
