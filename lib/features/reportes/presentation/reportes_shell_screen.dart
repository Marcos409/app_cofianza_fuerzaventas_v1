import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'supervision_screen.dart';
import 'productividad_screen.dart';

class ReportesShellScreen extends ConsumerStatefulWidget {
  final String agenciaId;

  const ReportesShellScreen({super.key, required this.agenciaId});

  @override
  ConsumerState<ReportesShellScreen> createState() =>
      _ReportesShellScreenState();
}

class _ReportesShellScreenState extends ConsumerState<ReportesShellScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reportes y Supervisión'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Supervisión'),
            Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Productividad'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SupervisionScreen(agenciaId: widget.agenciaId),
          ProductividadScreen(agenciaId: widget.agenciaId),
        ],
      ),
    );
  }
}
