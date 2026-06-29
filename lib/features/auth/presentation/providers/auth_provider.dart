import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_remote_datasource.dart';
import '../../domain/asesor_model.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_monitor.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final AsesorModel? asesor;
  final String? errorMessage;
  final bool isLoading;
  final bool isBlocked;
  final int remainingAttempts;
  final DateTime? blockTime;
  final DateTime? lastActivity;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.asesor,
    this.errorMessage,
    this.isLoading = false,
    this.isBlocked = false,
    this.remainingAttempts = 5,
    this.blockTime,
    this.lastActivity,
  });

  AuthState copyWith({
    AuthStatus? status,
    AsesorModel? asesor,
    String? errorMessage,
    bool? isLoading,
    bool? isBlocked,
    int? remainingAttempts,
    DateTime? blockTime,
    DateTime? lastActivity,
  }) {
    return AuthState(
      status: status ?? this.status,
      asesor: asesor ?? this.asesor,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isBlocked: isBlocked ?? this.isBlocked,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      blockTime: blockTime ?? this.blockTime,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  Timer? _refreshTimer;
  Timer? _inactivityTimer;
  static const _inactivityTimeout = Duration(hours: 8);
  static const _refreshInterval = Duration(minutes: 45);

  AuthNotifier(this._authRepository) : super(const AuthState());

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTimers() async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      try {
        await _authRepository.restoreSession();
      } catch (_) {}
    });

    _inactivityTimer?.cancel();
    final lastActivity = await _authRepository.getLastActivity();
    if (lastActivity != null) {
      state = state.copyWith(lastActivity: lastActivity);
      final elapsed = DateTime.now().difference(lastActivity);
      if (elapsed >= _inactivityTimeout) {
        await logout();
        return;
      }
    }
  }

  Future<void> updateActivity() async {
    await _authRepository.markActivity();
    state = state.copyWith(lastActivity: DateTime.now());
  }

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);

    final hasSession = await _authRepository.hasStoredSession();
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      await _authRepository.restoreSession();
      final isValid = await _authRepository.isSessionValid();
      if (!isValid) {
        await _authRepository.logout();
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final asesor = await _authRepository.getCurrentUser();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        asesor: asesor,
      );
      ApiClient.instance.setAsesorId(asesor.id);
      await _startTimers();
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String codigoEmpleado, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final asesor = await _authRepository.login(codigoEmpleado, password);

      ApiClient.instance.setAsesorId(asesor.id);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        asesor: asesor,
        isLoading: false,
        errorMessage: null,
        remainingAttempts: 5,
        isBlocked: false,
        blockTime: null,
      );
      await updateActivity();
      await _startTimers();
    } catch (e) {
      final remaining = await _authRepository.getRemainingAttempts();
      final blockTime = await _authRepository.getBlockTime();

      final isBlocked = blockTime != null &&
          DateTime.now().isBefore(blockTime);

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        remainingAttempts: remaining,
        isBlocked: isBlocked,
        blockTime: blockTime,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    _refreshTimer?.cancel();
    _inactivityTimer?.cancel();
    await _authRepository.logout();
    ApiClient.instance.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ApiClient.instance);
});

final networkMonitorProvider = Provider<NetworkMonitor>((ref) {
  return NetworkMonitor();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authRemoteDatasourceProvider),
    LocalDb.instance,
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
