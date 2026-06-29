import 'api_client.dart';
import '../cache/local_cache.dart';
import 'network_monitor.dart';

class ApiService {
  final ApiClient _client;
  final LocalCache _cache;
  final NetworkMonitor _networkMonitor;

  ApiService(this._client, this._cache, this._networkMonitor);

  Future<bool> get isOnline => _networkMonitor.isConnected;

  String? _asesorId;
  String get asesorId => _asesorId ?? '';
  set asesorId(String id) => _asesorId = id;

  Future<List<dynamic>> getAsignadas() async {
    final data = await _client.get<List>('/solicitudes/asignadas');
    if (_asesorId != null) {
      await _cache.cacheList('solicitudes_cache', _asesorId!, data, 'id');
    }
    return data;
  }

  Future<Map<String, dynamic>> getDetalleSolicitud(String solicitudId) async {
    try {
      return await _client.get<Map<String, dynamic>>('/solicitudes/$solicitudId');
    } catch (_) {
      final cached = await _cache.getCached('solicitudes_cache', solicitudId);
      if (cached != null) return cached as Map<String, dynamic>;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> crearSolicitud(Map<String, dynamic> data) async {
    return await _client.post<Map<String, dynamic>>('/solicitudes', data: data);
  }

  Future<Map<String, dynamic>> enviarComite(String solicitudId) async {
    return await _client.post<Map<String, dynamic>>('/solicitudes/$solicitudId/enviar-comite');
  }

  Future<Map<String, dynamic>> cambiarEstado(String solicitudId, String estado) async {
    return await _client.patch<Map<String, dynamic>>('/solicitudes/$solicitudId/estado', data: {'estado': estado});
  }

  Future<List<dynamic>> getCartera() async {
    final data = await _client.get<List>('/cartera');
    if (_asesorId != null) {
      await _cache.cacheList('cartera_cache', _asesorId!, data, 'id');
    }
    return data;
  }

  Future<void> marcarVisita(String carteraId, Map<String, dynamic> visitaData) async {
    try {
      await _client.post('/cartera/$carteraId/visita', data: visitaData);
    } catch (_) {
      if (_asesorId != null) {
        await _cache.enqueueSync('cartera', carteraId, 'visita', visitaData);
      }
    }
  }

  Future<Map<String, dynamic>> getFichaCliente(String clienteId) async {
    try {
      return await _client.get<Map<String, dynamic>>('/clientes/$clienteId/ficha');
    } catch (_) {
      final cached = await _cache.getCached('ficha_cache', clienteId);
      if (cached != null) return cached as Map<String, dynamic>;
      rethrow;
    }
  }

  Future<void> actualizarUbicacion(String clienteId, double lat, double lng, String direccion) async {
    await _client.post('/clientes/$clienteId/ubicacion', data: {
      'lat': lat, 'lng': lng, 'direccion': direccion,
    });
  }

  Future<List<dynamic>> getDocumentos(String solicitudId) async {
    return await _client.get<List>('/documentos/$solicitudId/documentos');
  }

  Future<void> uploadDocumento(String solicitudId, String filePath) async {
    await _client.uploadFile('/documentos/$solicitudId/upload', filePath, 'file');
  }

  Future<Map<String, dynamic>> consultarBuro(String dni, String clienteId) async {
    return await _client.post<Map<String, dynamic>>('/buro/consulta', data: {
      'dni': dni, 'cliente_id': clienteId,
    });
  }

  Future<List<dynamic>> getCampanas() async {
    return await _client.get<List>('/campanas');
  }

  Future<List<dynamic>> getAlertas() async {
    return await _client.get<List>('/alertas');
  }

  Future<int> getAlertasNoLeidas() async {
    return await _client.get<int>('/alertas/no-leidas');
  }

  Future<void> marcarAlertaLeida(String alertaId) async {
    await _client.post('/alertas/$alertaId/leer');
  }

  Future<List<dynamic>> getMora() async {
    return await _client.get<List>('/cobranza/mora');
  }

  Future<void> registrarAccionCobranza(Map<String, dynamic> data) async {
    try {
      await _client.post('/cobranza/accion', data: data);
    } catch (_) {
      await _cache.enqueueSync('cobranza', data['credito_id']?.toString() ?? '', 'accion', data);
    }
  }

  Future<Map<String, dynamic>> preEvaluar(Map<String, dynamic> data) async {
    return await _client.post<Map<String, dynamic>>('/pre-evaluar', data: data);
  }

  Future<Map<String, dynamic>> getReporteProductividad() async {
    return await _client.get<Map<String, dynamic>>('/reportes/productividad');
  }

  Future<List<dynamic>> getAsesores({String? perfil}) async {
    final params = perfil != null ? {'perfil': perfil} : null;
    return await _client.get<List>('/asesores', params: params);
  }

  Future<List<dynamic>> getUsuarios() async {
    return await _client.get<List>('/api/v1/usuarios');
  }

  Future<void> eliminarUsuario(String usuarioId, String codigoEmpleado) async {
    await _client.delete('/api/v1/usuarios/$usuarioId', data: {'X-Codigo-Empleado': codigoEmpleado});
  }

  Future<Map<String, dynamic>> getOutbox() async {
    return await _client.get<Map<String, dynamic>>('/sync/outbox');
  }

  Future<Map<String, dynamic>> promoverSync() async {
    return await _client.post<Map<String, dynamic>>('/sync/promover');
  }

  Future<List<dynamic>> getNotas(String solicitudId) async {
    return await _client.get<List>('/solicitudes/$solicitudId/notas');
  }

  Future<void> agregarNota(String solicitudId, String contenido) async {
    await _client.post('/solicitudes/$solicitudId/notas', data: {'contenido': contenido});
  }

  Future<void> flushSyncQueue() async {
    final pendientes = await _cache.getPendingSync();
    for (final item in pendientes) {
      try {
        final id = item['id'] as int;
        final payload = item['payload'] != null ? item['payload'] as String : null;
        switch (item['entidad'] as String) {
          case 'cartera':
            final carteraId = item['entidad_id'] as String;
            await _client.post('/cartera/$carteraId/visita', data: payload != null ? Map<String, dynamic>.from(payload as Map) : {});
          case 'cobranza':
            await _client.post('/cobranza/accion', data: payload != null ? Map<String, dynamic>.from(payload as Map) : {});
        }
        await _cache.markSynced(id);
      } catch (_) {
        await _cache.markSyncError(item['id'] as int);
      }
    }
  }
}
