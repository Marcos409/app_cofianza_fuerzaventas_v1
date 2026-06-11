import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../solicitud/domain/solicitud_model.dart';
import '../domain/nota_interna_model.dart';

class EstadoRepository {
  final SupabaseClient _supabase;

  EstadoRepository(this._supabase);

  Future<List<SolicitudModel>> listarPorAsesor(String asesorId) async {
    try {
      final response = await _supabase
          .from('solicitudes_credito')
          .select()
          .eq('asesor_id', asesorId)
          .neq('estado', 'borrador')
          .order('fecha_envio', ascending: false);

      final list = response as List;
      return list.map((item) {
        final m = Map<String, dynamic>.from(item);
        return SolicitudModel.fromJson(m);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Stream<List<SolicitudModel>> streamPorAsesor(String asesorId) {
    final controller = StreamController<List<SolicitudModel>>();
    _supabase
        .from('solicitudes_credito')
        .stream(primaryKey: ['id'])
        .eq('asesor_id', asesorId)
        .order('fecha_envio', ascending: false)
        .listen((list) {
          final filtered = list
              .where((item) =>
                  item['estado']?.toString() != 'borrador')
              .map((item) =>
                  SolicitudModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          controller.add(filtered);
        }, onError: (e) {
          controller.addError(e);
        });
    return controller.stream;
  }

  Future<List<NotaInterna>> listarNotas(String solicitudId) async {
    try {
      final response = await _supabase
          .from('solicitudes_notas_internas')
          .select()
          .eq('solicitud_id', solicitudId)
          .order('created_at', ascending: false);
      final list = response as List;
      return list
          .map((item) => NotaInterna.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> agregarNota(NotaInterna nota) async {
    try {
      await _supabase.from('solicitudes_notas_internas').insert(nota.toMap());
    } catch (_) {}
  }
}
