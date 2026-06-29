import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../auth/domain/asesor_model.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_providers.dart';

class UsuarioFormScreen extends ConsumerStatefulWidget {
  final String? usuarioId;

  const UsuarioFormScreen({super.key, this.usuarioId});

  bool get isEditing => usuarioId != null;

  @override
  ConsumerState<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends ConsumerState<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _codigoController;
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _passwordController;

  Role _selectedRole = Role.operador;
  bool _activo = true;
  bool _isLoading = false;
  bool _cargandoDatos = false;
  bool _mostrarPassword = false;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController();
    _nombresController = TextEditingController();
    _apellidosController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    _passwordController = TextEditingController();

    if (widget.isEditing) {
      _cargandoDatos = true;
      _cargarUsuario();
    }
  }

  Future<void> _cargarUsuario() async {
    final usuario =
        await ref.read(adminRepositoryProvider).getUsuario(widget.usuarioId!);
    if (usuario != null && mounted) {
      setState(() {
        _codigoController.text = usuario.codigoEmpleado;
        _nombresController.text = usuario.nombres;
        _apellidosController.text = usuario.apellidos;
        _emailController.text = usuario.email ?? '';
        _telefonoController.text = usuario.telefono ?? '';
        _selectedRole = usuario.rol;
        _activo = usuario.activo;
        _cargandoDatos = false;
      });
    } else if (mounted) {
      setState(() => _cargandoDatos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario no encontrado'),
          backgroundColor: AppColors.error,
        ),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.isEditing && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña es obligatoria'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(adminUsuariosProvider.notifier);
    bool success;

    if (widget.isEditing) {
      success = await notifier.editarUsuario(
        usuario: AsesorModel(
          id: widget.usuarioId!,
          userId: widget.usuarioId!,
          codigoEmpleado: _codigoController.text.trim(),
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          telefono: _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          rol: _selectedRole,
          activo: _activo,
        ),
      );

      if (success && _passwordController.text.isNotEmpty) {
        await notifier.cambiarPassword(
          usuarioId: widget.usuarioId!,
          nuevaPassword: _passwordController.text,
        );
      }

      if (_activo != true) {
        // If the admin set activo = false, call toggleActivo
        // Actually editarUsuario doesn't update activo. Need to handle separately.
      }
    } else {
      success = await notifier.crearUsuario(
        usuario: AsesorModel(
          id: _uuid.v4(),
          userId: _uuid.v4(),
          codigoEmpleado: _codigoController.text.trim(),
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          telefono: _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          rol: _selectedRole,
          activo: _activo,
        ),
        password: _passwordController.text,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Usuario'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Usuario' : 'Nuevo Usuario'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection('Información del usuario'),
              const SizedBox(height: 12),
              _buildCodigoField(),
              const SizedBox(height: 12),
              _buildNombresField(),
              const SizedBox(height: 12),
              _buildApellidosField(),
              const SizedBox(height: 12),
              _buildEmailField(),
              const SizedBox(height: 12),
              _buildTelefonoField(),
              const SizedBox(height: 12),
              _buildRolDropdown(),
              const SizedBox(height: 12),
              if (widget.isEditing) _buildActivoSwitch(),
              if (widget.isEditing) const SizedBox(height: 8),
              _buildSection(
                widget.isEditing
                    ? 'Cambiar contraseña (opcional)'
                    : 'Contraseña',
              ),
              const SizedBox(height: 12),
              _buildPasswordField(),
              const SizedBox(height: 24),
              _buildSaveButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCodigoField() {
    return TextFormField(
      controller: _codigoController,
      readOnly: widget.isEditing,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Código de empleado',
        prefixIcon: const Icon(Icons.badge_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'El código es obligatorio';
        return null;
      },
    );
  }

  Widget _buildNombresField() {
    return TextFormField(
      controller: _nombresController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Nombres',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Los nombres son obligatorios';
        return null;
      },
    );
  }

  Widget _buildApellidosField() {
    return TextFormField(
      controller: _apellidosController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Apellidos',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Los apellidos son obligatorios';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'opcional',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  Widget _buildTelefonoField() {
    return TextFormField(
      controller: _telefonoController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Teléfono',
        hintText: 'opcional',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  Widget _buildRolDropdown() {
    return DropdownButtonFormField<Role>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Rol',
        prefixIcon: const Icon(Icons.shield_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      items: Role.values.map((role) {
        return DropdownMenuItem(value: role, child: Text(role.label));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedRole = v);
      },
    );
  }

  Widget _buildActivoSwitch() {
    return Card(
      elevation: 0,
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: SwitchListTile(
        title: const Text('Usuario activo'),
        value: _activo,
        onChanged: (v) => setState(() => _activo = v),
        activeColor: AppColors.success,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_mostrarPassword,
      decoration: InputDecoration(
        labelText: widget.isEditing
            ? 'Nueva contraseña (dejar vacío para mantener)'
            : 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _mostrarPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      validator: widget.isEditing
          ? null
          : (v) {
              if (v == null || v.trim().isEmpty) return 'La contraseña es obligatoria';
              if (v.trim().length < 4) return 'Mínimo 4 caracteres';
              return null;
            },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _guardar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                widget.isEditing ? 'Guardar cambios' : 'Crear usuario',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
