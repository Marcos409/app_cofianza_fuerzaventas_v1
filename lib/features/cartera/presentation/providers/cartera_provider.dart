import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/cartera_repository.dart';
import '../../data/cartera_remote_datasource.dart';
import '../../data/cartera_local_datasource.dart';
import '../../domain/cartera_model.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/storage/local_db.dart';

enum CarteraStatus { initial, loading, data, error }

class CarteraState {
  final CarteraStatus status;
  final List<CarteraModel> clientes;
  final List<CarteraModel> filteredClientes;
  final String? errorMessage;
  final FiltroCartera filtroActual;
  final String queryBusqueda;
  final bool isOffline;
  final DateTime? ultimaActualizacion;

  const CarteraState({
    this.status = CarteraStatus.initial,
    this.clientes = const [],
    this.filteredClientes = const [],
    this.errorMessage,
    this.filtroActual = FiltroCartera.todos,
    this.queryBusqueda = '',
    this.isOffline = false,
    this.ultimaActualizacion,
  });

  int get totalClientes => filteredClientes.length;
  int get visitados =>
      filteredClientes.where((c) => c.estadoVisita == EstadoVisita.visitado).length;
  int get pendientes => totalClientes - visitados;
  double get progreso => totalClientes > 0 ? visitados / totalClientes : 0.0;

  CarteraState copyWith({
    CarteraStatus? status,
    List<CarteraModel>? clientes,
    List<CarteraModel>? filteredClientes,
    String? errorMessage,
    FiltroCartera? filtroActual,
    String? queryBusqueda,
    bool? isOffline,
    DateTime? ultimaActualizacion,
  }) {
    return CarteraState(
      status: status ?? this.status,
      clientes: clientes ?? this.clientes,
      filteredClientes: filteredClientes ?? this.filteredClientes,
      errorMessage: errorMessage,
      filtroActual: filtroActual ?? this.filtroActual,
      queryBusqueda: queryBusqueda ?? this.queryBusqueda,
      isOffline: isOffline ?? this.isOffline,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }
}

class CarteraNotifier extends StateNotifier<CarteraState> {
  final CarteraRepository _repository;
  Timer? _debounceTimer;

  CarteraNotifier(this._repository) : super(const CarteraState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }

  Future<void> loadClientes() async {
    state = state.copyWith(status: CarteraStatus.loading, errorMessage: null);

    try {
      final clientes = await _repository.getCartera();
      state = state.copyWith(
        status: CarteraStatus.data,
        clientes: clientes,
        filteredClientes: clientes,
        ultimaActualizacion: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: CarteraStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setFilter(FiltroCartera filtro) async {
    state = state.copyWith(filtroActual: filtro, queryBusqueda: '');

    if (filtro == FiltroCartera.todos) {
      state = state.copyWith(filteredClientes: state.clientes);
      return;
    }

    final filtrados = _filtrarLocal(state.clientes, filtro);
    state = state.copyWith(filteredClientes: filtrados);
  }

  void search(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(queryBusqueda: query);

    if (query.trim().isEmpty) {
      _applyCurrentFilter();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final q = query.trim().toLowerCase();
      final filtrados = state.clientes.where((c) {
        return c.nombreCliente.toLowerCase().contains(q) ||
            c.documentoCliente.contains(q);
      }).toList();
      state = state.copyWith(filteredClientes: filtrados);
    });
  }

  Future<void> marcarVisita({
    required String id,
    required EstadoVisita estado,
    String? observacion,
    double? lat,
    double? lng,
  }) async {
    await _repository.marcarVisita(
      id: id,
      estado: estado,
      observacion: observacion,
      lat: lat,
      lng: lng,
    );

    final actualizados = state.clientes.map((c) {
      if (c.id == id) {
        return c.copyWith(
          estadoVisita: estado,
          observacionVisita: observacion,
          timestampVisita: DateTime.now(),
          latVisita: lat,
          lngVisita: lng,
          pendienteSync: true,
        );
      }
      return c;
    }).toList();

    state = state.copyWith(clientes: actualizados);
    _applyCurrentFilter();
  }

  Future<void> reordenar(int oldIndex, int newIndex) async {
    final clientes = List<CarteraModel>.from(state.clientes);
    final item = clientes.removeAt(oldIndex);
    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    clientes.insert(adjustedIndex, item);

    final actualizados = clientes.asMap().entries.map((e) {
      return e.value.copyWith(ordenManual: e.key);
    }).toList();

    state = state.copyWith(clientes: actualizados);
    _applyCurrentFilter();

    for (final c in actualizados) {
      await _repository.actualizarOrdenManual(c.id, c.ordenManual);
    }
  }

  List<CarteraModel> _filtrarLocal(
    List<CarteraModel> clientes,
    FiltroCartera filtro,
  ) {
    List<CarteraModel> result;
    switch (filtro) {
      case FiltroCartera.todos:
        result = List.from(clientes);
      case FiltroCartera.renovaciones:
        result = clientes
            .where((c) => c.tipoGestion == TipoGestion.renovacion)
            .toList();
      case FiltroCartera.nuevas:
        result = clientes
            .where((c) => c.tipoGestion == TipoGestion.nuevaSolicitud)
            .toList();
      case FiltroCartera.mora:
        result = clientes
            .where((c) => c.tipoGestion == TipoGestion.recuperacionMora)
            .toList();
      case FiltroCartera.visitados:
        result = clientes
            .where((c) => c.estadoVisita == EstadoVisita.visitado)
            .toList();
    }
    return _sortVisitadosToBottom(result);
  }

  List<CarteraModel> _sortVisitadosToBottom(List<CarteraModel> list) {
    final visitados = list
        .where((c) => c.estadoVisita == EstadoVisita.visitado)
        .toList();
    final noVisitados = list
        .where((c) => c.estadoVisita != EstadoVisita.visitado)
        .toList();
    return [...noVisitados, ...visitados];
  }

  void _applyCurrentFilter() {
    if (state.filtroActual == FiltroCartera.todos &&
        state.queryBusqueda.isEmpty) {
      state = state.copyWith(filteredClientes: state.clientes);
    } else if (state.queryBusqueda.isNotEmpty) {
      search(state.queryBusqueda);
    } else {
      setFilter(state.filtroActual);
    }
  }
}

final carteraRemoteDatasourceProvider =
    Provider<CarteraRemoteDatasource>((ref) {
  return CarteraRemoteDatasource(SupabaseService.instance);
});

final carteraLocalDatasourceProvider = Provider<CarteraLocalDatasource>((ref) {
  return CarteraLocalDatasource(LocalDb.instance);
});

final carteraRepositoryProvider = Provider<CarteraRepository>((ref) {
  return CarteraRepository(
    ref.watch(carteraRemoteDatasourceProvider),
    ref.watch(carteraLocalDatasourceProvider),
    NetworkMonitor(),
    SupabaseService.instance,
  );
});

final carteraProvider =
    StateNotifierProvider<CarteraNotifier, CarteraState>((ref) {
  return CarteraNotifier(ref.watch(carteraRepositoryProvider));
});
