import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/documento_repository.dart';
import '../domain/documento_model.dart';

class DocumentosState {
  final String solicitudId;
  final List<DocumentoModel> documentos;
  final bool isUploading;
  final String? errorMessage;

  const DocumentosState({
    required this.solicitudId,
    this.documentos = const [],
    this.isUploading = false,
    this.errorMessage,
  });

  DocumentosState copyWith({
    String? solicitudId,
    List<DocumentoModel>? documentos,
    bool? isUploading,
    String? errorMessage,
  }) {
    return DocumentosState(
      solicitudId: solicitudId ?? this.solicitudId,
      documentos: documentos ?? this.documentos,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: errorMessage,
    );
  }

  DocumentoModel? getDocumento(TipoDocumento tipo) {
    try {
      return documentos.firstWhere((d) => d.tipo == tipo);
    } catch (_) {
      return null;
    }
  }

  bool get todosObligatoriosListos {
    final obligatorios = TipoDocumento.values.where((t) => t.esObligatorio);
    for (final tipo in obligatorios) {
      final doc = getDocumento(tipo);
      if (doc == null || doc.estado != EstadoDocumento.listo) return false;
    }
    return true;
  }

  int get totalListos => documentos.where((d) => d.estado == EstadoDocumento.listo).length;
  int get totalObligatorios => TipoDocumento.values.where((t) => t.esObligatorio).length;
  int get totalDocs => TipoDocumento.values.length;
}

class DocumentosNotifier extends StateNotifier<DocumentosState> {
  final DocumentoRepository _repository;

  DocumentosNotifier(this._repository, String solicitudId)
      : super(DocumentosState(solicitudId: solicitudId));

  Future<void> loadDocumentos() async {
    final docs = await _repository.listarDocumentos(state.solicitudId);
    state = state.copyWith(documentos: docs);
  }

  Future<void> capturarDocumento({
    required TipoDocumento tipo,
    required String imagePath,
  }) async {
    if (state.getDocumento(tipo) != null) {
      await _repository.eliminar(state.getDocumento(tipo)!);
    }
    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      final doc = await _repository.capturarYSubir(
        solicitudId: state.solicitudId,
        tipo: tipo,
        imagePath: imagePath,
      );
      final docs = List<DocumentoModel>.from(state.documentos);
      docs.removeWhere((d) => d.tipo == tipo);
      docs.add(doc);
      state = state.copyWith(documentos: docs, isUploading: false);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Error al procesar documento: ${e.toString()}',
      );
    }
  }

  Future<void> eliminarDocumento(TipoDocumento tipo) async {
    final doc = state.getDocumento(tipo);
    if (doc == null) return;
    final ok = await _repository.eliminar(doc);
    if (ok) {
      final docs = List<DocumentoModel>.from(state.documentos);
      docs.removeWhere((d) => d.tipo == tipo);
      state = state.copyWith(documentos: docs);
    } else {
      state = state.copyWith(errorMessage: 'Error al eliminar documento');
    }
  }
}
