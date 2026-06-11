import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class EstadoScreen extends StatelessWidget {
  const EstadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Estado de Solicitudes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Seguimiento de solicitudes',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
