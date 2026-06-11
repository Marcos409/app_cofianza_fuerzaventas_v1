import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../solicitud/domain/solicitud_model.dart';
import '../data/estado_repository.dart';
import '../domain/grupo_estado.dart';
import '../domain/nota_interna_model.dart';

class EstadoState {
  final Map<GrupoEstado, List<SolicitudModel>> agrupadas;
  final List<NotaInterna> notas;
  final bool isLoading;
  final String? errorMessage;

  const EstadoState({
    this.agrupadas = const {},
    this.notas = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EstadoState copyWith({
    Map<GrupoEstado, List<SolicitudModel>>? agrupadas,
    List<NotaInterna>? notas,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EstadoState(
      agrupadas: agrupadas ?? this.agrupadas,
      notas: notas ?? this.notas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  int contador(GrupoEstado grupo) => agrupadas[grupo]?.length ?? 0;
}

class EstadoNotifier extends StateNotifier<EstadoState> {
  final EstadoRepository _repository;
  final String _asesorId;
  StreamSubscription<List<SolicitudModel>>? _streamSub;

  EstadoNotifier(this._repository, this._asesorId)
      : super(const EstadoState());

  Future<void> cargarSolicitudes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final lista = await _repository.listarPorAsesor(_asesorId);
      final agrupadas = _agrupar(lista);
      state = state.copyWith(agrupadas: agrupadas, isLoading: false);
      _suscribirStream();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar solicitudes: $e',
      );
    }
  }

  Map<GrupoEstado, List<SolicitudModel>> _agrupar(List<SolicitudModel> lista) {
    final map = <GrupoEstado, List<SolicitudModel>>{};
    for (final grupo in GrupoEstado.values) {
      map[grupo] = [];
    }
    for (final s in lista) {
      final grupo = GrupoEstado.fromEstadoSolicitud(s.estado);
      map[grupo]?.add(s);
    }
    return map;
  }

  void _suscribirStream() {
    _streamSub?.cancel();
    final stream = _repository.streamPorAsesor(_asesorId);
    _streamSub = stream.listen((lista) {
      if (!mounted) return;
      final agrupadas = _agrupar(lista);
      state = state.copyWith(agrupadas: agrupadas);
    });
  }

  Future<void> cargarNotas(String solicitudId) async {
    final notas = await _repository.listarNotas(solicitudId);
    state = state.copyWith(notas: notas);
  }

  Future<void> agregarNota(String solicitudId, String contenido) async {
    final nota = NotaInterna(
      id: const Uuid().v4(),
      solicitudId: solicitudId,
      asesorId: _asesorId,
      contenido: contenido,
      createdAt: DateTime.now(),
    );
    await _repository.agregarNota(nota);
    final notas = [nota, ...state.notas];
    state = state.copyWith(notas: notas);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
