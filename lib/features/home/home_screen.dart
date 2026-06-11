import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/domain/asesor_model.dart';
import '../../core/constants/app_colors.dart';
import 'drawer_menu.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final asesor = authState.asesor;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Bienvenido, ${asesor?.nombreCompleto ?? 'Usuario'}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notificaciones',
          ),
        ],
      ),
      drawer: DrawerMenu(asesor: asesor),
      body: _buildDashboard(context, asesor),
    );
  }

  Widget _buildDashboard(BuildContext context, AsesorModel? asesor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del día',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: _buildMenuOptions(context, asesor),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuOptions(BuildContext context, AsesorModel? asesor) {
    final role = asesor?.rol ?? Role.operador;

    final options = <_MenuOption>[
      _MenuOption('Cartera', Icons.people_outline, AppColors.primary, () {
        context.push('/cartera');
      }),
      _MenuOption('Ruta', Icons.route_outlined, const Color(0xFF7B1FA2), () {
        context.push('/ruta');
      }),
      _MenuOption('Pre-Evaluación', Icons.search_outlined, const Color(0xFF0288D1), () {
        context.push('/pre-evaluacion');
      }),
      _MenuOption('Solicitudes', Icons.note_add_outlined, const Color(0xFF00897B), () {
        context.push('/solicitudes');
      }),
      _MenuOption('Documentos', Icons.description_outlined, const Color(0xFFE65100), () {
        context.push('/documentos');
      }),
      _MenuOption('Ficha Cliente', Icons.person_outline, const Color(0xFF2E7D32), () {
        context.push('/cartera');
      }),
    ];

    if (role == Role.supervisor || role == Role.administrador) {
      options.addAll([
        _MenuOption('Buró', Icons.credit_score_outlined, const Color(0xFFC62828), () {
          context.push('/buro');
        }),
        _MenuOption('Reportes', Icons.bar_chart_outlined, const Color(0xFF1565C0), () {
          context.push('/reportes');
        }),
        _MenuOption('Cobranza', Icons.payments_outlined, const Color(0xFF6A1B9A), () {
          context.push('/cobranza');
        }),
      ]);
    }

    return options.map((opt) {
      return Card(
        elevation: 0,
        color: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        child: InkWell(
          onTap: opt.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: opt.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(opt.icon, size: 26, color: opt.color),
                ),
                const SizedBox(height: 12),
                Text(
                  opt.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _MenuOption {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuOption(this.label, this.icon, this.color, this.onTap);
}
