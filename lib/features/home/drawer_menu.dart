import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/domain/asesor_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/storage/local_db.dart';

class DrawerMenu extends ConsumerWidget {
  final AsesorModel? asesor;

  const DrawerMenu({super.key, required this.asesor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = asesor?.rol ?? Role.operador;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMenuList(context, ref, role)),
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: AppColors.primary),
      accountName: Text(
        asesor?.nombreCompleto ?? 'Usuario',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      accountEmail: Text(
        'Código: ${asesor?.codigoEmpleado ?? ''}',
        style: const TextStyle(fontSize: 13),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          (asesor?.nombres ?? 'U')[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  bool _isVisibleForRole(Role role, String route) {
    const operadorRoutes = [
      '/cartera',
      '/ruta',
      '/ficha-cliente',
      '/solicitudes',
      '/pre-evaluacion',
      '/borradores',
      '/documentos',
    ];
    if (role == Role.operador) {
      return operadorRoutes.contains(route);
    }
    if (role == Role.supervisor || role == Role.administrador) {
      return true;
    }
    return operadorRoutes.contains(route);
  }

  Widget _buildMenuList(
      BuildContext context, WidgetRef ref, Role role) {
    final items = <_DrawerItem>[
      _DrawerItem('Cartera', Icons.people_outline, '/cartera', true),
      _DrawerItem('Ruta', Icons.route_outlined, '/ruta', true),
      _DrawerItem(
        'Ficha Cliente',
        Icons.person_outline,
        '/cartera',
        true,
      ),
      _DrawerItem(
        'Pre-Evaluación',
        Icons.search_outlined,
        '/pre-evaluacion',
        true,
      ),
      _DrawerItem(
        'Solicitudes',
        Icons.note_add_outlined,
        '/solicitudes',
        true,
      ),
      _DrawerItem(
        'Borradores',
        Icons.drafts_outlined,
        '/borradores',
        true,
      ),
      _DrawerItem(
        'Documentos',
        Icons.description_outlined,
        '/documentos',
        true,
      ),
      _DrawerItem('Buró', Icons.credit_score_outlined, '/buro', true),
      _DrawerItem(
        'Estado Solicitudes',
        Icons.pending_actions_outlined,
        '/estado-solicitudes',
        true,
      ),
      _DrawerItem(
        'Cobranza',
        Icons.payments_outlined,
        '/cobranza',
        role == Role.supervisor || role == Role.administrador,
      ),
      _DrawerItem(
        'Reportes',
        Icons.bar_chart_outlined,
        '/reportes',
        role == Role.supervisor || role == Role.administrador,
      ),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: items
          .where((item) => item.visible && _isVisibleForRole(role, item.route))
          .map((item) => ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(item.route);
                },
              ))
          .toList(),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  asesor?.rol.label ?? '',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              color: AppColors.error,
              tooltip: 'Cerrar sesión',
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final localDb = LocalDb.instance;
    final db = await localDb.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM solicitudes_local WHERE pendiente_sync = 1",
    );
    final pendingCount = (result.first['count'] as int?) ?? 0;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Cerrar sesión'),
        content: pendingCount > 0
            ? Text(AppStrings.pendingSyncWarning.replaceAll('@count', pendingCount.toString()))
            : const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;
  final bool visible;

  const _DrawerItem(this.label, this.icon, this.route, this.visible);
}
