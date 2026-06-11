import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/documento_model.dart';

class VisorImagenScreen extends StatelessWidget {
  final DocumentoModel documento;
  final VoidCallback onRetake;
  final VoidCallback onDelete;

  const VisorImagenScreen({
    super.key,
    required this.documento,
    required this.onRetake,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = documento.localPath != null
        ? FileImage(File(documento.localPath!)) as ImageProvider
        : (documento.storageUrl != null
            ? NetworkImage(documento.storageUrl!)
            : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(documento.tipo.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Retomar foto',
            onPressed: () {
              Navigator.of(context).pop();
              onRetake();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Eliminar',
            onPressed: () => _confirmarEliminacion(context),
          ),
        ],
      ),
      body: imageProvider != null
          ? PhotoView(
              imageProvider: imageProvider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            )
          : const Center(child: Text('Imagen no disponible')),
    );
  }

  void _confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Eliminar ${documento.tipo.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
