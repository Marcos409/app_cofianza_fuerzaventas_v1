import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/documento_checklist.dart';
import '../domain/documento_model.dart';
import 'camera_screen.dart';
import 'documentos_providers.dart';
import 'documentos_viewmodel.dart';
import 'visor_imagen_screen.dart';

class DocumentosScreen extends ConsumerStatefulWidget {
  final String solicitudId;

  const DocumentosScreen({super.key, required this.solicitudId});

  @override
  ConsumerState<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends ConsumerState<DocumentosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(documentosNotifierProvider(widget.solicitudId).notifier)
          .loadDocumentos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentosNotifierProvider(widget.solicitudId));
    final notifier =
        ref.read(documentosNotifierProvider(widget.solicitudId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      body: Column(
        children: [
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          _buildHeader(state),
          Expanded(
            child: DocumentoChecklist(
              documentos: state.documentos,
              onTap: (tipo) => _onTapDocumento(state, tipo, notifier),
              onRetake: (tipo) => _onCaptureDocumento(tipo, notifier),
            ),
          ),
          _buildBottomButton(state, notifier),
        ],
      ),
    );
  }

  Widget _buildHeader(DocumentosState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.totalListos} de ${state.totalDocs} documentos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.todosObligatoriosListos
                      ? 'Todos los obligatorios listos'
                      : 'Faltan documentos obligatorios',
                  style: TextStyle(
                    color: state.todosObligatoriosListos
                        ? AppColors.success
                        : AppColors.warning,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (state.isUploading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  void _onTapDocumento(
    DocumentosState state,
    TipoDocumento tipo,
    DocumentosNotifier notifier,
  ) {
    final doc = state.getDocumento(tipo);
    if (doc == null) {
      _onCaptureDocumento(tipo, notifier);
      return;
    }

    if (doc.estado == EstadoDocumento.listo || doc.estado == EstadoDocumento.error) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VisorImagenScreen(
            documento: doc,
            onRetake: () => _onCaptureDocumento(tipo, notifier),
            onDelete: () => notifier.eliminarDocumento(tipo),
          ),
        ),
      );
    } else {
      _onCaptureDocumento(tipo, notifier);
    }
  }

  void _onCaptureDocumento(TipoDocumento tipo, DocumentosNotifier notifier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          tipoDocumento: tipo,
          onCapture: (imagePath) async {
            await notifier.capturarDocumento(
              tipo: tipo,
              imagePath: imagePath,
            );
            return 'Documento ${tipo.label} procesado';
          },
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    DocumentosState state,
    DocumentosNotifier notifier,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: state.todosObligatoriosListos && !state.isUploading
                ? () => context.pushReplacement('/transmision/${widget.solicitudId}')
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            child: const Text(
              'CONTINUAR',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
