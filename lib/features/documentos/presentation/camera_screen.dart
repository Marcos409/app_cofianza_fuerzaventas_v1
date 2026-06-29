import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/image_service.dart';
import '../domain/documento_model.dart';

class CameraScreen extends StatefulWidget {
  final TipoDocumento tipoDocumento;
  final Future<String> Function(String imagePath) onCapture;

  const CameraScreen({
    super.key,
    required this.tipoDocumento,
    required this.onCapture,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  XFile? _capturedImage;
  bool _isReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No se detectó cámara');
        return;
      }
      _controller = CameraController(cameras.first, ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      setState(() => _errorMessage = 'Error al iniciar cámara: $e');
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final image = await _controller!.takePicture();
      await _validateAndProcess(image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _validateAndProcess(image.path);
  }

  Future<void> _validateAndProcess(String path) async {
    setState(() => _capturedImage = XFile(path));

    final bytes = await File(path).readAsBytes();
    final score = ImageService.calcularNitidez(bytes);
    if (!ImageService.esNitida(bytes)) {
      if (!mounted) return;
      _showRetakeDialog(score);
      return;
    }

    if (!mounted) return;
    final msg = await widget.onCapture(path);
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop(true);
    }
  }

  void _showRetakeDialog(double score) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto con poca nitidez'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Puntaje de nitidez: ${score.toStringAsFixed(1)} (mínimo requerido: ${ImageService.nitidezUmbral.toStringAsFixed(0)})'),
            const SizedBox(height: 8),
            const Text(
              'La foto no alcanza el nivel mínimo de nitidez. '
              'Asegúrate de que la imagen esté bien enfocada y con buena iluminación.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _capturedImage = null);
            },
            child: const Text('REINTENTAR'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final msg = await widget.onCapture(_capturedImage!.path);
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$msg (nitidez baja: ${score.toStringAsFixed(1)})'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('CONTINUAR IGUAL'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tipoDocumento.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
            tooltip: 'Seleccionar de galería',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _errorMessage = null);
                _initCamera();
              },
              child: const Text('REINTENTAR'),
            ),
          ],
        ),
      );
    }

    if (!_isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        CameraPreview(_controller!),
        _GuideFrame(tipo: widget.tipoDocumento),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_capturedImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Procesando imagen...',
                    style: TextStyle(
                      color: Colors.white,
                      backgroundColor: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
              FloatingActionButton.large(
                onPressed: _capturedImage == null ? _capture : null,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideFrame extends StatelessWidget {
  final TipoDocumento tipo;
  const _GuideFrame({required this.tipo});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GuideFramePainter(tipo: tipo),
    );
  }
}

class _GuideFramePainter extends CustomPainter {
  final TipoDocumento tipo;
  _GuideFramePainter({required this.tipo});

  @override
  void paint(Canvas canvas, Size size) {
    final rectWidth = size.width * 0.8;
    final rectHeight = size.height * 0.5;
    final left = (size.width - rectWidth) / 2;
    final top = (size.height - rectHeight) / 2 - 40;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, rectWidth, rectHeight),
      const Radius.circular(12),
    );

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rect, paint);

    final cornerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const cornerLen = 30.0;
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), cornerPaint);
    canvas.drawLine(
      Offset(left + rectWidth - cornerLen, top),
      Offset(left + rectWidth, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + rectWidth, top),
      Offset(left + rectWidth, top + cornerLen),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + rectHeight - cornerLen),
      Offset(left, top + rectHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + rectHeight),
      Offset(left + cornerLen, top + rectHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + rectWidth - cornerLen, top + rectHeight),
      Offset(left + rectWidth, top + rectHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + rectWidth, top + rectHeight),
      Offset(left + rectWidth, top + rectHeight - cornerLen),
      cornerPaint,
    );

    final textSpan = TextSpan(
      text: tipo.label,
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(left, top - 28));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
