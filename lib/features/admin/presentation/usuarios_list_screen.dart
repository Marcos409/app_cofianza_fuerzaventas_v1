import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/asesor_model.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_providers.dart';

class UsuariosListScreen extends ConsumerStatefulWidget {
  const UsuariosListScreen({super.key});

  @override
  ConsumerState<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends ConsumerState<UsuariosListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminUsuariosProvider.notifier).loadUsuarios());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsuariosProvider);

    ref.listen<AdminUsuariosState>(adminUsuariosProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(adminUsuariosProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(adminUsuariosProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/usuarios/nuevo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo usuario'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AdminUsuariosState state) {
    switch (state.status) {
      case AdminUsuariosStatus.initial:
      case AdminUsuariosStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case AdminUsuariosStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Error al cargar usuarios',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(adminUsuariosProvider.notifier).loadUsuarios(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case AdminUsuariosStatus.loaded:
        if (state.usuarios.isEmpty) {
          return const Center(
            child: Text(
              'No hay usuarios registrados',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(adminUsuariosProvider.notifier).loadUsuarios(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.usuarios.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final usuario = state.usuarios[index];
              return _UsuarioCard(usuario: usuario);
            },
          ),
        );
    }
  }
}

class _UsuarioCard extends ConsumerWidget {
  final AsesorModel usuario;

  const _UsuarioCard({required this.usuario});

  void _confirmarEliminar(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final esPropio = authState.asesor?.id == usuario.id;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar usuario'),
        content: Text(
          esPropio
              ? 'No puedes eliminarte a ti mismo.'
              : '¿Estás seguro de eliminar a ${usuario.nombreCompleto}?\n\n'
                  'El usuario quedará inactivo y no podrá iniciar sesión.',
        ),
        actions: esPropio
            ? [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    print('[DELETE] Confirmada eliminación — usuario_id=${usuario.id} codigo=${usuario.codigoEmpleado} nombre="${usuario.nombreCompleto}"');
                    ref
                        .read(adminUsuariosProvider.notifier)
                        .eliminarUsuario(usuario.id);
                  },
                  child: const Text('Eliminar'),
                ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColors = _rolColor(usuario.rol);
    final authState = ref.watch(authProvider);
    final esPropio = authState.asesor?.id == usuario.id;

    return Card(
      elevation: 0,
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: usuario.activo ? AppColors.border : AppColors.error.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/usuarios/editar/${usuario.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (usuario.nombres.isNotEmpty ? usuario.nombres[0] : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Código: ${usuario.codigoEmpleado}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: roleColors.$1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      usuario.rol.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: roleColors.$2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: usuario.activo
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      usuario.activo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: usuario.activo
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              if (usuario.activo)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: esPropio ? AppColors.textHint : AppColors.error,
                  tooltip: esPropio ? 'No puedes eliminarte' : 'Eliminar usuario',
                  onPressed: esPropio
                      ? null
                      : () => _confirmarEliminar(context, ref),
                ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _rolColor(Role role) {
    switch (role) {
      case Role.administrador:
        return (AppColors.error.withValues(alpha: 0.1), AppColors.error);
      case Role.supervisor:
        return (AppColors.warning.withValues(alpha: 0.1), AppColors.warning);
      case Role.superOperador:
        return (AppColors.info.withValues(alpha: 0.1), AppColors.info);
      case Role.operador:
        return (AppColors.success.withValues(alpha: 0.1), AppColors.success);
    }
  }
}
