import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/cartera/presentation/cartera_screen.dart';
import '../features/ruta/presentation/ruta_screen.dart';
import '../features/ficha_cliente/presentation/ficha_screen.dart';
import '../features/prospeccion/presentation/prospeccion_screen.dart';
import '../features/prospeccion/presentation/campanas_screen.dart';
import '../features/solicitud/presentation/solicitud_screen.dart';
import '../features/solicitud/presentation/simulador_screen.dart';
import '../features/solicitud/presentation/mis_solicitudes_screen.dart';
import '../features/solicitud/presentation/pre_evaluacion_screen.dart';
import '../features/solicitud/presentation/borradores_screen.dart';
import '../features/documentos/presentation/documentos_screen.dart';
import '../features/buro/presentation/buro_screen.dart';
import '../features/transmision/presentation/transmision_screen.dart';
import '../features/estado_solicitudes/presentation/tablero_solicitudes_screen.dart';
import '../features/cobranza/presentation/cobranza_screen.dart';
import '../features/reportes/presentation/reportes_shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final goRouter = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isUninitialized =
          authState.status == AuthStatus.uninitialized ||
              authState.status == AuthStatus.loading;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplashRoute = state.matchedLocation == '/splash';

      if (isUninitialized) {
        return isSplashRoute ? null : '/splash';
      }

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/cartera',
        name: 'cartera',
        builder: (_, _) => const CarteraScreen(),
      ),
      GoRoute(
        path: '/ruta',
        name: 'ruta',
        builder: (_, _) => const RutaScreen(),
      ),
      GoRoute(
        path: '/ficha-cliente/:clienteId',
        name: 'fichaCliente',
        builder: (_, state) => FichaScreen(
          clienteId: state.pathParameters['clienteId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/ficha/:clienteId',
        name: 'ficha',
        builder: (_, state) => FichaScreen(
          clienteId: state.pathParameters['clienteId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/cliente/:clienteId',
        name: 'clienteDetalle',
        builder: (_, state) => FichaScreen(
          clienteId: state.pathParameters['clienteId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/solicitudes',
        name: 'solicitudes',
        builder: (_, _) => const MisSolicitudesScreen(),
      ),
      GoRoute(
        path: '/documentos',
        name: 'documentos',
        builder: (_, _) => const Scaffold(
          body: Center(
            child: Text(
              'Seleccione una solicitud para ver sus documentos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/buro',
        name: 'buroPlaceholder',
        builder: (_, _) => const Scaffold(
          body: Center(
            child: Text(
              'Seleccione un cliente desde Cartera para consultar Buró',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/estado-solicitudes',
        name: 'estadoSolicitudesPlaceholder',
        builder: (context, _) {
          final asesorId = ref.read(authProvider).asesor?.id ?? '';
          return TableroSolicitudesScreen(asesorId: asesorId);
        },
      ),
      GoRoute(
        path: '/cobranza',
        name: 'cobranza',
        builder: (context, _) {
          final asesorId = ref.read(authProvider).asesor?.id ?? '';
          return CobranzaScreen(asesorId: asesorId);
        },
      ),
      GoRoute(
        path: '/prospeccion',
        name: 'prospeccion',
        builder: (_, _) => const ProspeccionScreen(),
      ),
      GoRoute(
        path: '/campanas',
        name: 'campanas',
        builder: (_, _) => const CampanasScreen(),
      ),
      GoRoute(
        path: '/pre-evaluacion',
        name: 'preEvaluacion',
        builder: (_, _) => const PreEvaluacionScreen(),
      ),
      GoRoute(
        path: '/solicitud',
        name: 'solicitud',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SolicitudScreen(
            clienteId: extra?['clienteId'] as String?,
            nombreCliente: extra?['nombre'] as String?,
            documentoCliente: extra?['documento'] as String?,
            telefonoCliente: extra?['telefono'] as String?,
            montoPrefill: extra?['monto'] as double?,
            plazoPrefill: extra?['plazo'] as int?,
            tasaPrefill: extra?['tasa'] as double?,
          );
        },
      ),
      GoRoute(
        path: '/solicitud/nueva',
        name: 'solicitudNueva',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SolicitudScreen(
            clienteId: extra?['clienteId'] as String?,
            nombreCliente: extra?['nombre'] as String?,
            documentoCliente: extra?['documento'] as String?,
            telefonoCliente: extra?['telefono'] as String?,
            montoPrefill: extra?['monto'] as double?,
            plazoPrefill: extra?['plazo'] as int?,
            tasaPrefill: extra?['tasa'] as double?,
          );
        },
      ),
      GoRoute(
        path: '/simulador',
        name: 'simulador',
        builder: (_, _) => const SimuladorScreen(),
      ),
      GoRoute(
        path: '/mis-solicitudes',
        name: 'misSolicitudes',
        builder: (_, _) => const MisSolicitudesScreen(),
      ),
      GoRoute(
        path: '/borradores',
        name: 'borradores',
        builder: (_, _) => const BorradoresScreen(),
      ),
      GoRoute(
        path: '/documentos/:solicitudId',
        name: 'documentosSolicitud',
        builder: (_, state) {
          final solicitudId = state.pathParameters['solicitudId']!;
          return DocumentosScreen(solicitudId: solicitudId);
        },
      ),
      GoRoute(
        path: '/buro/:clienteId',
        name: 'buro',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BuroScreen(
            asesorId: extra['asesorId'] as String,
            clienteId: state.pathParameters['clienteId']!,
            dniCliente: extra['dniCliente'] as String,
            nombreCliente: extra['nombreCliente'] as String,
            solicitudId: extra['solicitudId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/transmision/:solicitudId',
        name: 'transmision',
        builder: (_, state) {
          final solicitudId = state.pathParameters['solicitudId']!;
          return TransmisionScreen(solicitudId: solicitudId);
        },
      ),
      GoRoute(
        path: '/estado-solicitudes/:asesorId',
        name: 'estadoSolicitudes',
        builder: (_, state) {
          final asesorId = state.pathParameters['asesorId']!;
          return TableroSolicitudesScreen(asesorId: asesorId);
        },
      ),
      GoRoute(
        path: '/reportes',
        name: 'reportes',
        builder: (context, _) {
          final asesorId = ref.read(authProvider).asesor?.id ?? '';
          return ReportesShellScreen(agenciaId: asesorId);
        },
      ),
    ],
    errorBuilder: (_, _) => const Scaffold(
      body: Center(child: Text('Página no encontrada')),
    ),
  );

  ref.listen<AuthState>(authProvider, (_, _) {
    goRouter.refresh();
  });

  return goRouter;
});
