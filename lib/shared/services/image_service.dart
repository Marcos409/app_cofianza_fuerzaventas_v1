import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageService {
  static const double _nitidezUmbral = 100.0;
  static const int _maxSizeKb = 800;
  static const int _maxWidth = 1920;

  static double calcularNitidez(Uint8List bytes) {
    final original = img.decodeImage(bytes);
    if (original == null) return 0;

    final gray = img.grayscale(original);
    return _laplacianVariance(gray);
  }

  static double _laplacianVariance(img.Image src) {
    final values = <int>[];

    int r(int px, int py) => src.getPixel(px, py).r.toInt();

    for (var y = 1; y < src.height - 1; y++) {
      for (var x = 1; x < src.width - 1; x++) {
        final sum = r(x - 1, y - 1) +
            r(x, y - 1) +
            r(x + 1, y - 1) +
            r(x - 1, y) +
            -8 * r(x, y) +
            r(x + 1, y) +
            r(x - 1, y + 1) +
            r(x, y + 1) +
            r(x + 1, y + 1);
        values.add(sum.abs());
      }
    }

    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) ~/ values.length;
    final variance =
        values.fold<double>(0, (a, b) => a + pow(b - mean, 2)) / values.length;

    return variance;
  }

  static bool esNitida(Uint8List bytes) {
    return calcularNitidez(bytes) >= _nitidezUmbral;
  }

  static Future<Uint8List> comprimir(Uint8List bytes) async {
    var imagen = img.decodeImage(bytes);
    if (imagen == null) return bytes;

    if (imagen.width > _maxWidth) {
      final ratio = _maxWidth / imagen.width;
      imagen = img.copyResize(
        imagen,
        width: _maxWidth,
        height: (imagen.height * ratio).round(),
      );
    }

    var calidad = 90;
    Uint8List comprimida;
    do {
      comprimida = Uint8List.fromList(
        img.encodeJpg(imagen, quality: calidad),
      );
      calidad -= 10;
    } while (comprimida.length > _maxSizeKb * 1024 && calidad >= 10);

    return comprimida;
  }

  static Future<Uint8List> capturarDesdeArchivo(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    return _redimensionar(bytes);
  }

  static Future<Uint8List> _redimensionar(Uint8List bytes) async {
    final imagen = img.decodeImage(bytes);
    if (imagen == null) return bytes;

    if (imagen.width > _maxWidth || imagen.height > _maxWidth) {
      final scale = _maxWidth / max(imagen.width, imagen.height);
      final resized = img.copyResize(
        imagen,
        width: (imagen.width * scale).round(),
        height: (imagen.height * scale).round(),
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    }

    return bytes;
  }
}
