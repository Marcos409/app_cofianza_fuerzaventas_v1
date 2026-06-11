import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reportes_repository.dart';
import '../domain/avance_asesor.dart';
import '../domain/productividad_asesor.dart';

enum ReportesStatus { initial, loading, data, error }

class SupervisionState {
  final ReportesStatus status;
  final List<AvanceAsesor> asesores;
  final String? errorMessage;

  const SupervisionState({
    this.status = ReportesStatus.initial,
    this.asesores = const [],
    this.errorMessage,
  });

  SupervisionState copyWith({
    ReportesStatus? status,
    List<AvanceAsesor>? asesores,
    String? errorMessage,
  }) {
    return SupervisionState(
      status: status ?? this.status,
      asesores: asesores ?? this.asesores,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProductividadState {
  final ReportesStatus status;
  final ReporteMensual? reporte;
  final int mes;
  final int anio;
  final String? errorMessage;

  const ProductividadState({
    this.status = ReportesStatus.initial,
    this.reporte,
    this.mes = 1,
    this.anio = 2026,
    this.errorMessage,
  });

  ProductividadState copyWith({
    ReportesStatus? status,
    ReporteMensual? reporte,
    int? mes,
    int? anio,
    String? errorMessage,
  }) {
    return ProductividadState(
      status: status ?? this.status,
      reporte: reporte ?? this.reporte,
      mes: mes ?? this.mes,
      anio: anio ?? this.anio,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SupervisionNotifier extends StateNotifier<SupervisionState> {
  final ReportesRepository _repository;
  final String _agenciaId;

  SupervisionNotifier(this._repository, this._agenciaId)
      : super(const SupervisionState());

  Future<void> cargarAvance() async {
    state = state.copyWith(status: ReportesStatus.loading);
    try {
      final avance = await _repository.getAvanceDiario(_agenciaId);
      state = SupervisionState(status: ReportesStatus.data, asesores: avance);
    } catch (e) {
      state = state.copyWith(
        status: ReportesStatus.error,
        errorMessage: 'Error al cargar avance: $e',
      );
    }
  }
}

class ProductividadNotifier extends StateNotifier<ProductividadState> {
  final ReportesRepository _repository;
  final String _agenciaId;

  ProductividadNotifier(this._repository, this._agenciaId)
      : super(ProductividadState(
          mes: DateTime.now().month,
          anio: DateTime.now().year,
        ));

  Future<void> cargarReporte() async {
    state = state.copyWith(status: ReportesStatus.loading);
    try {
      final reporte =
          await _repository.getProductividad(_agenciaId, state.mes, state.anio);
      state = state.copyWith(
        status: ReportesStatus.data,
        reporte: reporte,
      );
    } catch (e) {
      state = state.copyWith(
        status: ReportesStatus.error,
        errorMessage: 'Error al cargar reporte: $e',
      );
    }
  }

  void mesAnterior() {
    final m = state.mes - 1;
    state = state.copyWith(
      mes: m > 0 ? m : 12,
      anio: m > 0 ? state.anio : state.anio - 1,
    );
    cargarReporte();
  }

  void mesSiguiente() {
    final m = state.mes + 1;
    state = state.copyWith(
      mes: m <= 12 ? m : 1,
      anio: m <= 12 ? state.anio : state.anio + 1,
    );
    cargarReporte();
  }
}
