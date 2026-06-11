import '../domain/asesor_model.dart';

final List<AsesorModel> mockAsesores = [
  AsesorModel(
    id: 'mock-001',
    userId: 'user-mock-001',
    codigoEmpleado: '123456',
    nombres: 'Carlos',
    apellidos: 'García López',
    agenciaId: 'agencia-001',
    rol: Role.operador,
    token: 'mock-token-123456',
  ),
  AsesorModel(
    id: 'mock-002',
    userId: 'user-mock-002',
    codigoEmpleado: '654321',
    nombres: 'María',
    apellidos: 'Fernández Rojas',
    agenciaId: 'agencia-001',
    rol: Role.supervisor,
    token: 'mock-token-654321',
  ),
  AsesorModel(
    id: 'mock-003',
    userId: 'user-mock-003',
    codigoEmpleado: '111111',
    nombres: 'Admin',
    apellidos: 'Sistema',
    agenciaId: 'agencia-001',
    rol: Role.administrador,
    token: 'mock-token-111111',
  ),
  AsesorModel(
    id: 'mock-004',
    userId: 'user-mock-004',
    codigoEmpleado: '222222',
    nombres: 'Super',
    apellidos: 'Operador Test',
    agenciaId: 'agencia-001',
    rol: Role.superOperador,
    token: 'mock-token-222222',
  ),
];

final Map<String, String> mockPasswords = {
  '123456': '123456',
  '654321': '654321',
  '111111': '111111',
  '222222': '222222',
};
