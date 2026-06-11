import 'package:flutter/material.dart';
import 'reportes_viewmodel.dart';
import '../../../core/constants/app_colors.dart';

// TODO: Implementar UI de reportes
class ReportesScreen extends StatelessWidget {
  final ReportesViewModel viewModel;

  const ReportesScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Generación de reportes',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
