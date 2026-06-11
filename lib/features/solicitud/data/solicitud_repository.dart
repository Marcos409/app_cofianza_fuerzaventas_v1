import 'dart:async';
import 'solicitud_local_datasource.dart';
import '../domain/solicitud_model.dart';
import '../../../core/network/network_monitor.dart';
import '../../../core/supabase/supabase_client.dart';

class SolicitudRepository {
  final SolicitudLocalDatasource _localDatasource;
  final SupabaseService _supabase;
  final NetworkMonitor _networkMonitor;

  SolicitudRepository(
    this._localDatasource,
    this._supabase,
    this._networkMonitor,
  );

  Future<void> saveBorrador(SolicitudModel solicitud) {
    return _localDatasource.saveBorrador(solicitud);
  }

  Future<List<SolicitudModel>> getBorradores() {
    return _localDatasource.getBorradores();
  }

  Future<void> deleteBorrador(String id) {
    return _localDatasource.deleteBorrador(id);
  }

  Future<SolicitudModel?> getBorrador(String id) {
    return _localDatasource.getBorrador(id);
  }

  Future<String> enviarSolicitud(SolicitudModel solicitud) async {
    final enviada = solicitud.copyWith(
      estado: EstadoSolicitud.enviado,
      numeroExpediente: _generarExpedienteLocal(),
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );

    await _localDatasource.saveEnviada(enviada);

    final isOnline = await _networkMonitor.isConnected;
    if (isOnline) {
      try {
        await _supabase.client.from('solicitudes_credito').insert(enviada.toJson());
      } catch (_) {
        // queda pendiente de sync
      }
    }

    return enviada.numeroExpediente;
  }

  Future<List<SolicitudModel>> getSolicitudesDelMes(String asesorId) async {
    final isOnline = await _networkMonitor.isConnected;

    if (isOnline) {
      try {
        final inicioMes = DateTime(DateTime.now().year, DateTime.now().month, 1)
            .toIso8601String();
        final response = await _supabase.client
            .from('solicitudes_credito')
            .select()
            .eq('asesor_id', asesorId)
            .gte('created_at', inicioMes)
            .order('created_at', ascending: false);

        final solicitudes = (response as List)
            .map((j) =>
                SolicitudModel.fromJson(Map<String, dynamic>.from(j)))
            .toList();

        for (final s in solicitudes) {
          await _localDatasource.saveEnviada(s);
        }

        return solicitudes;
      } catch (_) {
        return _localDatasource.getSolicitudesDelMes(asesorId);
      }
    }

    return _localDatasource.getSolicitudesDelMes(asesorId);
  }

  String _generarExpedienteLocal() {
    final now = DateTime.now();
    final rand = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'EXP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rand';
  }
}
