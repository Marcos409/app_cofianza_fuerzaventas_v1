import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double wp(double percent) => screenWidth * percent / 100;
  double hp(double percent) => screenHeight * percent / 100;

  double sp(double size) {
    final scale = screenWidth / 375;
    return (size * scale).clamp(size * 0.8, size * 1.4);
  }

  EdgeInsets respPad({double all = 0, double h = 0, double v = 0}) {
    if (all > 0) {
      final s = _scale(all);
      return EdgeInsets.all(s);
    }
    return EdgeInsets.symmetric(
      horizontal: _scale(h > 0 ? h : 0),
      vertical: _scale(v > 0 ? v : 0),
    );
  }

  EdgeInsets respOnly({double l = 0, double t = 0, double r = 0, double b = 0}) {
    return EdgeInsets.only(
      left: _scale(l),
      top: _scale(t),
      right: _scale(r),
      bottom: _scale(b),
    );
  }

  double _scale(double px) {
    return (px * screenWidth / 375).clamp(px * 0.8, px * 1.3);
  }
}
