class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  static String? codigoEmpleado(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código de empleado es requerido';
    }
    final cleaned = value.trim();
    if (cleaned.length < 4 || cleaned.length > 10) {
      return 'El código debe tener entre 4 y 10 dígitos';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'El código debe ser numérico';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'El correo es requerido';
    final regex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  static String? dni(String? value) {
    if (value == null || value.isEmpty) return 'El DNI es requerido';
    if (!RegExp(r'^\d{8}$').hasMatch(value)) return 'El DNI debe tener 8 dígitos';
    return null;
  }

  static String? ruc(String? value) {
    if (value == null || value.isEmpty) return 'El RUC es requerido';
    if (!RegExp(r'^\d{11}$').hasMatch(value)) return 'El RUC debe tener 11 dígitos';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es requerido';
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 9) return 'Deben ser 9 dígitos';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) return 'El monto es requerido';
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return 'Ingresa un monto válido mayor a 0';
    return null;
  }

  static String? positiveInt(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$fieldName es requerido';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'Ingresa un número válido mayor a 0';
    return null;
  }
}
