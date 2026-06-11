import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../domain/asesor_model.dart';

// TODO: Implementar lógica de la pantalla de login
class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository);

  bool _isLoading = false;
  String? _errorMessage;
  AsesorModel? _asesor;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AsesorModel? get asesor => _asesor;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _asesor = await _authRepository.login(email, password);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _asesor = null;
    notifyListeners();
  }
}
