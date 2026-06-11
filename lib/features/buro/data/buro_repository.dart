import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/network_monitor.dart';
import '../domain/consulta_buro_model.dart';

class BuroRepository {
  final SupabaseClient _supabase;
  final NetworkMonitor _network;

  BuroRepository(this._supabase, this._network);

  Future<ConsultaBuroModel?> consultarReciente(
    String clienteId,
  ) async {
    final hace30Dias = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    try {
      final response = await _supabase
          .from('consultas_buro')
          .select()
          .eq('cliente_id', clienteId)
          .gte('created_at', hace30Dias)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return ConsultaBuroModel.fromMap(Map<String, dynamic>.from(response));
    } catch (_) {
      return null;
    }
  }

  Future<ConsultaBuroModel> consultar({
    required String asesorId,
    required String clienteId,
    required String dniCliente,
    required String firmaBase64,
    String? solicitudId,
  }) async {
    final connected = await _network.isConnected;

    final id = const Uuid().v4();

    if (!connected) {
      return ConsultaBuroModel(
        id: id,
        asesorId: asesorId,
        clienteId: clienteId,
        dniConsultado: dniCliente,
        resultado: const ResultadoBuro(
          calificacionSbs: CalificacionSbs.normal,
          numEntidadesDeuda: 0,
          deudaTotal: 0,
          mayorDeuda: 0,
          diasMayorMora: 0,
        ),
        firmaConsentimientoBase64: firmaBase64,
        solicitudId: solicitudId,
        createdAt: DateTime.now(),
      );
    }

    try {
      final response = await _supabase.functions.invoke(
        'consulta-buro',
        body: {
          'dni': dniCliente,
          'firma_consentimiento': firmaBase64,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      final enListaNegra = data['en_lista_negra'] as bool? ?? false;
      final resultadoBuro = Map<String, dynamic>.from(
        data['resultado_buro'] as Map? ?? {},
      );

      final resultado = ResultadoBuro.fromJson(resultadoBuro);

      final consulta = ConsultaBuroModel(
        id: id,
        asesorId: asesorId,
        clienteId: clienteId,
        dniConsultado: dniCliente,
        resultado: resultado,
        enListaNegra: enListaNegra,
        motivoBloqueo: data['motivo_bloqueo'] as String?,
        firmaConsentimientoBase64: firmaBase64,
        solicitudId: solicitudId,
        createdAt: DateTime.now(),
      );

      await _guardarConsulta(consulta);
      return consulta;
    } catch (e) {
      return ConsultaBuroModel(
        id: id,
        asesorId: asesorId,
        clienteId: clienteId,
        dniConsultado: dniCliente,
        resultado: const ResultadoBuro(
          calificacionSbs: CalificacionSbs.normal,
          numEntidadesDeuda: 0,
          deudaTotal: 0,
          mayorDeuda: 0,
          diasMayorMora: 0,
        ),
        firmaConsentimientoBase64: firmaBase64,
        solicitudId: solicitudId,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<void> guardarReutilizacion(ConsultaBuroModel consultaOriginal) async {
    final consulta = ConsultaBuroModel(
      id: const Uuid().v4(),
      asesorId: consultaOriginal.asesorId,
      clienteId: consultaOriginal.clienteId,
      dniConsultado: consultaOriginal.dniConsultado,
      resultado: consultaOriginal.resultado,
      enListaNegra: consultaOriginal.enListaNegra,
      motivoBloqueo: consultaOriginal.motivoBloqueo,
      firmaConsentimientoBase64: consultaOriginal.firmaConsentimientoBase64,
      solicitudId: consultaOriginal.solicitudId,
      esReutilizada: true,
      createdAt: DateTime.now(),
    );
    await _guardarConsulta(consulta);
  }

  Future<void> _guardarConsulta(ConsultaBuroModel consulta) async {
    try {
      await _supabase.from('consultas_buro').insert({
        'id': consulta.id,
        'asesor_id': consulta.asesorId,
        'cliente_id': consulta.clienteId,
        'dni_consultado': consulta.dniConsultado,
        'calificacion_sbs': consulta.resultado.calificacionSbs.name,
        'entidades_con_deuda': consulta.resultado.numEntidadesDeuda,
        'deuda_total_pen': consulta.resultado.deudaTotal,
        'mayor_deuda': consulta.resultado.mayorDeuda,
        'dias_mayor_mora': consulta.resultado.diasMayorMora,
        'resultado_json': consulta.resultado.toJson(),
        'en_lista_negra': consulta.enListaNegra,
        'motivo_bloqueo': consulta.motivoBloqueo,
        'firma_consentimiento_base64': consulta.firmaConsentimientoBase64,
        'solicitud_id': consulta.solicitudId,
        'created_at': consulta.createdAt.toIso8601String(),
      });
    } catch (_) {}
  }
}
