import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/documentos/domain/documento_model.dart';

class DocumentoChecklist extends StatelessWidget {
  final List<DocumentoModel> documentos;
  final void Function(TipoDocumento tipo) onTap;
  final void Function(TipoDocumento tipo) onRetake;

  const DocumentoChecklist({
    super.key,
    required this.documentos,
    required this.onTap,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: TipoDocumento.values.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, i) {
        final tipo = TipoDocumento.values[i];
        final doc = documentos.cast<DocumentoModel?>().firstWhere(
              (d) => d?.tipo == tipo,
              orElse: () => null,
            );
        return _DocumentoItem(
          tipo: tipo,
          doc: doc,
          onTap: () => onTap(tipo),
          onRetake: () => onRetake(tipo),
        );
      },
    );
  }
}

class _DocumentoItem extends StatelessWidget {
  final TipoDocumento tipo;
  final DocumentoModel? doc;
  final VoidCallback onTap;
  final VoidCallback onRetake;

  const _DocumentoItem({
    required this.tipo,
    required this.doc,
    required this.onTap,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final estado = doc?.estado ?? EstadoDocumento.pendiente;
    final isListo = estado == EstadoDocumento.listo;

    Widget stateIcon;
    Color statusColor;
    if (isListo) {
      stateIcon = const Icon(Icons.check_circle, color: Colors.green, size: 28);
      statusColor = Colors.green;
    } else if (estado == EstadoDocumento.error) {
      stateIcon = const Icon(Icons.error, color: Colors.red, size: 28);
      statusColor = Colors.red;
    } else if (estado == EstadoDocumento.capturando || estado == EstadoDocumento.subiendo) {
      stateIcon = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
      );
      statusColor = AppColors.primary;
    } else {
      // Pendiente -> ⚠️
      stateIcon = const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28);
      statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          stateIcon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tipo.esObligatorio ? 'OBLIGATORIO' : 'OPCIONAL',
                  style: TextStyle(
                    color: tipo.esObligatorio ? Colors.red.shade700 : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (doc != null && doc!.tamanioKb != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${doc!.tamanioKb} KB | Nitidez: ${(doc!.nitidezScore ?? 0).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text(
              'CAPTURAR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isListo ? Colors.grey.shade100 : AppColors.primary,
              foregroundColor: isListo ? AppColors.primary : Colors.white,
              elevation: isListo ? 0 : 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isListo ? const BorderSide(color: AppColors.border) : BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
