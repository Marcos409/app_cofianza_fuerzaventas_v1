import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../core/constants/app_colors.dart';

class SignaturePad extends StatefulWidget {
  final ValueChanged<String>? onSignatureChanged;

  const SignaturePad({super.key, this.onSignatureChanged});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final _controller = SignatureController(
    penStrokeWidth: 2.5,
    penColor: AppColors.textPrimary,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    _exportSignature();
  }

  Future<void> _exportSignature() async {
    if (_controller.isEmpty) {
      widget.onSignatureChanged?.call('');
      return;
    }
    final data = await _controller.toPngBytes();
    if (data != null) {
      final base64 = base64Encode(data);
      widget.onSignatureChanged?.call(base64);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Signature(
              controller: _controller,
              height: 180,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                _controller.clear();
                widget.onSignatureChanged?.call('');
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Limpiar firma'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textHint),
            ),
          ],
        ),
      ],
    );
  }
}
